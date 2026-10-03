#!/usr/bin/env bash
# Integrate the packaged Linux AppImage into the user's desktop menu and dock.
#
# Creates a stable copy under ~/Applications, installs hicolor icons generated
# from resources/icon.png, and writes ~/.local/share/applications/deepseek-harness.desktop.
# The desktop file basename must equal package.json's desktopName (minus suffix),
# which Electron reports as the Wayland app_id / X11 WM_CLASS, so GNOME links
# running windows to this entry and shows the app icon in the dock.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(dirname "$SCRIPT_DIR")"                       # apps/desktop
ARTIFACTS="$APP_ROOT/.desktop-build/targets/linux-x64/artifacts"
STABLE_DIR="$HOME/Applications"
STABLE_APP="$STABLE_DIR/DeepSeek-Harness.AppImage"
ICONS_DIR="$HOME/.local/share/icons/hicolor"
ENTRIES_DIR="$HOME/.local/share/applications"
ENTRY="$ENTRIES_DIR/deepseek-harness.desktop"

# Optional argument: explicit AppImage path; otherwise take the newest build.
APPIMAGE="${1:-}"
if [[ -z "$APPIMAGE" ]]; then
  APPIMAGE="$(ls -t "$ARTIFACTS"/*.AppImage 2>/dev/null | head -1 || true)"
fi
if [[ -z "$APPIMAGE" || ! -f "$APPIMAGE" ]]; then
  echo "error: no AppImage found; build first or pass its path as argument" >&2
  exit 1
fi

echo "source:  $APPIMAGE"
mkdir -p "$STABLE_DIR"
cp -f "$APPIMAGE" "$STABLE_APP"
chmod +x "$STABLE_APP"
echo "installed: $STABLE_APP"

# Resize the original artwork into the standard hicolor sizes.
if [[ ! -d "$APP_ROOT/node_modules/sharp" ]]; then
  echo "error: sharp missing; run 'pnpm install' at the repository root first" >&2
  exit 1
fi
node -e '
const sharp = require(process.argv[1]);
const { mkdirSync } = require("node:fs");
const { join } = require("node:path");
const src = process.argv[2];
const dst = process.argv[3];
(async () => {
  for (const size of [512, 256, 128, 48]) {
    const dir = join(dst, `${size}x${size}`, "apps");
    mkdirSync(dir, { recursive: true });
    await sharp(src).resize(size, size).png().toFile(join(dir, "deepseek-harness.png"));
  }
  console.log(`icons:    wrote 512/256/128/48 into ${process.argv[3]}`);
})().catch(error => { console.error(error); process.exit(1) });
' "$APP_ROOT/node_modules/sharp" "$APP_ROOT/resources/icon.png" "$ICONS_DIR"

# Write the desktop entry after the icons exist so icon lookups never cache a miss.
mkdir -p "$ENTRIES_DIR"
cat > "$ENTRY" <<EOF
[Desktop Entry]
Type=Application
Name=DeepSeek Harness
Comment=Electron desktop shell for a bundled dsh runtime and external plugins
Exec=$STABLE_APP %U
Icon=deepseek-harness
Terminal=false
Categories=Development;
MimeType=x-scheme-handler/dsh;
StartupWMClass=deepseek-harness
EOF
chmod 644 "$ENTRY"
echo "entry:    $ENTRY"

command -v update-desktop-database >/dev/null \
  && update-desktop-database "$ENTRIES_DIR" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null \
  && gtk-update-icon-cache -f -t "$ICONS_DIR" >/dev/null 2>&1 || true

echo "done. Search 'DeepSeek' in the app grid; log out/in if a stale generic icon persists."
