{ pkgs ? import <nixpkgs> {} }:

let
    dependencies = import ./src/dependencies.nix { inherit pkgs; };
    julia_16 = pkgs.callPackage ./src/julia/1.6.nix { inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices ApplicationServices; };
in pkgs.mkShell {
    buildInputs = [
        dependencies.artiq-master
        # julia_16
    ];
}
