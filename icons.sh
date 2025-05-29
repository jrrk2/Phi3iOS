#!/bin/bash

# Generate all required icon sizes
echo "Generating all iOS app icon sizes..."

ORIGINAL="icon-1024.png"

# iPhone sizes
sips -z 20 20 $ORIGINAL --out AppIcon-20@1x.png
sips -z 40 40 $ORIGINAL --out AppIcon-20@2x.png  
sips -z 60 60 $ORIGINAL --out AppIcon-20@3x.png
sips -z 29 29 $ORIGINAL --out AppIcon-29@1x.png
sips -z 58 58 $ORIGINAL --out AppIcon-29@2x.png
sips -z 87 87 $ORIGINAL --out AppIcon-29@3x.png
sips -z 40 40 $ORIGINAL --out AppIcon-40@1x.png
sips -z 80 80 $ORIGINAL --out AppIcon-40@2x.png
sips -z 120 120 $ORIGINAL --out AppIcon-40@3x.png
sips -z 120 120 $ORIGINAL --out AppIcon-60@2x.png
sips -z 180 180 $ORIGINAL --out AppIcon-60@3x.png

# iPad sizes  
sips -z 76 76 $ORIGINAL --out AppIcon-76@1x.png
sips -z 152 152 $ORIGINAL --out AppIcon-76@2x.png
sips -z 167 167 $ORIGINAL --out AppIcon-83.5@2x.png

echo "✅ All icon sizes generated!"
echo "Now drag these into your Assets.xcassets → AppIcon slots"
