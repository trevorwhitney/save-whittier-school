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
          whittier = pkgs.stdenv.mkDerivation {
            name = "save-whittier-school";
            src = ./docs;
            buildInputs = with pkgs; [ ruby bundler ];
            installPhase = ''
              mkdir -p $out/{bin,share/jekyll}
              cp -r * $out/share/jekyll
              bin=$out/bin/jekyll
              # we are using bundle exec to start in the bundled environment
              cat > $bin <<EOF
                #!/bin/sh -e
                pushd $out/share/jekyll
                ${pkgs.bundler}/bin/bundle package --no-install --path vendor
                ${pkgs.bundler}/bin/bundle exec jekyll "\$@"
              EOF
              chmod +x $bin
            '';
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
                  ${whittier}/bin/jekyll serve -host 0.0.0.0
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
