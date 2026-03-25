#!/bin/zsh
set -e

ICONSET="/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Assets.xcassets/AppIcon.appiconset"
SRC="/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/fastflow_app_icon_master.png"

sips -z 1024 1024 "$SRC" --out "$ICONSET/Icon-1024.png" >/dev/null
sips -z 40 40 "$SRC" --out "$ICONSET/Icon-20@2x.png" >/dev/null
sips -z 60 60 "$SRC" --out "$ICONSET/Icon-20@3x.png" >/dev/null
sips -z 58 58 "$SRC" --out "$ICONSET/Icon-29@2x.png" >/dev/null
sips -z 87 87 "$SRC" --out "$ICONSET/Icon-29@3x.png" >/dev/null
sips -z 80 80 "$SRC" --out "$ICONSET/Icon-40@2x.png" >/dev/null
sips -z 120 120 "$SRC" --out "$ICONSET/Icon-40@3x.png" >/dev/null
sips -z 120 120 "$SRC" --out "$ICONSET/Icon-60@2x.png" >/dev/null
sips -z 180 180 "$SRC" --out "$ICONSET/Icon-60@3x.png" >/dev/null
sips -z 20 20 "$SRC" --out "$ICONSET/Icon-20.png" >/dev/null
sips -z 40 40 "$SRC" --out "$ICONSET/Icon-20@2x-ipad.png" >/dev/null
sips -z 29 29 "$SRC" --out "$ICONSET/Icon-29.png" >/dev/null
sips -z 58 58 "$SRC" --out "$ICONSET/Icon-29@2x-ipad.png" >/dev/null
sips -z 40 40 "$SRC" --out "$ICONSET/Icon-40.png" >/dev/null
sips -z 80 80 "$SRC" --out "$ICONSET/Icon-40@2x-ipad.png" >/dev/null
sips -z 76 76 "$SRC" --out "$ICONSET/Icon-76.png" >/dev/null
sips -z 152 152 "$SRC" --out "$ICONSET/Icon-76@2x.png" >/dev/null
sips -z 167 167 "$SRC" --out "$ICONSET/Icon-83.5@2x.png" >/dev/null
