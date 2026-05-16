---
description: ARTIST MODE ACTIVATED
---

# ARTIST MODE ACTIVATED

You are now operating in **artist mode**. Every pixel justifies its existence. Spatial awareness is paramount. These are binding rules, not suggestions.

This unified skill covers matplotlib, TikZ, seaborn, and SVG workflows for publication-quality scientific figures.

---

## 1. THE RENDER-CHECK-FIX LOOP (MANDATORY)

**This is the most important section.** Claude's visual acuity is limited — you cannot reliably validate a figure by glancing at a full-page thumbnail. The only way to produce correct figures is a disciplined iteration loop.

### The Problem

Claude sees rasterized images at limited resolution. Text overlap, spacing violations, and font-size drift are frequently missed because:
- Small text (6pt) is near the edge of what Claude can resolve
- Full-figure views compress details into too few pixels
- A single glance cannot catch collisions that are obvious to a human at 400% zoom

**Acknowledging this limitation is not optional. Compensate for it procedurally.**

### The Mandatory Loop

Every figure MUST go through this cycle. Do NOT skip steps. Do NOT declare a figure "done" after one render.

```
1. RENDER  →  Generate the figure at final DPI (300+) and target physical dimensions
2. VIEW    →  Read the output image with the Read tool
3. MEASURE →  Run programmatic overlap detection (Section 4, Strategy 6)
4. CROP    →  View dense regions individually (axis labels, legends, colorbars)
5. FIX     →  Apply corrections in code
6. REPEAT  →  Go back to step 1. Minimum 2 full cycles.
```

### Programmatic Validation (Non-Negotiable)

Do NOT rely solely on visual inspection. Run this after every render:

```python
def validate_figure(fig):
    """Programmatic checks that catch what the eye misses."""
    renderer = fig.canvas.get_renderer()
    issues = []

    # Collect ALL text elements from all axes
    all_texts = list(fig.texts)
    for ax in fig.get_axes():
        all_texts.extend(ax.texts)
        all_texts.append(ax.title)
        all_texts.append(ax.xaxis.label)
        all_texts.append(ax.yaxis.label)
        all_texts.extend(ax.get_xticklabels())
        all_texts.extend(ax.get_yticklabels())

    # Filter to visible text
    all_texts = [t for t in all_texts if t.get_text().strip()]

    # Check 1: Overlap detection
    bboxes = []
    for t in all_texts:
        try:
            bb = t.get_window_extent(renderer=renderer)
            if bb.width > 0 and bb.height > 0:
                bboxes.append((t, bb))
        except Exception:
            pass

    for i, (t1, bb1) in enumerate(bboxes):
        for t2, bb2 in bboxes[i+1:]:
            if bb1.overlaps(bb2):
                issues.append(f"OVERLAP: '{t1.get_text()}' x '{t2.get_text()}'")

    # Check 2: Font size verification
    for t in all_texts:
        size = t.get_fontsize()
        if size > 6.5:
            issues.append(f"FONT SIZE {size}pt on '{t.get_text()[:20]}' (must be ≤6pt)")

    # Check 3: Bold where it shouldn't be
    for t in all_texts:
        weight = t.get_fontproperties().get_weight()
        if weight in ('bold', 'heavy', 700, 800, 900):
            text = t.get_text().strip()
            if len(text) > 1 or not text.isalpha():
                issues.append(f"UNEXPECTED BOLD on '{text[:20]}' (only panel labels may be bold)")

    if issues:
        print(f"VALIDATION FAILED — {len(issues)} issue(s):")
        for issue in issues:
            print(f"  ✗ {issue}")
    else:
        print("VALIDATION PASSED — no overlap, font, or weight issues detected")

    return issues
```

### Render-at-Target-Size Rule

A figure that looks fine at screen resolution may have obvious problems at print size. Always render at the actual target:

```python
# WRONG: default low-res render
fig.savefig('test.png', dpi=100)

# RIGHT: render at journal target size and DPI
fig.savefig('test_check.png', dpi=300, bbox_inches='tight')
```

### When to Stop Iterating

- `validate_figure()` returns zero issues, AND
- You have visually inspected the rendered output at least twice, AND
- You have viewed at least one cropped dense region (axis labels, legend, etc.)

If you have not completed all three, you are not done.

---

## 2. UNIVERSAL DESIGN LAWS

### Spatial Hierarchy
- Padding MUST decrease inward: outer margin > panel gap > label pad > tick pad
- **Aligned layouts** (heatmap + dendrogram sharing axes): `hspace/wspace = 0.02`
- **Heterogeneous multi-panel composites** (independent axes with their own labels, colorbars): use **SubFigures + `layout='constrained'`** (preferred) or nested GridSpec with `hspace=0.30–0.40`
- Label pad: `1pt`, Tick pad: `1pt`
- NEVER use flat `hspace/wspace=0.02` on multi-panel figures with independent axes

### Anti-Overlap Mandate
- **NO text may touch any other element** — not other text, not axes, not data points, not borders, not colorbars
- Minimum clearance: 1pt between any text element and any other figure element

### Breathing Room

| Element pair | Minimum clearance |
|---|---|
| Text to text | 1pt |
| Text to axis line | 1pt (via labelpad/tickpad) |
| Text to data (bars, points) | 2pt |
| Panel to panel (aligned layout) | 0.02 in figure fraction |
| Panel to panel (heterogeneous) | 0.30–0.40 hspace via SubFigures or nested GridSpec |
| Colorbar to heatmap | 0.008 width fraction gap |

### Data-to-Ink Ratio
- Target: >70% of figure area showing data
- Remove all chart junk: unnecessary gridlines, borders, backgrounds, legends that duplicate axis info

### Visual Weight Balance
- Distribute visual density evenly across the figure
- Colorbars should be compact and context-appropriate, never dominant

---

## 3. TYPOGRAPHY LAW

**ALL text: 6pt Arial. No exceptions.**

Enforced by `apply_tara_style()`. If writing a standalone script without the module, set all rcParams manually (see Section 11).

### Font Embedding (critical for Illustrator compatibility)
```python
mpl.rcParams['pdf.fonttype'] = 42      # TrueType in PDF
mpl.rcParams['ps.fonttype'] = 42       # TrueType in PostScript
mpl.rcParams['svg.fonttype'] = 'none'  # Embed fonts in SVG
```

### TikZ Typography
- Use `\fontsize{6}{7.2}\selectfont\sffamily` for all node text
- Document preamble: `\usepackage[scaled=0.9]{helvet}` with `\renewcommand*\familydefault{\sfdefault}`

### Panel Labels and Titles
- **Panel labels** (`A`, `B`, `C`, …) are the ONLY bold text — 6pt bold Arial
- **NO panel titles** — titles belong in the figure caption, not on the panel
- Remove all `ax.set_title()` calls
- Position: `ax.text(-0.12, 1.08, letter, transform=ax.transAxes, fontsize=6, fontweight='bold', va='top', ha='left')`

### Text Content Rules
- **NO unicode subscripts** — write `Log2` not `Log₂`, write `CO2` not `CO₂`
- Abbreviate aggressively: `"2119"` instead of `"PF02119"`
- Sparse labeling: every Nth item when >20 items on an axis
- **NO `fontweight='bold'`** anywhere except panel labels

---

## 4. ANTI-OVERLAP PROTOCOL

Apply these strategies in order of preference:

### Strategy 1: Rotation
- Rotate x-axis labels 45° when >6 labels
- `ha='right', rotation_mode='anchor'`

### Strategy 2: Sparse Labeling
- When >20 items: label every Nth item
- `ax.set_xticks(ticks[::N])`

### Strategy 3: Abbreviation
- Strip common prefixes: `"PF02119"` → `"2119"`
- Truncate long names to 15 chars + `…`
- Use taxa as colored bars instead of text labels

### Strategy 4: adjustText Library
```python
from adjustText import adjust_text
texts = [ax.text(x, y, label, fontsize=6) for x, y, label in zip(xs, ys, labels)]
adjust_text(texts, arrowprops=dict(arrowstyle='-', color='gray', lw=0.25))
```

### Strategy 5: Explicit Padding
Already handled by `apply_tara_style()`. Manual override when needed:
```python
mpl.rcParams['axes.labelpad'] = 1
mpl.rcParams['xtick.major.pad'] = 1
mpl.rcParams['ytick.major.pad'] = 1
```

### Strategy 6: Post-Generation Overlap Detection
Use `validate_figure()` from Section 1. For lightweight checks during development:
```python
renderer = fig.canvas.get_renderer()
for i, t1 in enumerate(fig.texts):
    bb1 = t1.get_window_extent(renderer=renderer)
    for t2 in fig.texts[i+1:]:
        bb2 = t2.get_window_extent(renderer=renderer)
        if bb1.overlaps(bb2):
            print(f"OVERLAP: '{t1.get_text()}' and '{t2.get_text()}'")
```

---

## 5. COLOR SYSTEMS

**All figures must use the unified palette from `figures/palette.py`.**

```python
from palette import (
    get_sequential_cmap, get_diverging_cmap, get_categorical_colors,
    BASIN_COLORS, LINEAGE_COLORS, ENV_CATEGORY_COLORS,
    OCEAN_CMAP, FOREST_CMAP, THERMAL_CMAP, DIVERGING_CMAP
)
```

### Colormap Selection Rules

| Data Type | Colormap | Function |
|-----------|----------|----------|
| Abundance/Counts | `OCEAN_CMAP` | `get_sequential_cmap('ocean')` |
| R²/Performance | `OCEAN_CMAP` | Sequential, NOT diverging |
| Chlorophyll/Productivity | `FOREST_CMAP` | `get_sequential_cmap('forest')` |
| Temperature | `THERMAL_CMAP` | `get_sequential_cmap('thermal')` |
| Correlations (-1 to +1) | `DIVERGING_CMAP` | `get_diverging_cmap()` |
| Residuals/Z-scores | `DIVERGING_CMAP` | Centered at zero |
| Basins | `BASIN_COLORS` | Dict lookup |
| Lineages | `LINEAGE_COLORS` | Dict lookup |
| Modules/Clusters | `get_categorical_colors(n)` | 10-color Earth palette |

### Color Rules
- **White = missing/NaN** — always, in every context
- Colorblind-safe: all project palettes pass deuteranopia simulation
- Grayscale-distinguishable: patterns must survive B&W conversion
- **NEVER use**: rainbow/jet, default matplotlib colors (tab10), diverging maps for non-diverging data

### Fallback Blackbody Palette (when palette.py is unavailable)
```python
blackbody_colors = [
    (1.0, 1.0, 1.0), (0.95, 0.95, 0.95), (0.1, 0.1, 0.1),
    (0.4, 0.0, 0.0), (0.7, 0.0, 0.0), (0.9, 0.2, 0.0),
    (1.0, 0.5, 0.0), (1.0, 0.7, 0.0), (1.0, 0.9, 0.2),
]
```

### Fallback Diverging Palette (when palette.py is unavailable)
```python
diverging_colors = [
    (0.0, 0.3, 0.7), (0.3, 0.5, 0.9), (0.7, 0.8, 0.95),
    (0.95, 0.95, 0.95),
    (0.95, 0.8, 0.7), (0.9, 0.4, 0.3), (0.7, 0.1, 0.1),
]
```

### Fallback Colorblind Palettes (non-project contexts)
```python
OKABE_ITO = ['#E69F00', '#56B4E9', '#009E73', '#F0E442',
             '#0072B2', '#D55E00', '#CC79A7', '#000000']
```

---

## 6. STYLE INFRASTRUCTURE

### Apply Style (top of every script)

```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from tara_style import apply_tara_style, check_figure_size, save_figure
apply_tara_style()
```

### The `tara_style` module (`figures/tara_style.py`)

If this file does not exist, create it. It provides three functions:

- **`apply_tara_style(target='cell')`** — Applies full rcParams (6pt Arial, 0.25pt lines, minimal padding, TrueType embedding, transparent export defaults)
- **`check_figure_size(fig, journal='cell', width='double')`** — Validates dimensions against journal specs. Prints PASS/FAIL.
- **`save_figure(fig, name, output_dir='figures')`** — Saves PDF + SVG with transparent background. Refuses PNG.

The module source is in Section 11.

---

## 7. MATPLOTLIB IMPLEMENTATION

### Layout Patterns

#### Heterogeneous multi-panel (PREFERRED: SubFigures)
```python
fig = plt.figure(figsize=(7, 9), layout='constrained')
(row0, row1, row2) = fig.subfigures(3, 1, height_ratios=[1, 1.4, 1])
axs_r0 = row0.subplots(1, 4)
axs_r1 = row1.subplots(1, 3, gridspec_kw={'width_ratios': [1.2, 2, 0.8]})
```

#### Heterogeneous multi-panel (ALTERNATIVE: nested GridSpec)
```python
fig = plt.figure(figsize=(7, 10))
outer = gridspec.GridSpec(4, 1, figure=fig,
    height_ratios=[1, 1.1, 1.4, 1.0], hspace=0.35)
gs_row0 = gridspec.GridSpecFromSubplotSpec(1, 4,
    subplot_spec=outer[0], wspace=0.30)
```

#### Aligned biclustering (GridSpec with tight spacing)
```python
fig = plt.figure(figsize=(7, 9), layout='constrained')
gs = fig.add_gridspec(6, 5,
    height_ratios=[0.5, 0.8, 0.3, 4, 0.2, 0.3],
    width_ratios=[0.15, 0.5, 3, 0.3, 0.15])
```

#### Simple regular grids (subplot_mosaic)
```python
fig, axd = plt.subplot_mosaic(
    [['A', 'B'], ['C', 'C']],
    figsize=(7, 5), layout='constrained')
```

### Heatmap Recipes

**Aligned heatmap** (biclustering):
```python
im = ax.imshow(data, aspect='auto', cmap=OCEAN_CMAP, interpolation='nearest')
```

**Standalone heatmap** (correlation matrix — compact square cells):
```python
im = ax.imshow(data, cmap=DIVERGING_CMAP, norm=norm, aspect='equal',
               interpolation='nearest')
```
Control cell size via narrow `width_ratios` column in GridSpec.

### Colorbar Recipes

| Context | Code | When |
|---------|------|------|
| Aligned heatmap | `fraction=0.008, pad=0.01, aspect=30` | Thin strip beside dominant heatmap |
| Standalone heatmap | `fraction=0.04, pad=0.03, aspect=20` | Compact correlation matrix |
| Scatter/hexbin | `shrink=0.6, pad=0.02` | Visible size beside plot |

Always apply:
```python
cbar.ax.tick_params(labelsize=6, width=0.25, length=2)
cbar.outline.set_linewidth(0.25)
```

### Dendrogram Recipe
```python
from scipy.cluster.hierarchy import dendrogram
dn = dendrogram(linkage, ax=ax, orientation='left',
                color_threshold=0, above_threshold_color='black',
                no_labels=True)
ax.set_axis_off()
```

### Export
Use `save_figure()` from `tara_style`. If unavailable:
```python
for fmt in ['pdf', 'svg']:
    fig.savefig(f'figure_name.{fmt}', format=fmt,
                transparent=True, edgecolor='none')
```

**NEVER save PNG for publication figures.**

---

## 8. TikZ IMPLEMENTATION

### Document Preamble
```tex
\documentclass[tikz,border=3pt]{standalone}
\usepackage[T1]{fontenc}
\usepackage[scaled=0.9]{helvet}
\renewcommand*\familydefault{\sfdefault}
\usepackage{tikz}
\usepackage{xcolor}
\usetikzlibrary{
    shapes.geometric, shapes.misc, shapes.symbols,
    arrows.meta, positioning, fit, calc, backgrounds, patterns
}
```

### MODIS Ocean Categorical Palette
```tex
\definecolor{modisDeepLight}{RGB}{198,219,239}
\definecolor{modisTealLight}{RGB}{204,236,239}
\definecolor{modisChloroLight}{RGB}{232,245,208}
\definecolor{modisThermalLight}{RGB}{255,237,204}
\definecolor{modisVioletLight}{RGB}{229,216,246}
\definecolor{modisDeep}{RGB}{8,48,107}
\definecolor{modisTeal}{RGB}{0,109,119}
\definecolor{modisChloro}{RGB}{120,147,60}
\definecolor{modisThermal}{RGB}{204,102,0}
\definecolor{modisViolet}{RGB}{106,61,154}
```

### Node Styles
```tex
\tikzset{
    baseBox/.style={
        rectangle, rounded corners=2pt, draw=black,
        line width=0.25pt, minimum height=0.65cm,
        text centered,
        font=\fontsize{6}{7.2}\selectfont\sffamily,
        inner xsep=5pt, inner ysep=3pt
    },
    dataBox/.style={baseBox, fill=modisDeepLight},
    processBox/.style={baseBox, fill=modisTealLight},
    mlBox/.style={baseBox, fill=modisChloroLight},
    envBox/.style={baseBox, fill=modisThermalLight},
    analysisBox/.style={baseBox, fill=modisVioletLight}
}
```

### Arrow Styles
```tex
mainArrow/.style={->, >={Stealth[length=2mm,width=1.5mm]}, line width=0.6pt, black},
branchArrow/.style={->, >={Stealth[length=1.6mm,width=1.2mm]}, line width=0.4pt, black!60, densely dashed},
mergeArrow/.style={->, >={Stealth[length=2mm,width=1.5mm]}, line width=0.6pt, modisThermal}
```

### Spacing & Line Weights

| Element | Value |
|---|---|
| node distance (default) | 0.12cm |
| Title to first box | `below=0.2cm` |
| Between sequential stages | `below=0.1cm` |
| Parallel branch offset | `right=2.5cm` |
| Box borders | 0.25pt |
| Main arrows | 0.6pt |
| Branch arrows | 0.4pt |

Build TikZ incrementally — compile after adding each stage.

---

## 9. SEABORN INTEGRATION

```python
import seaborn as sns
from tara_style import apply_tara_style
apply_tara_style()

sns.set_theme(style='ticks', context='paper', font_scale=1.0)
sns.despine()
```

### Rules
- Always `apply_tara_style()` BEFORE any seaborn configuration
- Use `ax=` parameter for multi-panel figures
- Override palette with project colors: `palette=[rgb_to_hex(c) for c in get_categorical_colors(n)]`
- Always `sns.despine()` — remove top/right spines
- Show individual data points when possible: `sns.stripplot(..., alpha=0.3, size=3)` over box/bar

---

## 10. LAYOUT ARCHITECTURE PATTERNS

### Multi-Panel with Dendrograms + Statistics + Heatmap
```
[row dendro] [row anno] [   MAIN HEATMAP   ] [stats] [extra]
                         [  col dendrogram   ]
                         [   env var tracks   ]
                         [  metadata bars     ]
                         [===== HEATMAP =====]
                         [    colorbar        ]
                         [     legend         ]
```

### Heterogeneous Multi-Panel Figure
```
Row 0: [  UMAP-CC1  ] [  UMAP-CC2  ] [  UMAP-CC3  ] [  UMAP-CC4  ]
Row 1: [  HexEnv1   ] [  HexEnv2   ] [  HexEnv3   ] [  HexEnv4   ]
Row 2: [   Donut    ] [ Heatmap  ] [  Bar chart   ]
Row 3: [  Lineage   ] [  Histogram ] [ Ridge plot  ]
```
Use SubFigures with `layout='constrained'`. Each row owns its panels independently.

### Planning Protocol (MANDATORY for >4 panels)
Present a numbered-row ASCII layout grid BEFORE writing any code. Use 1-based row numbering. Get explicit user approval before proceeding.

### Panel Axes Tracking
**NEVER rely on `fig.get_axes()` ordering.** Colorbars and insets insert extra axes that shift indices. Collect panel axes explicitly:
```python
panel_axes = []
for i, draw_fn in enumerate([draw_a, draw_b, draw_c, draw_d]):
    ax = fig.add_subplot(gs[0, i])
    draw_fn(ax)
    panel_axes.append(ax)

for letter, ax in zip('ABCD', panel_axes):
    ax.text(-0.12, 1.08, letter, ...)
```

### Full-Width Panel Label Alignment
A panel label at `-0.12` in `transAxes` on a full-width panel is much further left than on a quarter-width panel. Align using figure coordinates:
```python
ax_a_bbox = panel_axes[0].get_position()
label_x_fig = ax_a_bbox.x0 - 0.02
ax_pos = ax_fullwidth.get_position()
x_axes = (label_x_fig - ax_pos.x0) / ax_pos.width
ax_fullwidth.text(x_axes, 1.08, 'H', transform=ax_fullwidth.transAxes, ...)
```

### Row Height Ratios

| Row type | Height ratio |
|---|---|
| 4-panel row (charts/bars) | 0.19–0.22 |
| 3-panel row (wider panels) | 0.19–0.22 |
| Full-width compact (heatmap, profiles) | 0.12–0.16 |
| 3-panel row with tall content | 0.24–0.27 |

Use `hspace=0.28` for tight but readable inter-row gaps. Default `hspace=0.35+` wastes vertical space.

### Space-Saving Techniques
1. **Shared axes** — multiple panels use same x/y coordinates
2. **Inline legends** — color bars AS data tracks
3. **Sparse labeling** — every 5th PFAM labeled
4. **Compact colorbars** — context-dependent (see Section 7)
5. **Merged annotations** — taxa as colored bar, not text labels
6. **Compact heatmap cells** — `aspect='equal'` + narrow GridSpec column

---

## 11. THE `tara_style` MODULE

Source for `figures/tara_style.py`. **Create this file if it does not exist.**

```python
#!/usr/bin/env python3
"""TARA Oceans Manuscript -- Figure Style Infrastructure."""

import matplotlib as mpl
import matplotlib.pyplot as plt
from pathlib import Path
from datetime import datetime
from typing import List, Optional

JOURNAL_SPECS = {
    'nature': {'single': 89, 'double': 183, 'max_height': 247},
    'science': {'single': 55, 'double': 175, 'max_height': 233},
    'cell': {'single': 85, 'double': 178, 'max_height': 230},
    'plos': {'single': 83, 'double': 173, 'max_height': 233},
    'acs': {'single': 82.5, 'double': 178, 'max_height': 247},
}


def apply_tara_style(target: str = 'cell') -> None:
    style = {
        'pdf.fonttype': 42,
        'ps.fonttype': 42,
        'svg.fonttype': 'none',
        'font.family': 'sans-serif',
        'font.sans-serif': ['Arial', 'Helvetica'],
        'font.size': 6,
        'axes.labelsize': 6,
        'axes.titlesize': 6,
        'xtick.labelsize': 6,
        'ytick.labelsize': 6,
        'legend.fontsize': 6,
        'axes.linewidth': 0.25,
        'xtick.major.width': 0.25,
        'ytick.major.width': 0.25,
        'xtick.major.size': 2,
        'ytick.major.size': 2,
        'axes.labelpad': 1,
        'xtick.major.pad': 1,
        'ytick.major.pad': 1,
        'axes.spines.top': False,
        'axes.spines.right': False,
        'axes.grid': False,
        'axes.axisbelow': True,
        'axes.edgecolor': 'black',
        'axes.labelcolor': 'black',
        'legend.frameon': False,
        'figure.dpi': 100,
        'figure.facecolor': 'white',
        'figure.constrained_layout.use': True,
        'lines.linewidth': 1.2,
        'lines.markersize': 3,
        'lines.markeredgewidth': 0.4,
        'savefig.dpi': 600,
        'savefig.format': 'pdf',
        'savefig.transparent': True,
        'savefig.facecolor': 'none',
        'savefig.edgecolor': 'none',
        'image.cmap': 'viridis',
    }
    mpl.rcParams.update(style)


def check_figure_size(fig, journal='cell', width='double'):
    specs = JOURNAL_SPECS.get(journal.lower(), JOURNAL_SPECS['cell'])
    w_in, h_in = fig.get_size_inches()
    w_mm, h_mm = w_in * 25.4, h_in * 25.4
    target_mm = specs.get(width, specs['double'])
    max_h = specs['max_height']
    w_ok = abs(w_mm - target_mm) < 5
    h_ok = h_mm <= max_h
    status = 'PASS' if (w_ok and h_ok) else 'FAIL'
    print(f"Figure size ({journal.upper()} {width}): {status}")
    print(f"  Actual: {w_mm:.1f} x {h_mm:.1f} mm")
    print(f"  Target: {target_mm} mm wide, max {max_h} mm tall")
    return {'width_mm': w_mm, 'height_mm': h_mm, 'compliant': w_ok and h_ok}


def save_figure(fig, name, output_dir='figures', formats=None):
    if formats is None:
        formats = ['pdf', 'svg']
    formats = [f for f in formats if f != 'png']
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    saved = []
    for fmt in formats:
        path = out / f"{name}.{fmt}"
        fig.savefig(path, format=fmt, transparent=True, edgecolor='none')
        saved.append(path)
        print(f"  Saved: {path}")
    return saved
```

---

## 12. SCRIPT TEMPLATE

```python
#!/usr/bin/env python3
"""Figure N: [description]. Generated YYYY-MM-DD."""

import sys, os
import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from tara_style import apply_tara_style, check_figure_size, save_figure
from palette import (OCEAN_CMAP, DIVERGING_CMAP, get_categorical_colors,
                     BASIN_COLORS, LINEAGE_COLORS)

apply_tara_style()

# ---------- data ----------
data = ...

# ---------- figure ----------
fig = plt.figure(figsize=(7, 5), layout='constrained')
# ... build panels ...

# ---------- panel labels ----------
for ax, letter in zip(axes, 'ABCDEF'):
    ax.text(-0.12, 1.08, letter, transform=ax.transAxes,
            fontsize=6, fontweight='bold', va='top', ha='left')

# ---------- validate & export ----------
check_figure_size(fig, 'cell', 'double')
save_figure(fig, 'figureN_description_YYYYMMDD_HHMMSS')
plt.close(fig)
```

---

## 13. SVG EXPERT MODE

This section covers direct SVG editing for post-generation modifications, Illustrator compatibility, and vector text operations.

### Golden Rule: Never Edit In Place
Always write output to a NEW file with a timestamp suffix. The original must survive intact.

### SVG Structure Awareness
```
<svg>
  <defs>          <!-- Gradients, patterns, clipPaths, styles -->
  <style>         <!-- CSS rules (class-based styling) -->
  <metadata>      <!-- Tool-specific data (Illustrator PGF, Inkscape) -->
  <g>             <!-- Groups: primary organizational unit -->
    <path>        <!-- Vector shapes -->
    <text>        <!-- Live text -->
      <tspan>     <!-- Text spans within <text> -->
    <circle>, <rect>, <line>, <polygon>
    <image>       <!-- Embedded rasters (base64 or linked) -->
    <use>         <!-- References to <defs> elements -->
  </g>
</svg>
```

### The Adobe Illustrator PGF Problem
Illustrator SVGs contain a `<metadata>` section with a compressed PGF blob — a copy of the entire .ai file. When Illustrator opens the SVG, **it reads the PGF blob and ignores the SVG markup entirely**. Edits to `<text>`, `<path>`, `<g>` elements are invisible to Illustrator.

**Resolution: Strip PGF metadata (preferred for edited SVGs)**
```python
import re
svg_stripped = re.sub(r'\s*<metadata>.*?</metadata>', '', svg, flags=re.DOTALL)
```
This forces Illustrator to read actual SVG markup. Visual content is preserved.

### SVG Text Editing

Anatomy of a matplotlib-generated label:
```xml
<g id="text_23">
  <g id="patch_15">
    <path class="st615" d="M822.3,426.6h31.8c.8,0,..."/>  <!-- background box -->
  </g>
  <text class="st611" transform="translate(822.3 424.1)">
    <tspan x="0" y="0">LabelText</tspan>
  </text>
</g>
```

To remove: remove the entire `<g id="text_N">` block. To change text: modify the `<tspan>` content.

### Batch Label Operations
```python
LABEL_PATTERN = re.compile(
    r'(\s*<g id="text_\d+">\s*'
    r'(?:<g id="patch_\d+">\s*<path[^/]*/>\s*</g>\s*)?'
    r'<text[^>]*><tspan[^>]*>(.*?)</tspan></text>\s*'
    r'</g>)',
    re.DOTALL
)
```

### SVG Validation (after every edit)
```python
from xml.etree import ElementTree
try:
    ElementTree.fromstring(svg_content)
    print("VALID XML")
except ElementTree.ParseError as e:
    print(f"INVALID: {e}")
```

### Background Boxes for Label Readability
Network figures and dense visualizations need semi-transparent background boxes behind labels:
```python
BOX_W = 56        # covers 8 chars at 12px
BOX_H_INNER = 13  # vertical span
BOX_R = 1.2       # corner radius
X_PAD = -2        # left padding beyond text origin
Y_OFFSET = 3.5    # box bottom below text baseline
```
Box style CSS: `fill: #fff; opacity: .7;`

When labels move, boxes must follow — always update paired `<path>` coordinates.

### Label Overlap Resolution (Force-Directed Repulsion)
```python
def repel_labels(group, iterations=80, padding_x=3, padding_y=2):
    for _ in range(iterations):
        moved = False
        for i in range(len(group)):
            for j in range(i+1, len(group)):
                a, b = group[i], group[j]
                dx = a['x'] - b['x']; dy = a['y'] - b['y']
                min_dx = (a['w'] + b['w'])/2 + padding_x
                min_dy = (a['h'] + b['h'])/2 + padding_y
                adx = abs(dx) or 0.1; ady = abs(dy) or 0.1
                if adx < min_dx and ady < min_dy:
                    sy = 1 if dy >= 0 else -1
                    sx = 1 if dx >= 0 else -1
                    a['y'] += sy * (min_dy-ady)/2 * 0.6
                    b['y'] -= sy * (min_dy-ady)/2 * 0.6
                    a['x'] += sx * (min_dx-adx)/2 * 0.3
                    b['x'] -= sx * (min_dx-adx)/2 * 0.3
                    moved = True
        if not moved:
            break
```

### Text Width Estimation
- **12px Arial**: ~7.2px/char width, ~15.6px height
- **6px Arial**: ~3.6px/char width, ~7.8px height
- General: `width = nchars × font_size × 0.6`, `height = font_size × 1.3`

### SVG File Size Reduction
- Strip PGF metadata (often 50–70% of file size)
- Remove unused `<defs>` entries
- Simplify path precision: `re.sub(r'(\d+\.\d{2})\d+', r'\1', svg)`
- Remove empty groups

### Renderer Differences

| Feature | Browser | Illustrator | Inkscape |
|---------|---------|-------------|----------|
| PGF metadata | Ignored | **Primary source** | Ignored |
| CSS in `<style>` | Full | Good | Good |
| Embedded fonts | Depends | Requires installed font | Good |
| Foreign objects | Supported | **Not supported** | Partial |

### Rasterized-to-Vector Text Conversion
When matplotlib panels arrive as `<image>` elements containing base64 PNGs, all text within is non-editable. Workflow:
1. Extract the embedded PNG
2. Determine the image transform (`translate`, `scale`)
3. Add white mask rectangles over rasterized text areas
4. Add vector `<text>` elements at computed SVG positions
5. Group all overlays in `<g id="vector_text_overlay">`

---

## 14. MANDATORY POST-CREATION VALIDATION

After EVERY figure, perform ALL checks **individually**. Do NOT rubber-stamp — each check must be verified separately.

### Checklist

| # | Check | How to Verify | Pass Criteria |
|---|-------|--------------|---------------|
| 1 | **Programmatic validation** | Run `validate_figure(fig)` | Zero issues returned |
| 2 | **View the figure** | Read tool on output PDF/SVG | File renders correctly |
| 3 | **Crop-and-zoom** | View at least one dense region (labels, legend) at crop level | No overlap visible |
| 4 | **Font verification** | Spot-check multiple text elements | ALL text 6pt Arial |
| 5 | **Transparent background** | Confirm `transparent=True` in savefig | No white rectangle |
| 6 | **Vector format** | Check file extension | PDF and/or SVG, never PNG |
| 7 | **Data-to-ink ratio** | Visual estimate | >70% of area is data |
| 8 | **Color verification** | Compare against palette.py | Project palettes, white for NaN |
| 9 | **Line weight** | Inspect axes/ticks | 0.25pt, not matplotlib default |
| 10 | **Figure dimensions** | `check_figure_size(fig)` | Width matches journal column |
| 11 | **Re-render after fixes** | If ANY fix was applied, re-render and re-validate from #1 | All checks pass on final render |

### Reporting Format
```
Validation (render cycle N):
 1. Programmatic: PASS (0 overlaps, 0 font issues)
 2. View: PASS
 3. Crop-zoom: PASS (checked x-axis labels, legend, colorbar)
 4. Font: PASS (6pt Arial throughout)
 ...
```

### If ANY check fails:
- Fix the issue immediately
- **Re-render the figure** (do not assume the fix worked)
- Re-run the ENTIRE checklist from #1
- Do NOT report completion until all checks pass on the same render

---

## 15. COMMON FAILURE MODES

| Failure | Root Cause | Fix |
|---|---|---|
| Text overlapping axes | Default labelpad | `labelpad=1, tickpad=1` via `apply_tara_style()` |
| Labels overlapping each other | Too many labels | Sparse labeling or 45° rotation |
| Fonts not 6pt | Mixed sizes | `apply_tara_style()` at script top |
| White background in PDF | Omitted `transparent=True` | `save_figure()` or explicit `transparent=True` |
| Blurry figure | Saved as PNG | PDF + SVG only |
| Default ugly colors | Forgot custom colormap | Import from `palette.py` |
| Multi-panel overlap/collision | Flat spacing on heterogeneous figure | SubFigures or nested GridSpec |
| Oversized heatmap cells | `aspect='auto'` with wide allocation | `aspect='equal'` + narrow `width_ratios` |
| Invisible sliver colorbars | `fraction=0.008` on scatter panel | `shrink=0.6, pad=0.02` |
| Unwanted panel titles | `set_title()` on panels | Remove; describe in caption |
| Bold text on non-labels | `fontweight='bold'` on axis labels | Bold ONLY on panel letters |
| Uneditable fonts in PDF | Wrong fonttype | `pdf.fonttype = 42` |
| Diverging cmap on non-diverging data | Wrong cmap choice | Sequential for R², abundance, counts |
| Seaborn overrides project style | Called `sns.set_theme()` first | `apply_tara_style()` BEFORE seaborn |
| Figure too large for journal | Unchecked figsize | `check_figure_size()` before export |
| Unicode in labels | Subscript characters | Write `Log2` not `Log₂` |
| PDF composition width mismatch | Different native widths | Source PDFs must match physical width |
| Panel labels shifted by colorbar | `fig.get_axes()` includes colorbars | Collect panel axes explicitly |
| Full-width label misaligned | `-0.12` transAxes scales with width | Compute label x from figure coords |
| Too much whitespace between rows | Default `hspace` too large | Start at `hspace=0.28` |
| Declared victory after one render | Did not iterate | Minimum 2 render-check-fix cycles |
| Overlap missed by Claude | Visual inspection alone | Run `validate_figure()` programmatically |
| Fix applied but not re-rendered | Assumed code change worked | Always re-render and re-validate |

---

## 16. FIGURE SIZE STANDARDS

| Context | Width | Notes |
|---|---|---|
| Single column | 3.5 in (89mm) | Nature, Science, Cell |
| 1.5 column | 5.5 in (140mm) | Some journals |
| Double column | 7 in (178mm) | Full-width figures |
| Full page | 8.27 × 11.69 in (A4) | Supplementary |

### Journal Dimension Reference (mm)

| Journal | Single | Double | Max Height |
|---------|--------|--------|------------|
| Nature | 89 | 183 | 247 |
| Science | 55 | 175 | 233 |
| Cell | 85 | 178 | 230 |
| PLOS | 83 | 173 | 233 |

---

*Artist mode is now active. Every figure produced in this session will conform to these standards. The render-check-fix loop is mandatory. No exceptions.*
