
let
  opts = {
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskellPackages.override {
        overrides = haskellPackagesNew: haskellPackagesOld: rec {
          insert-ordered-containers = pkgs.haskell.lib.doJailbreak haskellPackagesOld.insert-ordered-containers;
          these = pkgs.haskell.lib.doJailbreak haskellPackagesOld.these;
          HaTeX = pkgs.haskell.lib.doJailbreak haskellPackagesOld.HaTeX;
          wl-pprint-extras = pkgs.haskell.lib.doJailbreak haskellPackagesOld.wl-pprint-extras;
        };
      };
    };
  };

  pkgs = import (builtins.fetchTarball {
    url = https://github.com/nixos/nixpkgs/archive/6b80db3f5fae2e72f7a06943abe3cfae2791e8e8.tar.gz;
    sha256 = "1909m8p20spf8779ilkwvszndcysf866bkhzzrxrhvxkmy08k3mf";
  }) { config = opts; };
in

pkgs.stdenv.mkDerivation {
  name = "askvader";
  src = ./.;
  phases = ["installPhase"];
  installPhase =
    ''
    echo Please use nix-shell for now!
    touch $out
    '';
  buildInputs = [
    pkgs.nixops
    pkgs.terraform
    pkgs.packer
    pkgs.kubernetes
    pkgs.nix
    pkgs.fswatch
    pkgs.gmp
    pkgs.zlib
    pkgs.dnsutils
    pkgs.less
    (
    pkgs.haskellPackages.ghcWithPackages (hsPkgs: with hsPkgs;
        [ aeson
          base-prelude
          parsec
          parsers
          boxes
          dlist
          mtl
          pandoc
          trifecta
          parsers
          data-fix
          vinyl
          extensible-effects
          async
          lens
          text
          neat-interpolation
	  HaTeX
          streams
          aeson
          warp-tls
          wai-websockets
          dhall-json
          dhall-text
        ])
    )
   ];
  shellHook = ''
    alias askvader=bin/askvader
  '';
}
