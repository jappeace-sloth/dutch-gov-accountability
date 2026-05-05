{ sources ? import ./npins
, pkgs ? import sources.nixpkgs {}
}:
let
  hp = pkgs.haskellPackages;
in
pkgs.mkShell {
  buildInputs = [
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
}
