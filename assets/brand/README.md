# Polytechnium brand assets

This folder holds the app icon. It has the look of the ZettaStream icon.

## Design

The mark is a bold geometric P. The mark carries a gradient from white to grey. The background is the dark app colour with a soft grey glow.

## Colours

| Name | Hex | Use |
| --- | --- | --- |
| Background | `#000000` | Icon background. Same as the app background. |
| Glow | `#2a2a2a` | Centre of the radial glow behind the mark. |
| White | `#ffffff` | Start of the mark gradient. |
| Grey | `#e0e0e0` | Middle of the mark gradient. |
| Dark grey | `#9a9a9a` | End of the mark gradient. |

## SVG sources

| File | Use |
| --- | --- |
| `icon-ios.svg` | The iOS app icon. It is square, with no clip, because iOS rounds the corners itself. `App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` is its render at 1024x1024. |
| `icon-full.svg` | The complete square icon with rounded corners. Use it for previews and the README. |

## PNG renders

| File | Size | Use |
| --- | --- | --- |
| `icon-512.png` | 512x512 | The icon of the app in the SideStore source. |

## How to render again

Use `rsvg-convert` from the SVG sources:

    rsvg-convert -w 512 -h 512 icon-full.svg -o icon-512.png
    rsvg-convert -w 1024 -h 1024 -b '#000000' icon-ios.svg -o ../../App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
