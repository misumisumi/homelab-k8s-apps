{
  description = "Kubernetes resource configurations";
  nixConfig = {
    extra-substituters = [
      "https://misumisumi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "misumisumi.cachix.org-1:f+5BKpIhAG+00yTSoyG/ihgCibcPuJrfQL3M9qw1REY="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixidy = {
      url = "github:arnarg/nixidy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixhelm = {
      url = "github:nix-community/nixhelm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixidy,
      nixhelm,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
      ];
      perSystem =
        {
          pkgs,
          lib,
          system,
          config,
          ...
        }:
        let
          nixpkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        in
        rec {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ ];
            config.allowUnfree = true;
          };

          # Make nixidy CLI available
          packages = rec {
            nixidy-cli = nixidy.packages.${system}.default;
          }
          // (pkgs.callPackages ./scripts/default.nix { flake-root = config.flake-root.package; });
          legacyPackages = {
            nixidyEnvs.${system} = nixidy.lib.mkEnvs {
              inherit pkgs;
              libOverlay = self: super: {
                importYAML = path: lib.head (self.kube.fromYAML (builtins.readFile path));
                nixdyGenerators = nixidy.packages.${system}.generators;
                extraPkgs = pkgs.callPackage ./_sources/generated.nix { };
              };
              charts = nixhelm.chartsDerivations.${system} // {
                piraeus-operator.piraeus = pkgs.stdenv.mkDerivation {
                  name = "piraeus-operator-chart";
                  src = (pkgs.callPackage ./_sources/generated.nix { }).piraeus-operator.src;
                  phases = [
                    "unpackPhase"
                    "installPhase"
                  ];
                  installPhase = ''
                    mkdir -p $out
                    cp -r charts/piraeus/* $out/
                  '';
                };
                ceph-csi-operator.ceph-csi-drivers = pkgs.stdenv.mkDerivation {
                  name = "ceph-csi-drivers-chart";
                  src = (pkgs.callPackage ./_sources/generated.nix { }).ceph-csi-operator.src;
                  phases = [
                    "unpackPhase"
                    "installPhase"
                  ];
                  installPhase = ''
                    mkdir -p $out
                    cp -r deploy/charts/ceph-csi-drivers/* $out/
                  '';
                };
                owncloud.ocis = pkgs.stdenv.mkDerivation {
                  name = "ocis-chart";
                  src = (pkgs.callPackage ./_sources/generated.nix { }).ocis.src;
                  phases = [
                    "unpackPhase"
                    "installPhase"
                  ];
                  installPhase = ''
                    mkdir -p $out
                    cp -r charts/ocis/* $out/
                  '';
                };
              };

              modules = [ ./modules ];

              envs = {
                develop.modules = [ ./branch/develop ];
                test.modules = [ ./branch/test ];
                production.modules = [ ./branch/production ];
              };
            };
          };
          devshells.default = {
            devshell.startup = {
              compinit.text = "";
              flakeRoot.text = ''
                FLAKE_ROOT="''$(${lib.getExe config.flake-root.package})"
                export FLAKE_ROOT
              '';
            };
            packages =
              with pkgs;
              with packages;
              [
                bashInteractive
                nixidy-cli

                k-dev
                helm-dev
                cilium-dev
              ];
          };
        };
    };
}
