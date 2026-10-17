# plane

Nix flake for [Plane](https://plane.so), the open-source project management tool.

Currently it packages the **Plane desktop app** (`plane-desktop`, x86_64-linux only, since
that is the only Linux build Plane publishes). A NixOS module for self-hosting the Plane
server may be added later.

## Usage

Try it without installing:

```bash
nix run github:TiagoDamascena/plane
```

### NixOS / Home Manager

Add the flake as an input and apply the overlay, which adds `pkgs.plane-desktop`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    plane = {
      url = "github:TiagoDamascena/plane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, plane, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ plane.overlays.default ];
          environment.systemPackages = [ pkgs.plane-desktop ];
        })
      ];
    };
  };
}
```

Or use the package directly, without the overlay:

```nix
environment.systemPackages = [ plane.packages.x86_64-linux.plane-desktop ];
```

On Wayland, set `NIXOS_OZONE_WL=1` to run the app natively instead of through XWayland.

## Updates

The version is pinned in [`pkgs/plane-desktop/sources.json`](pkgs/plane-desktop/sources.json).
Plane ships the desktop app through ToDesktop, and its release manifest
(`latest-linux.yml`) already includes the file name and sha512 of the newest AppImage, so
bumping the pin does not require downloading it.

A scheduled GitHub Action runs the update script daily and opens a pull request when a new
release is out. To run it by hand:

```bash
nix run .#update
```

The app's built-in auto-updater turns itself off when it is not running from an AppImage,
so updates only come through this flake.

## License

The Nix expressions and scripts in this repository are licensed under the [MIT License](LICENSE).
Plane itself is distributed by its authors under the AGPL-3.0.
