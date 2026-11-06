import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { generateContrastMarkdown } from "./contrast.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..", "..");

const paths = {
  tokens: path.join(
    root,
    "client",
    "packages",
    "design_system",
    "tokens",
    "tokens.json",
  ),
  dart: path.join(
    root,
    "client",
    "packages",
    "design_system",
    "lib",
    "src",
    "generated",
    "tokens.g.dart",
  ),
  css: path.join(
    root,
    "server",
    "src",
    "main",
    "resources",
    "public-report",
    "tokens.g.css",
  ),
  contrast: path.join(root, "docs", "ui", "figma", "contrast-after.md"),
};

function readTokens() {
  return JSON.parse(fs.readFileSync(paths.tokens, "utf8"));
}

function kebab(value) {
  return value.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`);
}

function dartColor(hex) {
  const value = hex.replace("#", "").toUpperCase();
  if (value.length === 6) {
    return `Color(0xFF${value})`;
  }
  if (value.length === 8) {
    return `Color(0x${value.slice(6, 8)}${value.slice(0, 6)})`;
  }
  throw new Error(`Unsupported hex colour: ${hex}`);
}

function number(value) {
  return Object.is(value, -0) ? "0" : String(value);
}

function generateDart(tokens) {
  const lines = [];
  lines.push("// GENERATED FILE - DO NOT EDIT.");
  lines.push("// Source: client/packages/design_system/tokens/tokens.json");
  lines.push("// Regenerate: node tools/design_tokens/generate.mjs --write");
  lines.push("");
  lines.push("import 'package:flutter/material.dart';");
  lines.push("");

  const colourClass = (name, colourTokens) => {
    const body = Object.entries(colourTokens)
      .map(
        ([token, value]) =>
          `  static const Color ${token} = ${dartColor(value)};`,
      )
      .join("\n");
    return `abstract final class ${name} {\n${body}\n}`;
  };

  // C0 Workstream B (light-only): dark colour classes are no longer emitted.
  // `tokens.json` may still carry `color.dark` until the lead removes it;
  // the generator intentionally ignores it so build outputs stay light-only.
  lines.push(colourClass("TrColorLight", tokens.color.light));
  lines.push("");

  lines.push("@immutable");
  lines.push("class TrBrandColors {");
  lines.push("  const TrBrandColors({");
  lines.push("    required this.fill,");
  lines.push("    required this.onFill,");
  lines.push("    required this.ink,");
  lines.push("    required this.container,");
  lines.push("    required this.onContainer,");
  lines.push("  });");
  lines.push("");
  lines.push("  final Color fill;");
  lines.push("  final Color onFill;");
  lines.push("  final Color ink;");
  lines.push("  final Color container;");
  lines.push("  final Color onContainer;");
  lines.push("}");
  lines.push("");

  const brandClass = (name, brandTokens) => {
    const entries = Object.entries(brandTokens)
      .map(([strategy, values]) => {
        const fields = Object.entries(values)
          .map(([field, value]) => `    ${field}: ${dartColor(value)},`)
          .join("\n");
        return `  static const TrBrandColors ${strategy} = TrBrandColors(\n${fields}\n  );`;
      })
      .join("\n\n");
    return `abstract final class ${name} {\n${entries}\n}`;
  };

  lines.push(brandClass("TrBrandLight", {
    emeraldFill: tokens.brand.emeraldFill.light,
    deepGreenFill: tokens.brand.deepGreenFill.light,
  }));
  lines.push("");

  lines.push("@immutable");
  lines.push("class TrStatusPair {");
  lines.push("  const TrStatusPair({");
  lines.push("    required this.foreground,");
  lines.push("    required this.background,");
  lines.push("  });");
  lines.push("");
  lines.push("  final Color foreground;");
  lines.push("  final Color background;");
  lines.push("}");
  lines.push("");

  const statusClass = (name, statusTokens) => {
    const entries = Object.entries(statusTokens)
      .map(
        ([tone, pair]) =>
          `  static const TrStatusPair ${tone} = TrStatusPair(\n    foreground: ${dartColor(pair.foreground)},\n    background: ${dartColor(pair.background)},\n  );`,
      )
      .join("\n\n");
    return `abstract final class ${name} {\n${entries}\n}`;
  };

  lines.push(statusClass("TrStatusLight", tokens.status.light));
  lines.push("");

  lines.push("@immutable");
  lines.push("class TrSeverityToken {");
  lines.push("  const TrSeverityToken({required this.tone, required this.icon});");
  lines.push("");
  lines.push("  final String tone;");
  lines.push("  final IconData icon;");
  lines.push("}");
  lines.push("");
  lines.push("abstract final class TrSeverityMap {");
  for (const item of tokens.severity) {
    lines.push(
      `  static const TrSeverityToken ${item.name} = TrSeverityToken(tone: '${item.tone}', icon: Icons.${item.icon});`,
    );
  }
  lines.push("}");
  lines.push("");

  lines.push("@immutable");
  lines.push("class TrInspectionResultToken {");
  lines.push(
    "  const TrInspectionResultToken({required this.tone, required this.icon});",
  );
  lines.push("");
  lines.push("  final String tone;");
  lines.push("  final IconData icon;");
  lines.push("}");
  lines.push("");
  lines.push("abstract final class TrInspectionResultMap {");
  for (const item of tokens.inspectionResult) {
    lines.push(
      `  static const TrInspectionResultToken ${item.name} = TrInspectionResultToken(tone: '${item.tone}', icon: Icons.${item.icon});`,
    );
  }
  lines.push("}");
  lines.push("");

  lines.push("@immutable");
  lines.push("class TrTypeStyleToken {");
  lines.push("  const TrTypeStyleToken({");
  lines.push("    required this.size,");
  lines.push("    required this.lineHeight,");
  lines.push("    required this.weight,");
  lines.push("    required this.tracking,");
  lines.push("  });");
  lines.push("");
  lines.push("  final double size;");
  lines.push("  final double lineHeight;");
  lines.push("  final int weight;");
  lines.push("  final double tracking;");
  lines.push("");
  lines.push("  double get height => lineHeight / size;");
  lines.push("}");
  lines.push("");

  const typeStyle = (style) =>
    `TrTypeStyleToken(size: ${number(style.size)}, lineHeight: ${number(style.lineHeight)}, weight: ${style.weight}, tracking: ${number(style.tracking)})`;

  lines.push("abstract final class TrType {");
  for (const [name, style] of Object.entries(tokens.type.latin)) {
    lines.push(`  static const ${name} = ${typeStyle(style)};`);
  }
  lines.push("}");
  lines.push("");

  lines.push("abstract final class TrTypeArabic {");
  lines.push(
    `  static const double tracking = ${number(tokens.type.arabic.tracking)};`,
  );
  lines.push(
    `  static const double bodyLineHeightMultiplier = ${number(tokens.type.arabic.bodyLineHeightMultiplier)};`,
  );
  lines.push("");
  for (const [name, style] of Object.entries(tokens.type.latin)) {
    const body = ["bodyLg", "bodyMd", "bodySm"].includes(name);
    const lineHeight = body
      ? Number((style.size * tokens.type.arabic.bodyLineHeightMultiplier).toFixed(2))
      : style.lineHeight;
    lines.push(
      `  static const ${name} = TrTypeStyleToken(size: ${number(style.size)}, lineHeight: ${number(lineHeight)}, weight: ${style.weight}, tracking: ${number(tokens.type.arabic.tracking)});`,
    );
  }
  lines.push("}");
  lines.push("");

  lines.push("abstract final class TrFontFamilies {");
  lines.push(`  static const String latin = '${tokens.fontFamilies.latin}';`);
  lines.push(
    `  static const String arabicDefault = '${tokens.fontFamilies.arabicDefault}';`,
  );
  lines.push(
    `  static const String arabicAlternative = '${tokens.fontFamilies.arabicAlternative}';`,
  );
  lines.push(
    `  static const String cyrillicFallback = '${tokens.fontFamilies.cyrillicFallback}';`,
  );
  lines.push(
    `  static const String cjkFallback = '${tokens.fontFamilies.cjkFallback}';`,
  );
  lines.push("}");
  lines.push("");

  const doubleClass = (name, values) => {
    const body = Object.entries(values)
      .map(([key, value]) => `  static const double ${key} = ${number(value)};`)
      .join("\n");
    return `abstract final class ${name} {\n${body}\n}`;
  };

  lines.push(doubleClass("TrSpacing", tokens.spacing));
  lines.push("");
  lines.push(doubleClass("TrRadii", tokens.radii));
  lines.push("");

  const shadowList = (name, shadows) => {
    const entries = shadows
      .map(
        (shadow) =>
          `    BoxShadow(\n      color: ${dartColor(shadow.color)},\n      offset: Offset(${number(shadow.x)}, ${number(shadow.y)}),\n      blurRadius: ${number(shadow.blur)},\n      spreadRadius: ${number(shadow.spread)},\n    ),`,
      )
      .join("\n");
    return `  static const List<BoxShadow> ${name} = <BoxShadow>[\n${entries}\n  ];`;
  };

  const button = tokens.shadows.button;
  lines.push("abstract final class TrShadows {");
  lines.push(shadowList("card", tokens.shadows.card));
  lines.push("");
  lines.push(shadowList("floating", tokens.shadows.floating));
  lines.push("");
  lines.push(shadowList("buttonSubtle", tokens.shadows.buttonSubtle));
  lines.push("");
  lines.push("  static const List<BoxShadow> buttonEmerald = <BoxShadow>[");
  lines.push("    BoxShadow(");
  lines.push(`      color: ${dartColor(button.emeraldFill)},`);
  lines.push(`      offset: Offset(${number(button.x)}, ${number(button.y)}),`);
  lines.push(`      blurRadius: ${number(button.blur)},`);
  lines.push(`      spreadRadius: ${number(button.spread)},`);
  lines.push("    ),");
  lines.push("  ];");
  lines.push("");
  lines.push("  static const List<BoxShadow> buttonDeepGreen = <BoxShadow>[");
  lines.push("    BoxShadow(");
  lines.push(`      color: ${dartColor(button.deepGreenFill)},`);
  lines.push(`      offset: Offset(${number(button.x)}, ${number(button.y)}),`);
  lines.push(`      blurRadius: ${number(button.blur)},`);
  lines.push(`      spreadRadius: ${number(button.spread)},`);
  lines.push("    ),");
  lines.push("  ];");
  lines.push("");
  lines.push("  static const List<BoxShadow> focus = <BoxShadow>[");
  lines.push("    BoxShadow(");
  lines.push("      color: TrColorLight.focus,");
  lines.push(
    `      offset: Offset(${number(tokens.shadows.focus.x)}, ${number(tokens.shadows.focus.y)}),`,
  );
  lines.push(`      blurRadius: ${number(tokens.shadows.focus.blur)},`);
  lines.push(`      spreadRadius: ${number(tokens.shadows.focus.spread)},`);
  lines.push("    ),");
  lines.push("  ];");
  lines.push("}");
  lines.push("");

  lines.push(doubleClass("TrSizing", tokens.sizing));
  lines.push("");

  lines.push("abstract final class TrMotion {");
  lines.push(
    `  static const Duration fast = Duration(milliseconds: ${tokens.motion.fast});`,
  );
  lines.push(
    `  static const Duration normal = Duration(milliseconds: ${tokens.motion.normal});`,
  );
  lines.push(
    `  static const Duration slow = Duration(milliseconds: ${tokens.motion.slow});`,
  );
  lines.push(
    `  static const Duration reduced = Duration(milliseconds: ${tokens.motion.reducedMotionDuration});`,
  );
  lines.push(`  static const double pressScale = ${number(tokens.motion.pressScale)};`);
  lines.push(
    `  static const Curve enterCurve = Curves.${tokens.motion.enterCurve};`,
  );
  lines.push(
    `  static const Curve exitCurve = Curves.${tokens.motion.exitCurve};`,
  );
  lines.push("}");
  lines.push("");

  lines.push(doubleClass("TrBreakpoints", tokens.breakpoints));
  lines.push("");

  return `${lines.join("\n")}\n`;
}

function cssColourDeclarations(tokens) {
  // C0 Workstream B (light-only): only the light theme is emitted.
  // Dark source values in tokens.json are ignored until the lead removes them.
  const light = tokens.color.light;
  const lightBrand = {
    emeraldFill: tokens.brand.emeraldFill.light,
    deepGreenFill: tokens.brand.deepGreenFill.light,
  };

  const baseKeys = [
    "surface",
    "surfaceLowest",
    "surfaceLow",
    "surfaceContainer",
    "surfaceHigh",
    "surfaceHighest",
    "onSurface",
    "onSurfaceVariant",
    "outline",
    "outlineVariant",
    "secondary",
    "onSecondary",
    "secondaryContainer",
    "onSecondaryContainer",
    "error",
    "onError",
    "errorContainer",
    "onErrorContainer",
    "focus",
    "overlay",
    "scrim",
  ];

  const brandDeclarations = (brand) => {
    const lines = [];
    for (const strategy of ["emeraldFill", "deepGreenFill"]) {
      const prefix =
        strategy === "emeraldFill"
          ? "--tr-brand-emerald"
          : "--tr-brand-deep-green";
      const values = brand[strategy];
      lines.push(`  ${prefix}-fill: ${values.fill};`);
      lines.push(`  ${prefix}-on-fill: ${values.onFill};`);
      lines.push(`  ${prefix}-ink: ${values.ink};`);
      lines.push(`  ${prefix}-container: ${values.container};`);
      lines.push(`  ${prefix}-on-container: ${values.onContainer};`);
    }
    lines.push("  --tr-brand-fill: var(--tr-brand-emerald-fill);");
    lines.push("  --tr-on-brand-fill: var(--tr-brand-emerald-on-fill);");
    lines.push("  --tr-brand-ink: var(--tr-brand-emerald-ink);");
    lines.push("  --tr-brand-container: var(--tr-brand-emerald-container);");
    lines.push(
      "  --tr-on-brand-container: var(--tr-brand-emerald-on-container);",
    );
    return lines;
  };

  const statusDeclarations = (status) => {
    const lines = [];
    for (const tone of [
      "neutral",
      "info",
      "success",
      "warning",
      "danger",
      "critical",
    ]) {
      lines.push(`  --tr-${tone}: ${status[tone].foreground};`);
      lines.push(`  --tr-${tone}-bg: ${status[tone].background};`);
    }
    return lines;
  };

  const declarations = (theme, brand, status) => {
    const lines = [];
    for (const key of baseKeys) {
      lines.push(`  --tr-${kebab(key)}: ${theme[key]};`);
    }
    lines.push(...brandDeclarations(brand));
    lines.push(...statusDeclarations(status));
    return lines;
  };

  return {
    light: declarations(light, lightBrand, tokens.status.light),
  };
}

function cssStaticDeclarations(tokens) {
  const lines = [];
  for (const [key, value] of Object.entries(tokens.spacing)) {
    lines.push(`  --tr-space-${kebab(key)}: ${number(value)}px;`);
  }
  lines.push("  --tr-space-colossal: var(--tr-space-massive);");
  lines.push("");
  for (const [key, value] of Object.entries(tokens.radii)) {
    lines.push(`  --tr-radius-${kebab(key)}: ${number(value)}px;`);
  }
  lines.push("");
  lines.push(
    `  --tr-font-latin: "${tokens.fontFamilies.latin}", "${tokens.fontFamilies.cyrillicFallback}", "${tokens.fontFamilies.cjkFallback}", system-ui, sans-serif;`,
  );
  lines.push(
    `  --tr-font-arabic: "${tokens.fontFamilies.arabicDefault}", "${tokens.fontFamilies.arabicAlternative}", "${tokens.fontFamilies.latin}", "${tokens.fontFamilies.cyrillicFallback}", sans-serif;`,
  );
  lines.push(
    `  --tr-font-arabic-alt: "${tokens.fontFamilies.arabicAlternative}", "${tokens.fontFamilies.arabicDefault}", "${tokens.fontFamilies.latin}", "${tokens.fontFamilies.cyrillicFallback}", sans-serif;`,
  );
  lines.push(
    `  --tr-font-cjk: "${tokens.fontFamilies.cjkFallback}", "${tokens.fontFamilies.cyrillicFallback}", system-ui, sans-serif;`,
  );
  lines.push("");
  const shadowValue = (shadows) =>
    shadows
      .map(
        (shadow) =>
          `${number(shadow.x)}px ${number(shadow.y)}px ${number(shadow.blur)}px ${number(shadow.spread)}px ${shadow.color}`,
      )
      .join(", ");
  lines.push(`  --tr-shadow-card: ${shadowValue(tokens.shadows.card)};`);
  lines.push(`  --tr-shadow-floating: ${shadowValue(tokens.shadows.floating)};`);
  lines.push(
    `  --tr-shadow-button-emerald: ${number(tokens.shadows.button.x)}px ${number(tokens.shadows.button.y)}px ${number(tokens.shadows.button.blur)}px ${number(tokens.shadows.button.spread)}px ${tokens.shadows.button.emeraldFill};`,
  );
  lines.push(
    `  --tr-shadow-button-deep-green: ${number(tokens.shadows.button.x)}px ${number(tokens.shadows.button.y)}px ${number(tokens.shadows.button.blur)}px ${number(tokens.shadows.button.spread)}px ${tokens.shadows.button.deepGreenFill};`,
  );
  lines.push("  --tr-shadow-focus: 0 0 0 2px var(--tr-focus);");
  return lines;
}

function cssLegacyAliases(tokens) {
  const lines = [];
  lines.push("  --primary: var(--tr-brand-ink);");
  lines.push("  --secondary: var(--tr-secondary);");
  lines.push("  --surface: var(--tr-surface);");
  lines.push("  --surface-low: var(--tr-surface-low);");
  lines.push("  --surface-card: var(--tr-surface-lowest);");
  lines.push("  --surface-high: var(--tr-surface-high);");
  lines.push("  --on-surface: var(--tr-on-surface);");
  lines.push("  --on-variant: var(--tr-on-surface-variant);");
  lines.push("  --outline: var(--tr-outline);");
  lines.push("  --success: var(--tr-success);");
  lines.push("  --success-bg: var(--tr-success-bg);");
  lines.push("  --warning: var(--tr-warning);");
  lines.push("  --warning-bg: var(--tr-warning-bg);");
  lines.push("  --danger: var(--tr-danger);");
  lines.push("  --danger-bg: var(--tr-danger-bg);");
  lines.push("  --critical: var(--tr-critical);");
  lines.push("  --critical-bg: var(--tr-critical-bg);");
  for (const key of Object.keys(tokens.spacing)) {
    lines.push(`  --spacing-${kebab(key)}: var(--tr-space-${kebab(key)});`);
  }
  for (const key of Object.keys(tokens.radii)) {
    lines.push(`  --radius-${kebab(key)}: var(--tr-radius-${kebab(key)});`);
  }
  lines.push('  --font-body: var(--tr-font-latin);');
  lines.push('  --font-arabic: var(--tr-font-arabic);');
  lines.push('  --font-cjk: var(--tr-font-cjk);');
  return lines;
}

function generateCss(tokens) {
  const colours = cssColourDeclarations(tokens);
  const lines = [];
  lines.push("/* GENERATED FILE - DO NOT EDIT.");
  lines.push(" * Source: client/packages/design_system/tokens/tokens.json");
  lines.push(" * Regenerate: node tools/design_tokens/generate.mjs --write");
  lines.push(" */");
  lines.push("");
  // Light-only (C0 Workstream B): only `:root` is emitted. No
  // `prefers-color-scheme` dark block and no `[data-theme]` alias block.
  lines.push(":root {");
  lines.push("  color-scheme: light;");
  lines.push(...colours.light);
  lines.push("");
  lines.push(...cssStaticDeclarations(tokens));
  lines.push("");
  lines.push(...cssLegacyAliases(tokens));
  lines.push("}");
  lines.push("");
  lines.push('[data-brand-strategy="deepGreen"],');
  lines.push('[data-brand-strategy="deep-green"],');
  lines.push('[data-brand="deep-green"] {');
  lines.push("  --tr-brand-fill: var(--tr-brand-deep-green-fill);");
  lines.push("  --tr-on-brand-fill: var(--tr-brand-deep-green-on-fill);");
  lines.push("  --tr-brand-ink: var(--tr-brand-deep-green-ink);");
  lines.push("  --tr-brand-container: var(--tr-brand-deep-green-container);");
  lines.push(
    "  --tr-on-brand-container: var(--tr-brand-deep-green-on-container);",
  );
  lines.push("}");
  lines.push("");
  lines.push("@media print {");
  lines.push("  :root {");
  lines.push("    color-scheme: light;");
  lines.push(...colours.light.map((line) => `  ${line}`));
  lines.push("  }");
  lines.push("}");
  lines.push("");
  return `${lines.join("\n")}\n`;
}

function writeOrCheck(outputs, check) {
  const stale = [];
  for (const output of outputs) {
    const current = fs.existsSync(output.path)
      ? fs.readFileSync(output.path, "utf8")
      : null;
    if (check) {
      if (current !== output.content) {
        stale.push(output.path);
      }
    } else {
      fs.mkdirSync(path.dirname(output.path), { recursive: true });
      fs.writeFileSync(output.path, output.content, { encoding: "utf8" });
      const bytes = Buffer.byteLength(output.content, "utf8");
      console.log(`wrote ${path.relative(root, output.path)} (${bytes} bytes)`);
    }
  }
  if (check) {
    if (stale.length > 0) {
      for (const file of stale) {
        console.error(`stale: ${path.relative(root, file)}`);
      }
      console.error(
        "Run `node tools/design_tokens/generate.mjs --write` to regenerate.",
      );
      process.exitCode = 1;
    } else {
      console.log("design tokens are up to date");
    }
  }
}

function main() {
  const args = new Set(process.argv.slice(2));
  if (args.has("--help") || args.has("-h")) {
    console.log("Usage: node tools/design_tokens/generate.mjs [--write|--check]");
    return;
  }
  const check = args.has("--check");
  const tokens = readTokens();
  const dart = generateDart(tokens);
  const css = generateCss(tokens);
  const contrast = generateContrastMarkdown(tokens).markdown;
  writeOrCheck(
    [
      { path: paths.dart, content: dart },
      { path: paths.css, content: css },
      { path: paths.contrast, content: contrast },
    ],
    check,
  );
}

main();
