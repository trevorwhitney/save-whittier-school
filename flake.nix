{
  description = "Grafana Loki";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Nixpkgs / NixOS version to use.

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
          config = { allowUnfree = true; };
        };
      in
      {
        # The default package for 'nix build'. This makes sense if the
        # flake provides only one package or there is a clear "main"
        # package.

        apps = {
          serve = {
            type = "app";
            program = with pkgs; "${
                (writeShellScriptBin "serve.sh" ''
                  cd ${self}/docs
                  pwd
                  ls
                  ${pkgs.bundler}/bin/bundle install
                  ${pkgs.bundler}/bin/bundle exec jekyll serve --host 0.0.0.0
                '')
              }/bin/serve.sh";
          };
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            ruby
            bundler
          ];
        };
      });
}
