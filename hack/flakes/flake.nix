{
  description = "Useful flakes for golang and Kubernetes projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.legacyPackages.${system}; rec {
        packages = rec {
          goprintconst = buildGo124Module rec {
            name = "goprintconst";
            version = "0.0.1-dev";
            src = fetchFromGitHub {
              owner = "jimmidyson";
              repo = "goprintconst";
              rev = "088aabfbe96447a809a6a742b6ea0a68f601aa43";
              hash = "sha256-s5CM7BRA231Nzjv3F7qJA6ZM1JC6FnGeFiDiiJTPr3E=";
            };
            doCheck = false;
            subPackages = [ "." ];
            vendorHash = null;
            ldflags = [ "-s" "-w" ];
          };

          release-please = buildNpmPackage rec {
            pname = "release-please";
            version = "17.1.2";
            src = fetchFromGitHub {
              owner = "googleapis";
              repo = "release-please";
              rev = "v${version}";
              hash = "sha256-tyxyyiPE9BkZKLDQATZwySM5qFobBPSGsvYs8gZ2K2k=";
            };
            npmDepsHash = "sha256-NULg1LXGML0J6fEI74hyhT53eFBxpjmyjNn0pIcRApw=";
            dontNpmBuild = true;
          };

          helm-schema = buildGo124Module rec {
            pname = "helm-schema";
            version = "2.3.0";

            src = fetchFromGitHub {
              owner = "losisin";
              repo = "helm-values-schema-json";
              rev = "v${version}";
              hash = "sha256-q5A+tCnuHTtUyejP4flID7XhsoBfWGge2jCgsL0uEOc=";
            };
            doCheck = false;
            vendorHash = "sha256-xmj2i1WNI/9ItbxRk8mPIygjq83xuvNu6THyPqZsysY=";
            ldflags = let t = "main"; in [
              "-s"
              "-w"
              "-X ${t}.BuildDate=19700101-00:00:00"
              "-X ${t}.GitCommit=v${version}"
              "-X ${t}.Version=v${version}"
            ];

            postPatch = ''
              sed -i '/^hooks:/,+2 d' plugin.yaml
              sed -i 's#command: $HELM_PLUGIN_DIR/schema#command: $HELM_PLUGIN_DIR/helm-values-schema-json#' plugin.yaml
            '';

            postInstall = ''
              install -dm755 $out/${pname}
              mv $out/bin/* $out/${pname}/
              install -m644 -Dt $out/${pname} plugin.yaml
            '';
          };

          helm-with-plugins = wrapHelm kubernetes-helm {
            plugins = [
              helm-schema
            ];
          };

          go_1_26_7 =
            let
              version = "1.26.7";
              # Go 1.26 requires Go 1.24.6 or later to bootstrap from source (https://go.dev/doc/go1.26),
              # but the nixpkgs revision pinned in flake.lock only ships a Go 1.22 bootstrap toolchain.
              # Self-bootstrap using the official prebuilt binary of the exact version we're building,
              # by setting GOROOT_BOOTSTRAP.
              # To refresh archive hashes, run:
              # nix-prefetch-url --type sha256 "https://go.dev/dl/<archive>.tar.gz" | xargs nix hash to-sri --type sha256
              # or intentionally build once and copy the 'got: sha256-...' value from the Nix mismatch error.
              bootstrapArchive = {
                x86_64-linux = {
                  file = "go${version}.linux-amd64.tar.gz";
                  sha256 = "sha256-/7X43hDGJVDf3atms2tXAwch4KRKMhjp4Rgde1nxIco=";
                };
                aarch64-linux = {
                  file = "go${version}.linux-arm64.tar.gz";
                  sha256 = "sha256-Wk7IgzedUe6c4QQNXof4014gOHV03YyUf+sB6rw8Gzc=";
                };
                x86_64-darwin = {
                  file = "go${version}.darwin-amd64.tar.gz";
                  sha256 = "sha256-kuizS/88iasWQExZVmmsjLAEzC9nbcvR9bh6a43vO0c=";
                };
                aarch64-darwin = {
                  file = "go${version}.darwin-arm64.tar.gz";
                  sha256 = "sha256-AgoegiSBG+dRY+kgvHfgkmoTkKau6hm9zyP3S510n20=";
                };
              }.${system};
              goBootstrap = stdenv.mkDerivation {
                pname = "go-bootstrap";
                inherit version;
                src = fetchurl {
                  url = "https://go.dev/dl/${bootstrapArchive.file}";
                  sha256 = bootstrapArchive.sha256;
                };
                dontConfigure = true;
                dontBuild = true;
                installPhase = ''
                  mkdir -p $out
                  cp -a . $out
                '';
              };
            in
            go.overrideAttrs (oldAttrs: {
              inherit version;
              src = fetchurl {
                url = "https://go.dev/dl/go${version}.src.tar.gz";
                hash = "sha256-DtJOrHVRBQhbif6cq8J0K5GgrXuUtZ0602SRjryJVq0=";
              };
              # Skip patches that don't apply to this version
              patches = [ ];
              GOROOT_BOOTSTRAP = "${goBootstrap}";
            });
        };

        formatter = alejandra;
      }
    );
}
