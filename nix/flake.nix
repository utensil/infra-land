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

      # Official julia 1.10.3 binary (the generic upstream tarball, same one juliaup
      # installs) — NOT nixpkgs' julia_110. Why: nixpkgs julia can't get GL FBConfigs
      # headless (GLMakie precompile/render dies "No GLXFBConfigs returned"), but the
      # official binary's GLFW_jll dlopens the *system* Mesa libGL → renders under xvfb.
      # Proven: precompiles the full ca-in-julia depot incl. GLMakie headless in ~6min
      # (infra-land julia-depot-spike). autoPatchelf only rewrites julia's own bundled
      # ELFs (interpreter + glibc/gcc rpath); GL libs live in the depot + system Mesa,
      # so the headless-GL behavior the freeze relied on is preserved.
      juliaOfficialFor = pkgs: system:
        let
          sel = {
            "x86_64-linux"  = { arch = "x86_64";  hash = "sha256-gbkQySL/8OJ64fJW8syAPbgfOWAhUoHt3S1IRyGSjHA="; };
            "aarch64-linux" = { arch = "aarch64"; hash = "sha256-LVKmGCaHKzFwxl+ZqVS9nSGjEhHLUJSAVtkk+BGgAk8="; };
          }.${system};
          shortArch = if system == "x86_64-linux" then "x64" else "aarch64";
        in pkgs.stdenv.mkDerivation {
          pname = "julia-official";
          version = "1.10.3";
          src = pkgs.fetchurl {
            url = "https://julialang-s3.julialang.org/bin/linux/${shortArch}/1.10/julia-1.10.3-linux-${sel.arch}.tar.gz";
            inherit (sel) hash;
          };
          # tarball unpacks to julia-1.10.3/ (default sourceRoot).
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.glibc ];
          # Don't strip — julia ships its own bundled libs already laid out.
          dontStrip = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -a . $out/
            runHook postInstall
          '';
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
      # ── Freeze-free Julia depot for the ca-in-julia post ──────────────────
      # Two stages so the precompile cache is relocatable-by-construction:
      #   Stage 1 (FOD): Pkg.instantiate downloads the Manifest-pinned packages +
      #     artifacts (needs network → fixed-output derivation). Scrub the registry
      #     clone / logs / scratchspaces so the content (and thus the hash) is stable.
      #   Stage 2 (normal drv): copy the FOD into $out, Pkg.precompile at $out under
      #     the headless-GL recipe (Xvfb + mesa.drivers software llvmpipe) so GLMakie's
      #     .ji embed THIS $out path (valid when used at $out), and autopatchelf the JLL
      #     executables (ffmpeg etc.) so they get a nix ELF interpreter (no FHS loader).
      # Build this on x86_64 GH Actions (sandbox=false, Xvfb trivial) → binary cache →
      # Spindle PULLS it (no depot rebuild on Spindle). Render uses runtime Xvfb.
      blogDepotSrcFor = pkgs: system:
        let julia = juliaOfficialFor pkgs system; in
        pkgs.stdenv.mkDerivation {
          pname = "blog-depot-src";
          version = "1.10.3";
          dontUnpack = true;
          nativeBuildInputs = [ julia pkgs.cacert pkgs.git pkgs.curl ];
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          # Per-system: instantiate pulls per-arch JLL artifacts → content (hash) differs.
          # aarch64 = local container; x86_64 = Spindle/GH (get its hash from a GH build).
          outputHash = {
            "aarch64-linux" = "sha256-1x4J3hFfwP2cubYd72MZ2Utz4yLv23chulQKxHvmyVU=";
            "x86_64-linux"  = "sha256-MXhGmbnBw9pVABuNN+jT72+ocwH1hRrLCUHVOrJd+Zc=";
          }.${system};
          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            export JULIA_DEPOT_PATH=$out
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            # Download only — DON'T auto-precompile here (Julia 1.10 instantiate
            # precompiles by default, and GLMakie's precompile needs GL/Xvfb which
            # only stage 2 provides). Precompile is stage 2's job, at the final $out.
            export JULIA_PKG_PRECOMPILE_AUTO=0
            mkdir -p $out
            cp ${./blog-depot/Project.toml} Project.toml
            cp ${./blog-depot/Manifest.toml} Manifest.toml
            julia --project=. -e 'using Pkg; Pkg.instantiate()'
            # Scrub non-deterministic bits so the FOD hash is stable across rebuilds:
            # the registry git clone, logs, scratchspaces, and any compiled cache.
            rm -rf $out/registries $out/logs $out/scratchspaces $out/clones $out/compiled
            find $out -name "*.log" -delete 2>/dev/null || true
            runHook postBuild
          '';
          dontInstall = true;
          dontFixup = true;
        };

      blogDepotFor = pkgs: system:
        let
          julia = juliaOfficialFor pkgs system;
          src = blogDepotSrcFor pkgs system;
          xlibs = with pkgs.xorg; [ libX11 libXrandr libXinerama libXcursor libXi libXext libXxf86vm libXfixes ];
          glLibPath = pkgs.lib.makeLibraryPath ([ pkgs.libGL pkgs.libglvnd pkgs.mesa.drivers pkgs.mesa ] ++ xlibs);
        in
        pkgs.stdenv.mkDerivation {
          pname = "blog-depot";
          version = "1.10.3";
          dontUnpack = true;
          nativeBuildInputs = [ julia pkgs.xorg.xorgserver pkgs.patchelf ];
          buildInputs = [ pkgs.libGL pkgs.libglvnd pkgs.mesa.drivers pkgs.stdenv.cc.cc.lib pkgs.zlib ] ++ xlibs;
          # dontFixup: NEVER let stdenv strip/patchelf the depot — modifying artifact .so
          # libs AFTER precompile invalidates the .ji cache (Julia re-checks them on load).
          # We patch ONLY the JLL executables' interpreter ourselves, leaving libs pristine.
          dontFixup = true;
          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            mkdir -p $out
            cp -a ${src}/. $out/
            chmod -R u+w $out
            export JULIA_DEPOT_PATH=$out
            # Offline + a placeholder registry. precompile→instantiate calls
            # download_default_registries, which downloads ONLY IF reachable_registries()
            # is empty (offline env does NOT gate it). The FOD has no registry (a real one
            # drifts daily → unstable hash), so seed a dummy registry here: the check then
            # passes, and a complete Manifest makes registry *content* irrelevant
            # (instantiate just verifies the pinned packages are present — they are).
            export JULIA_PKG_OFFLINE=true
            mkdir -p $out/registries/Dummy
            {
              echo 'name = "Dummy"'
              echo 'uuid = "00000000-0000-0000-0000-000000000001"'
              echo 'repo = ""'
              echo '[packages]'
            } > $out/registries/Dummy/Registry.toml
            export LD_LIBRARY_PATH=${glLibPath}
            export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri
            export LIBGL_ALWAYS_SOFTWARE=1
            export GALLIUM_DRIVER=llvmpipe
            export __GLX_VENDOR_LIBRARY_NAME=mesa
            export DISPLAY=:73
            rm -f /tmp/.X73-lock /tmp/.X11-unix/X73 2>/dev/null || true
            ${pkgs.xorg.xorgserver}/bin/Xvfb :73 -screen 0 1280x1024x24 +extension GLX +render -noreset >/tmp/xvfb73.log 2>&1 &
            XPID=$!
            sleep 4
            cp ${./blog-depot/Project.toml} Project.toml
            cp ${./blog-depot/Manifest.toml} Manifest.toml
            julia --project=. -e 'using Pkg; Pkg.precompile()'
            julia --project=. -e 'using GLMakie; println("depot OK: GLMakie loads")'
            kill $XPID 2>/dev/null || true

            # The Dummy registry was only needed to satisfy reachable_registries() during
            # this build's offline precompile. At RUNTIME (Quarto + Spindle) a real
            # registry is wanted: Quarto's ensureQuartoNotebookRunnerEnvironment runs
            # Pkg.up → check_registered, which fails if the only reachable registry is
            # the empty Dummy AND only_if_empty=true keeps Pkg from downloading the real
            # one. Removing the Dummy leaves reachable_registries() empty so Pkg installs
            # General (writable depot path on Spindle) and check_registered succeeds.
            rm -rf $out/registries/Dummy

            # Patch ONLY the JLL executables' ELF interpreter to nix's loader (the same
            # one nix gave the julia binary) so they spawn on nix/Spindle (no FHS
            # /lib*/ld-linux). Their NEEDED .so libs resolve at runtime via $ORIGIN +
            # the artifact lib dirs Julia puts on LD_LIBRARY_PATH. Leaving the libs
            # untouched keeps every .ji valid. Mainly fixes FFMPEG_jll's ffmpeg (Makie
            # spawns it to encode the mp4s); patching all artifact bins is harmless.
            LOADER=$(patchelf --print-interpreter ${julia}/bin/julia)
            echo "patching JLL exec interpreters → $LOADER"
            n=0
            for exe in $(find $out/artifacts -type f -path '*/bin/*' 2>/dev/null); do
              if patchelf --print-interpreter "$exe" >/dev/null 2>&1; then
                patchelf --set-interpreter "$LOADER" "$exe" 2>/dev/null && n=$((n+1)) || true
              fi
            done
            echo "patched $n JLL executables"
            runHook postBuild
          '';
          dontInstall = true;
        };
    in {
      packages = forAll (system:
        let pkgs = pkgsFor system; in {
          pikchr = pikchrFor pkgs;
          typst-ts-cli = typstTsFor pkgs system;
          julia-official = juliaOfficialFor pkgs system;
          blog-depot-src = blogDepotSrcFor pkgs system;
          blog-depot = blogDepotFor pkgs system;
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

          # Headless-render environment: official julia + the software-GL stack
          # (mesa.drivers llvmpipe + libglvnd + X libs) + Xvfb, with the proven GL
          # recipe exported. Used to render ca-in-julia against the precompiled depot
          # (CI validation now; the same env Spindle uses for the live render). Start
          # Xvfb + point JULIA_DEPOT_PATH at the depot, then `julia --project … render`.
          blog-render =
            let
              julia = juliaOfficialFor pkgs system;
              xlibs = with pkgs.xorg; [ libX11 libXrandr libXinerama libXcursor libXi libXext libXxf86vm libXfixes ];
              glLibPath = pkgs.lib.makeLibraryPath ([ pkgs.libGL pkgs.libglvnd pkgs.mesa.drivers pkgs.mesa ] ++ xlibs);
            in pkgs.mkShell {
              packages = [ julia pkgs.xorg.xorgserver ];
              shellHook = ''
                export LD_LIBRARY_PATH="${glLibPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                export LIBGL_DRIVERS_PATH="${pkgs.mesa.drivers}/lib/dri"
                export LIBGL_ALWAYS_SOFTWARE=1
                export GALLIUM_DRIVER=llvmpipe
                export __GLX_VENDOR_LIBRARY_NAME=mesa
              '';
            };
        });
    };
}
