{
  writeShellApplication,
  curl,
  jq,
  yq-go,
}:

writeShellApplication {
  name = "update-plane-desktop";
  runtimeInputs = [
    curl
    jq
    yq-go
  ];
  text = ''
    # Plane distributes the desktop app through ToDesktop, whose electron-builder
    # style manifest already carries the version, file name and sha512 of the
    # latest AppImage, so nothing has to be downloaded to bump the pin.
    base="https://download.todesktop.com/260130r75i625"
    sources="''${1:-pkgs/plane-desktop/sources.json}"

    manifest=$(curl -fsSL "$base/latest-linux.yml")

    version=$(yq -r '.version' <<<"$manifest")
    file=$(yq -r '.path' <<<"$manifest")
    sha512=$(yq -r '.sha512' <<<"$manifest")
    build=$(sed -E 's/.*-build-([^-]+)-x86_64\.AppImage$/\1/' <<<"$file")

    current=$(jq -r '.version + "+" + .build' "$sources")
    if [[ "$current" == "$version+$build" ]]; then
      echo "plane-desktop is up to date ($version, build $build)"
      exit 0
    fi

    jq -n \
      --arg version "$version" \
      --arg build "$build" \
      --arg url "$base/$file" \
      --arg hash "sha512-$sha512" \
      '{version: $version, build: $build, url: $url, hash: $hash}' >"$sources"

    echo "plane-desktop: $current -> $version+$build"
  '';
}
