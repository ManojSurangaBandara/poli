# Custom App Icon Setup

## Icon Requirements

### Main Icon (app_icon.png)
- **Size**: 1024x1024 pixels (square)
- **Format**: PNG with transparent background
- **Location**: `assets/icon/app_icon.png`

### Adaptive Icon Foreground (app_icon_foreground.png) - Android Only
- **Size**: 432x432 pixels (square, centered in 108x108 safe zone)
- **Format**: PNG with transparent background
- **Location**: `assets/icon/app_icon_foreground.png`

## How to Create Custom Icons

1. **Design your icon** in any graphic design software (Photoshop, GIMP, Figma, etc.)
2. **Save as PNG** with transparent background
3. **Place files** in the `assets/icon/` directory:
   - `app_icon.png` (1024x1024) - used for iOS and fallback Android
   - `app_icon_foreground.png` (432x432) - used for Android adaptive icon

## Generate Icons

After placing your icon files, run:
```bash
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for Android and iOS.

## Color Customization

The adaptive icon background color is set to `#2563EB` (your app's primary blue). You can change this in `pubspec.yaml`:

```yaml
flutter_icons:
  adaptive_icon_background: "#YOUR_COLOR_HERE"
```

## Current Icon Setup

Your app currently uses the default Flutter launcher icon. Once you add custom icons and run the generation command, they will replace the default icons on both Android and iOS.