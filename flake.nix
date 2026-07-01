{
  description = "F* (fstar-lang.org) syntax highlighting for Vim / Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned to the exact F* commit the Rectifier project compiles against, so
    # the generated keyword lists track that dialect precisely. To bump: set
    # this to the same commit as rectifier's flake.nix `fstar-src` input, run
    # `nix run .#gen`, and commit the regenerated syntax/fstar_tokens.vim.
    fstar-src = {
      url = "github:FStarLang/FStar/c12e51b16de4a5b499a6dcab33d776f35ed4c5c2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, fstar-src }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAll = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      rev = fstar-src.rev or "unknown";
    in {
      # `nix run .#gen` regenerates syntax/fstar_tokens.vim from the pinned F*
      # lexer sources. Run it from the repo root (uses $PWD, override with
      # $FSTAR_VIM_ROOT).
      apps = forAll (pkgs:
        let
          gen = pkgs.writeShellApplication {
            name = "gen";
            runtimeInputs = [ pkgs.ocaml ];
            text = ''
              root="''${FSTAR_VIM_ROOT:-$PWD}"
              ocaml "$root/gen/generate_tokens.ml" \
                --lexer "${fstar-src}/src/ml/FStarC_Parser_LexFStar.ml" \
                --pulse "${fstar-src}/pulse/src/ml/PulseSyntaxExtension_Parser.ml" \
                --rev "${rev}" \
                --out "$root/syntax/fstar_tokens.vim"
            '';
          };
        in {
          gen = { type = "app"; program = "${gen}/bin/gen"; };
          default = { type = "app"; program = "${gen}/bin/gen"; };
        });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.ocaml ]; };
      });
    };
}
