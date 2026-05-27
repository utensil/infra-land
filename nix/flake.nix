{
  description = "utensil SSG build toolchains — pinned, cache-reusable (local nix develop + tangled Spindle custom registry)";

  inputs = {
    # Single pinned 2024-era nixpkgs (full commit hash, NOT a branch ref — so input
    # resolution needs no GitHub API, avoiding 403 rate-limits, and fetches the
    # tarball directly). Ships hugo 0.125.6 (extended) + julia 1.10.x + quarto + d2
    # + python — the era the blog was built/tested with. Hugo stays <0.15x so the
    # pinned PaperMod + hugo-cite themes work (utensil/blog#2).
    nixpkgs.url = "github:NixOS/nixpkgs/cc6431d5598071f0021efc6c009c79e5b5fe1617";
  };

  outputs = { self, nixpkgs }:
    let
      # Linux only — we build/run in the nixos/nix container (local arm64), GH
      # Actions (x86_64), and tangled Spindle (x86_64). No host-darwin nix.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      # pikchr: zenomt/pikchr-cmd (the `-b` bare-SVG fork the blog uses), `make all`.
      pikchrFor = pkgs: pkgs.stdenv.mkDerivation {
        pname = "pikchr-cmd";
        version = "316bdf9";
        src = pkgs.fetchFromGitHub {
          owner = "zenomt";
          repo = "pikchr-cmd";
          rev = "316bdf9894dc2506fa8e48443b6e0d095575e407";
          hash = "sha256-+1aK9Tdw/ddHgCCI0J2nNSzZuE0qKNNocsFWLMKjpxs=";
        };
        dontConfigure = true;
        buildPhase = "runHook preBuild; make all; runHook postBuild";
        installPhase = "runHook preInstall; install -Dm755 pikchr $out/bin/pikchr; runHook postInstall";
      };

      # typst-ts-cli: prebuilt v0.4.1 release binary (the blog fetches it, doesn't
      # build from source) → fetchurl + autoPatchelf for nix.
      typstTsFor = pkgs: system:
        let
          sel = {
            "x86_64-linux"  = { arch = "x86_64";  hash = "sha256-MOCUL9xltLt+SPM6QVoKax8BHt3DMEtycFhoWo9c70Q="; };
            "aarch64-linux" = { arch = "aarch64"; hash = "sha256-KiqOKwp3C6Zh1NMRgXpIVeXqlLmBtpQny/j3P3qMSPU="; };
          }.${system};
        in pkgs.stdenv.mkDerivation {
          pname = "typst-ts-cli";
          version = "0.4.1";
          src = pkgs.fetchurl {
            url = "https://github.com/Myriad-Dreamin/typst.ts/releases/download/v0.4.1/typst-ts-${sel.arch}-unknown-linux-gnu.tar.gz";
            inherit (sel) hash;
          };
          sourceRoot = ".";
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
          installPhase = ''
            runHook preInstall
            install -Dm755 "$(find . -type f -name typst-ts-cli | head -1)" $out/bin/typst-ts-cli
            runHook postInstall
          '';
        };
    in {
      packages = forAll (system:
        let pkgs = pkgsFor system; in {
          pikchr = pikchrFor pkgs;
          typst-ts-cli = typstTsFor pkgs system;
        });

      devShells = forAll (system:
        let pkgs = pkgsFor system; in {
          # Blog (Hugo + Quarto + Julia + diagrams) toolchain. Precompiled Julia
          # depot for a freeze-free build comes next.
          blog = pkgs.mkShell {
            packages = [
              pkgs.hugo
              pkgs.julia_110
              pkgs.quarto
              pkgs.d2
              pkgs.python311
              (pikchrFor pkgs)
              (typstTsFor pkgs system)
            ];
            shellHook = ''
              echo "blog toolchain:"
              hugo version
              julia --version
              quarto --version
              typst-ts-cli --version 2>/dev/null || echo "typst-ts-cli present"
            '';
          };
        });
    };
}
