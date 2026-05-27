{
  description = "utensil SSG build toolchains — pinned, cache-reusable (local nix develop + tangled Spindle custom registry)";

  inputs = {
    # Single pinned 2024-era nixpkgs (full commit hash, NOT a branch ref — so
    # input resolution needs no GitHub API, avoiding 403 rate-limits, and fetches
    # the tarball directly). This rev ships hugo 0.125.6 (extended) + julia 1.10.x
    # + quarto + d2 + python — the era the blog was built/tested with. Hugo stays
    # <0.15x so the pinned PaperMod + hugo-cite themes work (utensil/blog#2).
    nixpkgs.url = "github:NixOS/nixpkgs/cc6431d5598071f0021efc6c009c79e5b5fe1617";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAll = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAll (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          # Blog (Hugo + Quarto + Julia) toolchain. TODO: typst-ts-cli + pikchr
          # need their own derivations (not in nixpkgs); precompiled Julia depot
          # for a freeze-free build comes next.
          blog = pkgs.mkShell {
            packages = [
              pkgs.hugo
              pkgs.julia_110
              pkgs.quarto
              pkgs.d2
              pkgs.python311
            ];
            shellHook = ''
              echo "blog toolchain ready:"
              hugo version
              julia --version
              quarto --version
            '';
          };
        });
    };
}
