{
  description = "Grafana Loki";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Nixpkgs / NixOS version to use.

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ ];
            config = { allowUnfree = true; };
          };
          jekyll = pkgs.bundlerApp {
            pname = "jekyll";
            exes = [ "jekyll" ];
            gemdir = ./docs;
          };
        in
        {
          # The default package for 'nix build'. This makes sense if the
          # flake provides only one package or there is a clear "main"
          # package.
          defaultPackage = jekyll;

          apps = {
            build = {
              type = "app";
              program = with pkgs; "${
                (writeShellScriptBin "build.sh" ''
                  pushd docs > /dev/null || exit 1
                  ${pkgs.bundler}/bin/bundler config set --local force_ruby_platform true
                  ${pkgs.bundix}/bin/bundix -l
                  popd > /dev/null || exit 1
                '')
              }/bin/build.sh";
            };
            serve = {
              type = "app";
              program = with pkgs; "${
                (writeShellScriptBin "serve.sh" ''
                  ${jekyll}/bin/jekyll serve --source docs --host 0.0.0.0 --livereload
                '')
              }/bin/serve.sh";
            };
          };

          devShell = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              ruby
              bundler
              bundix
              jekyll
            ];
          };
        });
}
