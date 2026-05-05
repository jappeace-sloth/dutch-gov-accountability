{ pkgs ? import ./pkgs.nix { }
,
}:
pkgs.haskellPackages.override {
  overrides = hnew: hold: {
    dutch-gov-accountability = hnew.callCabal2nix "dutch-gov-accountability" ../. { };
  };
}
