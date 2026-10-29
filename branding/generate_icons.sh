#!/bin/sh
# Regenerates every iOS and Android launcher icon from branding/*.svg.
# Needs rsvg-convert and ImageMagick (brew install librsvg imagemagick).
set -eu
cd "$(dirname "$0")/.."

render() { # svg, size px, output png
  rsvg-convert -w "$2" -h "$2" "$1" -o "$3"
}

ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
for spec in 20x20@1x:20 20x20@2x:40 20x20@3x:60 29x29@1x:29 29x29@2x:58 29x29@3x:87 \
            40x40@1x:40 40x40@2x:80 40x40@3x:120 60x60@2x:120 60x60@3x:180 \
            76x76@1x:76 76x76@2x:152 83.5x83.5@2x:167 1024x1024@1x:1024; do
  name=${spec%%:*}
  px=${spec##*:}
  render branding/logo.svg "$px" "$ios/Icon-App-$name.png"
  # App Store rejects icons with an alpha channel.
  magick "$ios/Icon-App-$name.png" -background '#1A2350' -alpha remove -alpha off "$ios/Icon-App-$name.png"
done

res=android/app/src/main/res
for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  density=${spec%%:*}
  rest=${spec#*:}
  legacy=${rest%%:*}
  adaptive=${rest##*:}
  render branding/logo.svg "$legacy" "$res/mipmap-$density/ic_launcher.png"
  render branding/logo_foreground.svg "$adaptive" "$res/mipmap-$density/ic_launcher_foreground.png"
done
