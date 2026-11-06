function hexToRgba(hex) {
  const value = hex.replace("#", "").toUpperCase();
  if (value.length !== 6 && value.length !== 8) {
    throw new Error(`Unsupported hex colour: ${hex}`);
  }
  const rgb = value.slice(0, 6);
  const alpha = value.length === 8 ? Number.parseInt(value.slice(6, 8), 16) / 255 : 1;
  return {
    hex: `#${value}`,
    r: Number.parseInt(rgb.slice(0, 2), 16),
    g: Number.parseInt(rgb.slice(2, 4), 16),
    b: Number.parseInt(rgb.slice(4, 6), 16),
    a: alpha,
  };
}

function linearChannel(channel) {
  const value = channel / 255;
  return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
}

function luminance(colour) {
  return (
    0.2126 * linearChannel(colour.r) +
    0.7152 * linearChannel(colour.g) +
    0.0722 * linearChannel(colour.b)
  );
}

function composite(foreground, background) {
  if (foreground.a >= 1) {
    return foreground;
  }
  return {
    hex: foreground.hex,
    r: Math.round(foreground.a * foreground.r + (1 - foreground.a) * background.r),
    g: Math.round(foreground.a * foreground.g + (1 - foreground.a) * background.g),
    b: Math.round(foreground.a * foreground.b + (1 - foreground.a) * background.b),
    a: 1,
  };
}

function contrastRatio(foregroundHex, backgroundHex) {
  const background = hexToRgba(backgroundHex);
  const foreground = composite(hexToRgba(foregroundHex), background);
  const foregroundLuminance = luminance(foreground);
  const backgroundLuminance = luminance(background);
  const lighter = Math.max(foregroundLuminance, backgroundLuminance);
  const darker = Math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

function formatRatio(value) {
  return value.toFixed(2);
}

function escapeCell(value) {
  return String(value).replaceAll("|", "\\|").replaceAll("\n", " ");
}

function surfaceRows(theme) {
  return [
    ["surface", theme.surface],
    ["surfaceLowest", theme.surfaceLowest],
    ["surfaceLow", theme.surfaceLow],
    ["surfaceContainer", theme.surfaceContainer],
    ["surfaceHigh", theme.surfaceHigh],
    ["surfaceHighest", theme.surfaceHighest],
  ];
}

function toneSeverity(tone) {
  switch (tone) {
    case "neutral":
      return "minor";
    case "warning":
      return "moderate";
    case "danger":
      return "major";
    case "critical":
      return "safetyCritical";
    default:
      return "not used";
  }
}

export function buildContrastRows(tokens) {
  const rows = [];
  const add = (row) => {
    const ratio = contrastRatio(row.fg, row.bg);
    rows.push({
      ...row,
      ratio,
      result: ratio >= row.threshold ? "PASS" : "FAIL",
    });
  };

  for (const themeName of ["light"]) {
    const theme = tokens.color[themeName];
    const surfaces = surfaceRows(theme);

    for (const [surfaceName, surfaceHex] of surfaces) {
      add({
        section: `Base text / UI — ${themeName}`,
        group: `base-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Body text",
        fgName: "onSurface",
        fg: theme.onSurface,
        bgName: surfaceName,
        bg: surfaceHex,
        threshold: 4.5,
        usage: `Normal text on ${surfaceName}.`,
      });
      add({
        section: `Base text / UI — ${themeName}`,
        group: `base-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Muted / placeholder text",
        fgName: "onSurfaceVariant",
        fg: theme.onSurfaceVariant,
        bgName: surfaceName,
        bg: surfaceHex,
        threshold: 4.5,
        usage: `Secondary text and input placeholder on ${surfaceName}.`,
      });
      add({
        section: `Base text / UI — ${themeName}`,
        group: `base-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Border / outline",
        fgName: "outline",
        fg: theme.outline,
        bgName: surfaceName,
        bg: surfaceHex,
        threshold: 3,
        usage: `UI boundary on ${surfaceName}; not normal text.`,
      });
    }

    for (const surfaceName of ["surface", "surfaceLowest", "surfaceContainer"]) {
      add({
        section: `Base text / UI — ${themeName}`,
        group: `base-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Secondary accent text",
        fgName: "secondary",
        fg: theme.secondary,
        bgName: surfaceName,
        bg: theme[surfaceName],
        threshold: 4.5,
        usage: `Links and secondary labels on ${surfaceName}.`,
      });
      add({
        section: `Base text / UI — ${themeName}`,
        group: `base-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Error text",
        fgName: "error",
        fg: theme.error,
        bgName: surfaceName,
        bg: theme[surfaceName],
        threshold: 4.5,
        usage: `Error text on ${surfaceName}.`,
      });
    }

    add({
      section: `Base text / UI — ${themeName}`,
      group: `base-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Error label",
      fgName: "onError",
      fg: theme.onError,
      bgName: "error",
      bg: theme.error,
      threshold: 4.5,
      usage: "Text/icon on an error fill.",
    });
    add({
      section: `Base text / UI — ${themeName}`,
      group: `base-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Error container text",
      fgName: "onErrorContainer",
      fg: theme.onErrorContainer,
      bgName: "errorContainer",
      bg: theme.errorContainer,
      threshold: 4.5,
      usage: "Text/icon on an error container.",
    });
    add({
      section: `Base text / UI — ${themeName}`,
      group: `base-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Secondary label",
      fgName: "onSecondary",
      fg: theme.onSecondary,
      bgName: "secondary",
      bg: theme.secondary,
      threshold: 4.5,
      usage: "Text/icon on a secondary fill.",
    });
    add({
      section: `Base text / UI — ${themeName}`,
      group: `base-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Secondary container text",
      fgName: "onSecondaryContainer",
      fg: theme.onSecondaryContainer,
      bgName: "secondaryContainer",
      bg: theme.secondaryContainer,
      threshold: 4.5,
      usage: "Text/icon on a secondary container.",
    });
    add({
      section: `Base text / UI — ${themeName}`,
      group: `base-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Inverse text",
      fgName: "onInverseSurface",
      fg: theme.onInverseSurface,
      bgName: "inverseSurface",
      bg: theme.inverseSurface,
      threshold: 4.5,
      usage: "Snackbar/inverse surface text.",
    });
  }

  for (const themeName of ["light"]) {
    const surfaces = surfaceRows(tokens.color[themeName]);
    for (const strategy of ["emeraldFill", "deepGreenFill"]) {
      const brand = tokens.brand[strategy][themeName];
      add({
        section: "A2 brand strategies",
        group: "brand",
        theme: themeName,
        strategy,
        role: "Brand fill label",
        fgName: `${strategy}.onFill`,
        fg: brand.onFill,
        bgName: `${strategy}.fill`,
        bg: brand.fill,
        threshold: 4.5,
        usage: `Normal text/icon on the ${strategy} brand fill.`,
      });
      add({
        section: "A2 brand strategies",
        group: "brand",
        theme: themeName,
        strategy,
        role: "Brand container text",
        fgName: `${strategy}.onContainer`,
        fg: brand.onContainer,
        bgName: `${strategy}.container`,
        bg: brand.container,
        threshold: 4.5,
        usage: `Normal text/icon on the ${strategy} brand container.`,
      });
      for (const [surfaceName, surfaceHex] of surfaces) {
        add({
          section: "A2 brand strategies",
          group: "brand",
          theme: themeName,
          strategy,
          role: "Brand ink text/icon",
          fgName: `${strategy}.ink`,
          fg: brand.ink,
          bgName: surfaceName,
          bg: surfaceHex,
          threshold: 4.5,
          usage: `Brand text/icon on ${surfaceName}.`,
        });
      }
      for (const surfaceName of ["surface", "surfaceLowest"]) {
        add({
          section: "A2 brand strategies",
          group: "brand",
          theme: themeName,
          strategy,
          role: "Brand fill boundary",
          fgName: `${strategy}.fill`,
          fg: brand.fill,
          bgName: surfaceName,
          bg: tokens.color[themeName][surfaceName],
          threshold: 3,
          usage:
            strategy === "emeraldFill" && themeName === "light"
              ? "Approved emerald fill against a light surface. Not a text/icon token; do not rely on fill alone to identify a control."
              : `Brand fill boundary against ${surfaceName}.`,
          exception:
            strategy === "emeraldFill" && themeName === "light"
              ? "Approved A2 fill; the button carries a 6.78:1 ink label and a non-colour label. Never use this fill as text/icon."
              : "",
        });
      }
    }
  }

  for (const themeName of ["light"]) {
    for (const tone of ["neutral", "info", "success", "warning", "danger", "critical"]) {
      const pair = tokens.status[themeName][tone];
      add({
        section: `Status and severity — ${themeName}`,
        group: `status-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: `Status ${tone}`,
        fgName: `${tone}.foreground`,
        fg: pair.foreground,
        bgName: `${tone}.background`,
        bg: pair.background,
        threshold: 4.5,
        usage:
          toneSeverity(tone) === "not used"
            ? `Status chip text on ${tone} background.`
            : `Status chip text on ${tone} background; severity ${toneSeverity(tone)} uses this pair.`,
      });
    }
  }

  for (const themeName of ["light"]) {
    const theme = tokens.color[themeName];
    for (const [surfaceName, surfaceHex] of surfaceRows(theme)) {
      add({
        section: `Focus and borders — ${themeName}`,
        group: `ui-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Focus ring",
        fgName: "focus",
        fg: theme.focus,
        bgName: surfaceName,
        bg: surfaceHex,
        threshold: 3,
        usage: `Focus indicator on ${surfaceName}.`,
      });
      add({
        section: `Focus and borders — ${themeName}`,
        group: `ui-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: "Divider / decorative outline",
        fgName: "outlineVariant",
        fg: theme.outlineVariant,
        bgName: surfaceName,
        bg: surfaceHex,
        threshold: 3,
        usage: `Decorative divider or non-essential outline on ${surfaceName}.`,
        exception:
          "Decorative only; not a sole component boundary. Use outline for boundaries that must be perceivable.",
      });
    }
  }

  for (const themeName of ["light"]) {
    const theme = tokens.color[themeName];
    const brand = tokens.brand.emeraldFill[themeName];
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report body",
      fgName: "--on-surface",
      fg: theme.onSurface,
      bgName: "--surface",
      bg: theme.surface,
      threshold: 4.5,
      usage: "report.css body text and headings.",
    });
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report muted text",
      fgName: "--on-variant",
      fg: theme.onSurfaceVariant,
      bgName: "--surface",
      bg: theme.surface,
      threshold: 4.5,
      usage: "report.css muted, metadata, footer and table heading text.",
    });
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report primary text",
      fgName: "--primary",
      fg: brand.ink,
      bgName: "--surface-card",
      bg: theme.surfaceLowest,
      threshold: 4.5,
      usage: "report.css .stat and primary text on a card.",
    });
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report link",
      fgName: "--secondary",
      fg: theme.secondary,
      bgName: "--surface",
      bg: theme.surface,
      threshold: 4.5,
      usage: "report.css links.",
    });
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report primary button",
      fgName: "--surface-card",
      fg: theme.surfaceLowest,
      bgName: "--primary",
      bg: brand.ink,
      threshold: 4.5,
      usage: "report.css .button.primary label on the legacy primary fill.",
    });
    for (const tone of ["success", "warning", "danger", "critical"]) {
      const pair = tokens.status[themeName][tone];
      add({
        section: `Public report — ${themeName}`,
        group: `public-${themeName}`,
        theme: themeName,
        strategy: "—",
        role: `Report ${tone} badge`,
        fgName: `--${tone}`,
        fg: pair.foreground,
        bgName: `--${tone}-bg`,
        bg: pair.background,
        threshold: 4.5,
        usage: `report.css .badge.${tone}.`,
      });
    }
    add({
      section: `Public report — ${themeName}`,
      group: `public-${themeName}`,
      theme: themeName,
      strategy: "—",
      role: "Report neutral badge",
      fgName: "--on-variant",
      fg: theme.onSurfaceVariant,
      bgName: "--surface-high",
      bg: theme.surfaceHigh,
      threshold: 4.5,
      usage: "report.css .badge default.",
    });
  }

  for (const themeName of ["light"]) {
    const theme = tokens.color[themeName];
    const brand = tokens.brand.emeraldFill[themeName];
    const section = `F2-A technician screens - ${themeName}`;
    const group = `f2a-${themeName}`;
    const f2a = [
      ["Body text", "onSurface", theme.onSurface, "surface", theme.surface, 4.5, "F2-A screen body text.", ""],
      ["Muted text", "onSurfaceVariant", theme.onSurfaceVariant, "surface", theme.surface, 4.5, "F2-A labels and secondary text.", ""],
      ["Muted text on field fill", "onSurfaceVariant", theme.onSurfaceVariant, "surfaceContainer", theme.surfaceContainer, 4.5, "F2-A field labels/hints on the filled input.", ""],
      ["Muted text on nav surface", "onSurfaceVariant", theme.onSurfaceVariant, "surfaceLowest", theme.surfaceLowest, 4.5, "F2-A dock unselected label.", ""],
      ["Brand ink text/icon", "emeraldFill.ink", brand.ink, "surface", theme.surface, 4.5, "F2-A icons and links on white.", ""],
      ["Brand container text", "emeraldFill.onContainer", brand.onContainer, "emeraldFill.container", brand.container, 4.5, "F2-A selected chip and icon tile label.", ""],
      ["Primary small label", "emeraldFill.onFill", brand.onFill, "emeraldFill.fill", brand.fill, 4.5, "P1 option 3: smaller emerald buttons use the ink label.", ""],
      ["Primary large label", "onPrimaryLarge", theme.onPrimaryLarge, "primaryLarge", theme.primaryLarge, 3, "P1 option 2: 19 px bold large CTA label.", "Owner-approved large-text pair (3.77:1 light) with a 19 px bold label."],
      ["Primary large fill boundary", "primaryLarge", theme.primaryLarge, "surface", theme.surface, 3, "P1 option 2 button boundary on the page.", ""],
      ["Field fill boundary", "surfaceContainer", theme.surfaceContainer, "surface", theme.surface, 3, "Borderless filled field boundary.", "Accepted accessibility risk P2: visible label above and F1 focus ring carry the affordance."],
      ["Focus ring", "focus", theme.focus, "surface", theme.surface, 3, "F2-A focus ring around fields and actions.", ""],
      ["Error text", "error", theme.error, "surface", theme.surface, 4.5, "F2-A validation text.", ""],
      ["Neutral status", "status.neutral.fg", tokens.status[themeName].neutral.foreground, "status.neutral.bg", tokens.status[themeName].neutral.background, 4.5, "F2-A status/result chip.", ""],
      ["Info status", "status.info.fg", tokens.status[themeName].info.foreground, "status.info.bg", tokens.status[themeName].info.background, 4.5, "F2-A in-progress status chip.", ""],
      ["Success status", "status.success.fg", tokens.status[themeName].success.foreground, "status.success.bg", tokens.status[themeName].success.background, 4.5, "F2-A no-issue-observed count chip.", ""],
      ["Warning status", "status.warning.fg", tokens.status[themeName].warning.foreground, "status.warning.bg", tokens.status[themeName].warning.background, 4.5, "F2-A attention count chip.", ""],
      ["Danger status", "status.danger.fg", tokens.status[themeName].danger.foreground, "status.danger.bg", tokens.status[themeName].danger.background, 4.5, "F2-A defect count chip.", ""],
      ["Critical status", "status.critical.fg", tokens.status[themeName].critical.foreground, "status.critical.bg", tokens.status[themeName].critical.background, 4.5, "F2-A critical severity chip.", ""],
    ];
    for (const [role, fgName, fg, bgName, bg, threshold, usage, exception] of f2a) {
      add({ section, group, theme: themeName, strategy: "-", role, fgName, fg, bgName, bg, threshold, usage, exception });
    }
  }

  return rows;
}

function table(rows) {
  const header = [
    "| Role | Foreground token | Hex | Background token | Hex | Ratio | AA threshold | Result | Usage / exception |",
    "|---|---|---|---|---:|---:|---:|---|---|",
  ];
  const body = rows.map((row) => {
    const usage = row.exception
      ? `${row.usage} EXCEPTION: ${row.exception}`
      : row.usage;
    return `| ${escapeCell(row.role)} | ${escapeCell(row.fgName)} | ${row.fg} | ${escapeCell(row.bgName)} | ${row.bg} | ${formatRatio(row.ratio)}:1 | ${row.threshold.toFixed(1)}:1 | ${row.result} | ${escapeCell(usage)} |`;
  });
  return [...header, ...body].join("\n");
}

function sectionSummary(rows, group) {
  const selected = rows.filter((row) => row.group === group);
  const pass = selected.filter((row) => row.result === "PASS").length;
  return {
    total: selected.length,
    pass,
    fail: selected.length - pass,
  };
}

export function generateContrastMarkdown(tokens) {
  const rows = buildContrastRows(tokens);
  const totalPass = rows.filter((row) => row.result === "PASS").length;
  const totalFail = rows.length - totalPass;
  // C0 Workstream B (light-only): dark groups removed.
  const groups = [
    ["Base text / UI — light", "base-light"],
    ["A2 brand strategies", "brand"],
    ["Status and severity — light", "status-light"],
    ["Focus and borders — light", "ui-light"],
    ["Public report — light", "public-light"],
    ["F2-A technician screens - light", "f2a-light"],
  ];
  const summaryRows = groups.map(([label, group]) => {
    const summary = sectionSummary(rows, group);
    return `| ${label} | ${summary.total} | ${summary.pass} | ${summary.fail} |`;
  });

  const prohibited = [
    ["#10B981", "surface", tokens.color.light.surface],
    ["#10B981", "surfaceLowest", tokens.color.light.surfaceLowest],
    ["#10B981", "surfaceContainer", tokens.color.light.surfaceContainer],
    ["#10B981", "surfaceHighest", tokens.color.light.surfaceHighest],
  ].map(([fg, bgName, bg]) => {
    const ratio = contrastRatio(fg, bg);
    return `| ${fg} | ${bgName} | ${bg} | ${formatRatio(ratio)}:1 | 4.5:1 | FAIL | Prohibited text/icon use. Emitted only as the emerald brand fill. |`;
  });

  const lines = [];
  lines.push("# F1 token contrast audit (measured, light-only)");
  lines.push("");
  lines.push("- **Status:** generated from `client/packages/design_system/tokens/tokens.json` (light theme only; C0 Workstream B removed the dark theme).");
  lines.push("- **Date:** 6 November 2026.");
  lines.push("- **Method:** WCAG 2.x relative luminance in sRGB, measured by `tools/design_tokens/contrast.mjs`; no value is inferred from a design tool.");
  lines.push("- **Thresholds:** normal text `4.5:1`, large text `3:1`, UI components and graphics `3:1`.");
  lines.push("- **Reproduce:** `node tools/design_tokens/generate.mjs --write` then read this file; `node tools/design_tokens/generate.mjs --check` verifies all generated outputs are current.");
  lines.push("");
  lines.push("## Summary");
  lines.push("");
  lines.push("| Section | Pairs | Pass | Fail |");
  lines.push("|---|---:|---:|---:|");
  lines.push(...summaryRows);
  lines.push(`| **Total audited token pairs** | **${rows.length}** | **${totalPass}** | **${totalFail}** |`);
  lines.push("");
  lines.push(`**Result: ${totalPass} pass, ${totalFail} fail.** Every failing pair is listed below with its usage or exception.`);
  lines.push("");
  lines.push("The four prohibited raw `#10B981` text/icon pairs are listed separately at the end and are **not** counted as token pairs because the generator never emits `#10B981` as a text or icon token.");
  lines.push("");
  lines.push("## Notes on scope");
  lines.push("");
  lines.push("- `overlay` and `scrim` are translucent layers, not text backgrounds; no text/background pair is defined on them in the contract, so no pair is claimed.");
  lines.push("- Shadow colours are decorative and are not text or UI boundaries; they are not contrast pairs.");
  lines.push("- `disabled` has no dedicated colour token in `f1-token-api.md`; no disabled pair is claimed. `onSurfaceVariant` is audited above as the placeholder/hint token.");
  lines.push("- Large-text rows use the same measured ratio; a `3:1` allowance would only be applied by the consuming component, never by lowering a normal-text row.");
  lines.push("- **F1.1 usage:** the 12 `outlineVariant` divider pairs are no longer used as the sole boundary of an interactive control; decorative dividers were removed or reverted to the Figma `#F4F3F8` separator. They remain token pairs only.");
  lines.push("- **F1.1 primary button:** the two emerald fill-boundary failures are the Figma fill vs a light surface. The product default carries a 6.78:1 ink label; option 1 (white) is 2.54:1 and is still an open owner decision. See the primary-button section below.");
  lines.push("");

  for (const [label, group] of groups) {
    lines.push(`## ${label}`);
    lines.push("");
    lines.push(table(rows.filter((row) => row.group === group)));
    lines.push("");
  }

  lines.push("## Primary button options (A2 re-opened, measured)");
  lines.push("");
  lines.push("Measured from the four fills the owner asked to see on the Figma primary button. WCAG large text is >= 18.66 px bold (14 pt) or >= 24 px regular; the threshold is 3:1 for large text and 4.5:1 for normal text.");
  lines.push("");
  lines.push("| Option | Fill | Label | Measured ratio | Normal 4.5:1 | Large 3:1 | Size needed to count as large |");
  lines.push("|---|---|---|---:|---|---|---|");
  const buttonOptions = [
    ["1. Figma exact", "#10B981", "#FFFFFF", "14/18 w700"],
    ["2. Figma pressed green", "#059669", "#FFFFFF", "19/18 w800 (large)"],
    ["3. Ink label (product default)", "#10B981", "#1A1B1F", "14/18 w700"],
    ["4. Deep green", "#006C49", "#FFFFFF", "14/18 w700"],
  ];
  for (const [name, fill, label, current] of buttonOptions) {
    const ratio = contrastRatio(label, fill);
    const normal = ratio >= 4.5 ? "PASS" : "FAIL";
    const large = ratio >= 3 ? "PASS" : "FAIL";
    const needed = ratio >= 4.5
      ? "Any size"
      : ratio >= 3
        ? ">= 18.66 px bold or >= 24 px regular (current: " + current + ")"
        : "Cannot reach 3:1 at any size";
    lines.push(`| ${name} | ${fill} | ${label} | ${formatRatio(ratio)}:1 | ${normal} | ${large} | ${needed} |`);
  }
  lines.push("");
  lines.push("Option 1 is the Figma-exact variant used only by the gallery and the fidelity harness. The product default remains option 3 until the owner chooses; option 2 is only acceptable as large text.");
  lines.push("");
  lines.push("## Prohibited raw emerald text/icon pairs (not counted)");
  lines.push("");
  lines.push("These pairs are measured to document why `#10B981` is fill-only. They are not emitted as text or icon tokens.");
  lines.push("");
  lines.push("| Foreground | Background token | Background hex | Ratio | AA threshold | Result | Decision |");
  lines.push("|---|---|---|---:|---:|---|---|");
  lines.push(...prohibited);
  lines.push("");
  // C0 Workstream B (light-only): dark ratios removed.
  lines.push("## Severity mapping check (light-only)");
  lines.push("");
  lines.push("| Severity | Tone | Measured pair | Light ratio | Result |");
  lines.push("|---|---|---|---:|---|");
  for (const severity of tokens.severity) {
    const light = tokens.status.light[severity.tone];
    const lightRatio = contrastRatio(light.foreground, light.background);
    const result = lightRatio >= 4.5 ? "PASS" : "FAIL";
    lines.push(`| ${severity.name} | ${severity.tone} | ${severity.tone}.foreground on ${severity.tone}.background | ${formatRatio(lightRatio)}:1 | ${result} |`);
  }
  lines.push("");
  lines.push("## Inspection-result mapping check");
  lines.push("");
  lines.push("`InspectionResult` reuses the status tones above; it adds no colours, so its contrast is the measured status pair for its tone.");
  lines.push("");
  lines.push("| Result | Tone | Icon |");
  lines.push("|---|---|---|");
  for (const item of tokens.inspectionResult) {
    lines.push(`| ${item.name} | ${item.tone} | ${item.icon} |`);
  }
  lines.push("");
  lines.push("## Reproduce");
  lines.push("");
  lines.push("```powershell");
  lines.push("node tools/design_tokens/generate.mjs --write");
  lines.push("node tools/design_tokens/generate.mjs --check");
  lines.push("```");
  lines.push("");
  lines.push("The generator reads `client/packages/design_system/tokens/tokens.json` and writes `tokens.g.dart`, `tokens.g.css` and this report. It exits non-zero on stale output when `--check` is used.");
  lines.push("");

  return {
    markdown: lines.join("\n"),
    rows,
    totalPass,
    totalFail,
  };
}

export { contrastRatio };
