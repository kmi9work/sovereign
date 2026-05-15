#!/bin/bash
# Generate app icons for Android and iOS from source icon
# Source: native/assets/icon.png (512x512)

set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
NATIVE_DIR="$PROJECT_DIR/native"
ICON_SRC="$NATIVE_DIR/assets/icon.png"

if [ ! -f "$ICON_SRC" ]; then
    echo "Error: Source icon not found at $ICON_SRC"
    exit 1
fi

# --- Android mipmap icons ---
# Density    | Size
# ---------------
# mdpi       | 48x48
# hdpi       | 72x72
# xhdpi      | 96x96
# xxhdpi     | 144x144
# xxxhdpi    | 192x192

ANDROID_RES="$NATIVE_DIR/android/app/src/main/res"

declare -A ANDROID_SIZES=(
    ["mipmap-mdpi"]=48
    ["mipmap-hdpi"]=72
    ["mipmap-xhdpi"]=96
    ["mipmap-xxhdpi"]=144
    ["mipmap-xxxhdpi"]=192
)

echo "=== Android icons ==="
for dir in "${!ANDROID_SIZES[@]}"; do
    size="${ANDROID_SIZES[$dir]}"
    echo "  $dir (${size}x${size})"
    convert "$ICON_SRC" -resize "${size}x${size}" "$ANDROID_RES/$dir/ic_launcher.png"
    convert "$ICON_SRC" -resize "${size}x${size}" "$ANDROID_RES/$dir/ic_launcher_round.png"
done

# --- iOS AppIcon ---
# Contents.json defines:
# Size    Scale  | Output
# ----------------------
# 20x20   @2x    | 40x40
# 20x20   @3x    | 60x60
# 29x29   @2x    | 58x58
# 29x29   @3x    | 87x87
# 40x40   @2x    | 80x80
# 40x40   @3x    | 120x120
# 60x60   @2x    | 120x120
# 60x60   @3x    | 180x180
# 1024x1024 @1x  | 1024x1024 (marketing)

IOS_APPICON="$NATIVE_DIR/ios/SovereignApp/Images.xcassets/AppIcon.appiconset"

echo ""
echo "=== iOS icons ==="

declare -A IOS_ICONS=(
    ["icon-20@2x.png"]=40
    ["icon-20@3x.png"]=60
    ["icon-29@2x.png"]=58
    ["icon-29@3x.png"]=87
    ["icon-40@2x.png"]=80
    ["icon-40@3x.png"]=120
    ["icon-60@2x.png"]=120
    ["icon-60@3x.png"]=180
    ["icon-1024.png"]=1024
)

for filename in "${!IOS_ICONS[@]}"; do
    size="${IOS_ICONS[$filename]}"
    echo "  $filename (${size}x${size})"
    convert "$ICON_SRC" -resize "${size}x${size}" "$IOS_APPICON/$filename"
done

# Update Contents.json to reference the files
cat > "$IOS_APPICON/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✓ Done — icons generated for Android and iOS"
