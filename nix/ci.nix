{ sources ? import ../npins }:
let
  pkgs = import sources.nixpkgs {};
  hp = pkgs.haskellPackages;
in
pkgs.stdenv.mkDerivation {
  name = "dutch-gov-accountability-ci";
  src = ../.;
  nativeBuildInputs = [
    (hp.ghcWithPackages (ps: [
      ps.persistent
      ps.persistent-sqlite
      ps.aeson
      ps.http-client
      ps.http-client-tls
      ps.http-types
      ps.optparse-applicative
      ps.monad-logger
      ps.resourcet
      ps.text
      ps.bytestring
      ps.time
      ps.tasty
      ps.tasty-hunit
      ps.unliftio
      ps.conduit
    ]))
    pkgs.cabal-install
  ];

  buildPhase = ''
    export HOME=$TMPDIR

    # Pre-create cabal config to prevent Hackage index fetch attempt.
    # In the nix sandbox there is no network.
    mkdir -p $HOME/.config/cabal
    cat > $HOME/.config/cabal/config <<'CABALEOF'
    CABALEOF

    cabal build all --enable-tests --offline
    cabal test all --offline
  '';

  installPhase = ''
    mkdir -p $out
    touch $out/ci-passed
  '';
}
