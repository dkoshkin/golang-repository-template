#!/usr/bin/env bash

# Copyright 2026 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# gojq filters legitimately contain $variables inside single quotes.
# shellcheck disable=SC2016

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "${0}")"
readonly SCRIPT_NAME

REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly REPO_ROOT

readonly FLAKE_FILE="${REPO_ROOT}/hack/flakes/flake.nix"
readonly DEVBOX_FILE="${REPO_ROOT}/devbox.json"
readonly GO_DL_URL="https://go.dev/dl/?mode=json&include=all"

function print_usage {
  cat >&2 <<EOF
  Usage: ${SCRIPT_NAME} [OPTIONS]
  Updates the pinned Go toolchain to the latest patch release of a minor version.
  Updates hack/flakes/flake.nix (package name, version and all archive hashes),
  devbox.json (flake package reference) and the go/toolchain directives of all go.mod files.
  Run 'devbox install' afterwards (or use 'make go-update-version') to refresh devbox.lock.
  Options:
    --minor     Go minor version to track, e.g. 1.27. Defaults to the currently pinned minor.
    --version   Exact Go version to pin, e.g. 1.27.1. Overrides the latest patch lookup.
    -h, --help  Show this help.
EOF
}

function fail {
  echo "${SCRIPT_NAME}: ${*}" >&2
  exit 1
}

function require_command {
  local -r cmd="${1}"
  command -v "${cmd}" >/dev/null 2>&1 || fail "'${cmd}' is required but was not found. Run this script inside the devbox shell (e.g. via 'make go-update-version')."
}

function check_prerequisites {
  require_command curl
  require_command gojq
  require_command go
  require_command basenc
  require_command base64
  require_command sed
  # GNU sed and coreutils are required for 'sed -i' and 'base64 -w0'.
  sed --version 2>/dev/null | grep -q "GNU sed" || fail "GNU sed is required. Run this script inside the devbox shell."
  base64 --version 2>/dev/null | grep -q "coreutils" || fail "GNU coreutils base64 is required. Run this script inside the devbox shell."
}

# Converts a hex encoded sha256 digest into the SRI format used by Nix (sha256-<base64>).
function hex_to_sri {
  local -r hex="${1}"
  echo "sha256-$(printf '%s' "${hex}" | tr 'a-f' 'A-F' | basenc --base16 -d | base64 -w0)"
}

# Prints the version currently pinned in flake.nix, e.g. 1.26.7.
function current_version {
  local attrs
  attrs="$(grep -oE '^\s*go_[0-9]+_[0-9]+_[0-9]+\s*=' "${FLAKE_FILE}" | grep -oE 'go_[0-9]+_[0-9]+_[0-9]+' | sort -u)"
  [[ $(echo "${attrs}" | wc -l) -eq 1 ]] || fail "expected exactly one go_X_Y_Z package in ${FLAKE_FILE}, found: ${attrs//$'\n'/ }"
  echo "${attrs#go_}" | tr '_' '.'
}

# Prints the sha256 (hex) of a file from the go.dev release listing.
# Args: <releases json file> <go version> <filename>
function file_sha256 {
  local -r releases="${1}" version="${2}" filename="${3}"
  local sha
  sha="$(gojq -r --arg v "go${version}" --arg f "${filename}" \
    '.[] | select(.version == $v) | .files[] | select(.filename == $f) | .sha256' "${releases}")"
  [[ -n ${sha} ]] || fail "could not find sha256 for ${filename} in the go.dev release listing"
  echo "${sha}"
}

function run_cmd() {
  local minor=""
  local version=""

  while [[ $# -gt 0 ]]; do
    case "${1}" in
    --minor)
      minor="${2:-}"
      shift 2
      ;;
    --version)
      version="${2:-}"
      shift 2
      ;;
    -h | --help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: ${1}" >&2
      print_usage
      exit 1
      ;;
    esac
  done

  check_prerequisites

  local current
  current="$(current_version)"
  readonly current

  if [[ -n ${version} ]]; then
    [[ ${version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "--version must be of the form X.Y.Z, got '${version}'"
    local version_minor="${version%.*}"
    if [[ -n ${minor} && ${minor} != "${version_minor}" ]]; then
      fail "--minor ${minor} conflicts with --version ${version}"
    fi
    minor="${version_minor}"
  elif [[ -z ${minor} ]]; then
    minor="${current%.*}"
  fi
  [[ ${minor} =~ ^[0-9]+\.[0-9]+$ ]] || fail "--minor must be of the form X.Y, got '${minor}'"

  # Global (not local) so that the EXIT trap can still see it.
  releases="$(mktemp)"
  trap 'rm -f "${releases}"' EXIT
  echo "Fetching Go release listing from ${GO_DL_URL}"
  curl -sSfL "${GO_DL_URL}" -o "${releases}" || fail "failed to fetch ${GO_DL_URL}"

  if [[ -z ${version} ]]; then
    # The listing is ordered newest first.
    version="$(gojq -r --arg prefix "go${minor}." \
      '[.[] | select(.stable and (.version | startswith($prefix)))] | first | .version // empty' "${releases}")"
    [[ -n ${version} ]] || fail "no stable Go release found for minor version ${minor}"
    version="${version#go}"
  else
    gojq -e --arg v "go${version}" 'any(.[]; .version == $v)' "${releases}" >/dev/null ||
      fail "Go version ${version} was not found in the go.dev release listing"
  fi

  if [[ ${version} == "${current}" ]]; then
    echo "Go ${current} is already the latest ${minor} release, nothing to do"
    exit 0
  fi

  echo "Updating Go ${current} -> ${version}"

  local src_hash linux_amd64_hash linux_arm64_hash darwin_amd64_hash darwin_arm64_hash
  src_hash="$(hex_to_sri "$(file_sha256 "${releases}" "${version}" "go${version}.src.tar.gz")")"
  linux_amd64_hash="$(hex_to_sri "$(file_sha256 "${releases}" "${version}" "go${version}.linux-amd64.tar.gz")")"
  linux_arm64_hash="$(hex_to_sri "$(file_sha256 "${releases}" "${version}" "go${version}.linux-arm64.tar.gz")")"
  darwin_amd64_hash="$(hex_to_sri "$(file_sha256 "${releases}" "${version}" "go${version}.darwin-amd64.tar.gz")")"
  darwin_arm64_hash="$(hex_to_sri "$(file_sha256 "${releases}" "${version}" "go${version}.darwin-arm64.tar.gz")")"

  local -r current_attr="go_${current//./_}"
  local -r new_attr="go_${version//./_}"

  echo "Updating ${FLAKE_FILE#"${REPO_ROOT}"/}"
  # The hash of each archive is expected on the line directly after the line naming the archive.
  sed -i \
    -e "s/\b${current_attr}\b/${new_attr}/g" \
    -e "s/version = \"${current}\";/version = \"${version}\";/" \
    -e "/\.linux-amd64\.tar\.gz\"/{n;s|sha256 = \"[^\"]*\"|sha256 = \"${linux_amd64_hash}\"|}" \
    -e "/\.linux-arm64\.tar\.gz\"/{n;s|sha256 = \"[^\"]*\"|sha256 = \"${linux_arm64_hash}\"|}" \
    -e "/\.darwin-amd64\.tar\.gz\"/{n;s|sha256 = \"[^\"]*\"|sha256 = \"${darwin_amd64_hash}\"|}" \
    -e "/\.darwin-arm64\.tar\.gz\"/{n;s|sha256 = \"[^\"]*\"|sha256 = \"${darwin_arm64_hash}\"|}" \
    -e "/\.src\.tar\.gz\"/{n;s|hash = \"[^\"]*\"|hash = \"${src_hash}\"|}" \
    "${FLAKE_FILE}"

  local expected
  for expected in "${new_attr}" "version = \"${version}\";" "${src_hash}" "${linux_amd64_hash}" "${linux_arm64_hash}" "${darwin_amd64_hash}" "${darwin_arm64_hash}"; do
    grep -qF "${expected}" "${FLAKE_FILE}" || fail "failed to update ${FLAKE_FILE}: '${expected}' not found after edit"
  done
  if grep -qE "\b${current_attr}\b" "${FLAKE_FILE}"; then
    fail "failed to update ${FLAKE_FILE}: '${current_attr}' is still referenced"
  fi

  echo "Updating ${DEVBOX_FILE#"${REPO_ROOT}"/}"
  sed -i "s|path:./hack/flakes#${current_attr}\"|path:./hack/flakes#${new_attr}\"|" "${DEVBOX_FILE}"
  grep -qF "path:./hack/flakes#${new_attr}\"" "${DEVBOX_FILE}" || fail "failed to update ${DEVBOX_FILE}"

  echo "Updating go.mod files"
  make -C "${REPO_ROOT}" go-mod-edit-version GO_TOOLCHAIN_VERSION="go${version}" GO_LANGUAGE_VERSION="${minor}.0"

  echo "Updated Go ${current} -> ${version}. Run 'devbox install' to refresh devbox.lock."
}

run_cmd "$@"
