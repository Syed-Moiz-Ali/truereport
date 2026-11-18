# Baseline build / bundle size

```
$ cd client/apps/workshop_admin_app
$ flutter build web --release
Wasm dry run succeeded.
Font asset "MaterialIcons-Regular.otf" was tree-shaken: 1,645,184 -> 23,908 bytes (98.5%)
√ Built build\web            (84.6 s)
```

**Build status: PASS.**

| Artifact | Size |
|---|---|
| `build/web` total | **60.99 MB** (63,948,109 bytes) |
| `main.dart.js` | 4.03 MB |
| `NotoSansSC-Regular.otf` | **16.05 MB** |
| `canvaskit.wasm` (largest of 4 variants) | 7.11 MB |
| `skwasm_heavy.wasm` | 5.09 MB |
| `main.dart.js` + framework wasm | ~21 MB |

Build warnings observed (not failures):

1. `Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons),
   but found (MaterialIcons)` — some widget references a `CupertinoIcons` glyph while
   `cupertino_icons` is not a declared dependency of this app. Harmless at runtime (the glyph
   resolves to the Material fallback) but it means an icon is silently not what was intended.
2. `Wasm dry run succeeded` — the app is wasm-ready; `wimp.wasm`/`skwasm*` ship alongside the
   JS build.

**Bundle finding (not in the top-10 because it is not a sign-in blocker):**
only `en` and `ar` are supported locales, yet the design system ships and the app bundles
`Noto Sans SC` (16.05 MB), `Noto Sans Telugu` (3 weights) and `Noto Sans` (Cyrillic).
Roughly **25% of the whole download is fallback fonts for scripts this product does not
support.** Removing/limiting them is a one-line pubspec change with no visual impact for
`en`/`ar` and belongs in Brief 1's scope only if the owner approves a bundle budget.

Baseline to beat: **60.99 MB total / 4.03 MB main.dart.js**, build time 84.6 s.
