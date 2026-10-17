{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  sources = lib.importJSON ./sources.json;

  pname = "plane-desktop";
  inherit (sources) version;

  src = fetchurl {
    inherit (sources) url hash;
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  # The AppImage ships its desktop entry and icons under the generic name
  # "desktop", so they are renamed to avoid clashing with other packages.
  #
  # Sign-in (e.g. with Google) finishes in the browser, which hands the session
  # back through a plane:// link; the entry has to claim that scheme for it to
  # reach the app, since the app cannot register itself from the Nix store.
  extraInstallCommands = ''
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    install -Dm444 ${appimageContents}/desktop.desktop $out/share/applications/${pname}.desktop
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U' \
      --replace-fail 'Icon=desktop' 'Icon=${pname}'
    echo 'MimeType=x-scheme-handler/plane;' >> $out/share/applications/${pname}.desktop

    for icon in ${appimageContents}/usr/share/icons/hicolor/*/apps/desktop.png; do
      size=$(basename "$(dirname "$(dirname "$icon")")")
      install -Dm444 "$icon" $out/share/icons/hicolor/$size/apps/${pname}.png
    done
  '';

  passthru = {
    inherit (sources) build;
  };

  meta = {
    description = "Desktop client for Plane, the open-source project management tool";
    homepage = "https://plane.so";
    downloadPage = "https://plane.so/download";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
