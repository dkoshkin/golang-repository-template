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
        };

        formatter = alejandra;
      }
    );
}
