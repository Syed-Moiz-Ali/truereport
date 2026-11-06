# TrueReport UI gallery (developer-only)

Renders every F1 design token and shared component. It is not a product app and is not part of a release.

## Run

```powershell
cd client
flutter pub get
cd apps/ui_gallery
flutter run -d chrome
```

Build a static web copy:

```powershell
flutter build web --release
```

## Controls

- Locale: English / العربية
- Theme: light-only (C0 Workstream B removed the dark toggle)
- Text scale: 1.0x / 1.5x / 2.0x
- A2 strategy: emeraldFill / deepGreenFill (also shown side by side)
- Arabic font: Noto Sans Arabic / IBM Plex Sans Arabic
- Viewport width: 390 / 600 / 900 / 1280

## URL parameters (for screenshots and QA)

```
?lang=en|ar
&scale=1|1.5|2
&strategy=emerald|deepGreen
&font=noto|ibm
&width=390|600|900|1280
&autofocus=0
```

Light-only (C0 Workstream B): the `&theme=` parameter was removed; the
gallery always renders the light theme.

`autofocus=0` prevents the focused-field specimen from scrolling the gallery.

The gallery loads bundled fonts from `client/packages/design_system/assets/fonts/`; it never downloads fonts at runtime.

## What it is not

- Not a screen implementation. Real screens start in F2.
- Not a fidelity baseline; the harness in `tools/figma_fidelity/` measures fidelity.
- Not a replacement for the accessibility matrix, the component tests or the F1 report.
