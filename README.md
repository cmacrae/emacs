# Nightly custom Emacs builds for macOS Nix environments
[![CI badge](https://github.com/cmacrae/emacs/actions/workflows/build.yaml/badge.svg)](https://github.com/cmacrae/emacs/actions/workflows/build.yaml)
[![BuiltWithNix badge](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?logo=nixos&labelColor=73C3D5)](https://builtwithnix.org)
[![Cachix badge](https://img.shields.io/badge/Cachix-store-blue.svg?logo=hack-the-box&logoColor=73C3D5)](https://app.cachix.org/cache/emacs)
[![Emacs badge](https://img.shields.io/badge/Emacs-29.0.50-adadad.svg?logo=gnu-emacs&labelColor=9266CC&logoColor=ffffff)](http://git.savannah.gnu.org/cgit/emacs.git/log/)

This repository provides nightly automated builds of Emacs from HEAD for macOS Nix environments with the following additions:
- Native Compilation ([gccemacs](https://www.emacswiki.org/emacs/GccEmacs))
- [X Widgets](https://www.emacswiki.org/emacs/EmacsXWidgets) (Webkit) support
- [libvterm](https://github.com/akermu/emacs-libvterm)
- Patched window role to work nicely with [yabai](https://github.com/koekeishiya/yabai)

## Recent Changes

The `no-titlebar` frame patch has been removed, as it can be implemented with
pure Emacs Lisp by putting the following early on during initialization (e.g. in
`early-init.el`):

```emacs-lisp
(add-to-list 'default-frame-alist '(undecorated . t))
```

See https://github.com/d12frosted/homebrew-emacs-plus/issues/433#issuecomment-1025547880 for further background.

## Usage

To use this flake on your system, add it to your configuration inputs & overlays.  
It overlays the `pkgs.emacs` package.  
There is a [complimentary binary cache](https://app.cachix.org/cache/emacs) available which is pushed to nightly.
```nix
{
  inputs.darwin.url = "github:lnl7/nix-darwin";
  inputs.emacs.url = "github:cmacrae/emacs";

  outputs = { self, darwin, emacs }: {
    darwinConfigurations.example = darwin.lib.darwinSystem {
      modules = [
        {
          nix.binaryCaches = [
            "https://cachix.org/api/v1/cache/emacs"
          ];

          nix.binaryCachePublicKeys = [
            "emacs.cachix.org-1:b1SMJNLY/mZF6GxQE+eDBeps7WnkT0Po55TAyzwOxTY="
          ];

          nixpkgs.overlays = [
            emacs.overlay
          ];
        }
      ];
    };
  };
}
```
