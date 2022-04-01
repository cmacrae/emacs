{
  description = "Nightly custom Emacs builds for macOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    emacs-src = {
      url = "github:emacs-mirror/emacs";
      flake = false;
    };

    emacs-vterm-src = {
      url = "github:akermu/emacs-libvterm";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, emacs-src, emacs-vterm-src }:
    let
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      packages = forAllSystems (system: {
        emacs = nixpkgsFor.${system}.emacs;
        emacs-vterm = nixpkgsFor.${system}.emacs-vterm;
      });

      overlay = final: prev: {
        emacs-vterm = prev.stdenv.mkDerivation rec {
          pname = "emacs-vterm";
          version = "master";

          src = emacs-vterm-src;

          nativeBuildInputs = [
            prev.cmake
            prev.libtool
            prev.glib.dev
          ];

          buildInputs = [
            prev.glib.out
            prev.libvterm-neovim
            prev.ncurses
          ];

          cmakeFlags = [
            "-DUSE_SYSTEM_LIBVTERM=yes"
          ];

          preConfigure = ''
            echo "include_directories(\"${prev.glib.out}/lib/glib-2.0/include\")" >> CMakeLists.txt
            echo "include_directories(\"${prev.glib.dev}/include/glib-2.0\")" >> CMakeLists.txt
            echo "include_directories(\"${prev.ncurses.dev}/include\")" >> CMakeLists.txt
            echo "include_directories(\"${prev.libvterm-neovim}/include\")" >> CMakeLists.txt
          '';

          installPhase = ''
            mkdir -p $out
            cp ../vterm-module.so $out
            cp ../vterm.el $out
          '';
        };

        emacs = (prev.emacs.override { srcRepo = true; nativeComp = true; withXwidgets = true; }).overrideAttrs (
          o: rec {
            version = "29.0.50";
            src = emacs-src;

            buildInputs = o.buildInputs ++ [ prev.darwin.apple_sdk.frameworks.WebKit ];

            patches = [
              ./patches/fix-window-role.patch
            ];

            postPatch = o.postPatch + ''
              substituteInPlace lisp/loadup.el \
              --replace '(emacs-repository-get-branch)' '"master"'
            '';

            postInstall = o.postInstall + ''
              cp ${final.emacs-vterm}/vterm.el $out/share/emacs/site-lisp/vterm.el
              cp ${final.emacs-vterm}/vterm-module.so $out/share/emacs/site-lisp/vterm-module.so
            '';

            CFLAGS = "-DMAC_OS_X_VERSION_MAX_ALLOWED=110203 -g -O2";
          }
        );
      };
    };
}
