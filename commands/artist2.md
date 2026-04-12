---
description: ARTIST MODE ACTIVATED
---

# ARTIST MODE v2

You are now operating in **artist mode v2**. Every pixel justifies its existence. Spatial awareness is paramount. These are binding rules, not suggestions.

This skill combines project-specific standards with reusable infrastructure (style presets, export utilities, size validators) so that figure scripts are shorter, more consistent, and harder to get wrong.

---

## 0. STYLE INFRASTRUCTURE

Before writing any plotting code, apply the project style preset. This replaces the 30+ lines of rcParams scattered across every script with a single function call.

### Apply Style (top of every script)

```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from tara_style import apply_tara_style, check_figure_size, save_figure
apply_tara_style()
```

This one call sets ALL rcParams (6pt Arial, 0.25pt lines, minimal padding, TrueType embedding, transparent export defaults). No need to repeat rcParams blocks.

### The `tara_style` module (`figures/tara_style.py`)

If this file does not exist, create it. It provides three functions:

#### `apply_tara_style(target='cell')`
Applies the full rcParams configuration. Optional `target` argument for journal-specific tweaks.

#### `check_figure_size(fig, journal='cell', width='double')`
Validates figure dimensions against journal specs. Prints PASS/FAIL with actual vs. expected mm. Call before saving.

#### `save_figure(fig, name, output_dir='figures')`
Saves PDF + SVG with transparent background. Adds provenance comment. Refuses to save PNG. Returns list of saved paths.

**The module source is defined in Section 11 below. Create it once; import it everywhere.**

---

## 1. UNIVERSAL DESIGN LAWS (all tools)

### Spatial Hierarchy
- Padding between nested elements MUST decrease inward (outer margin > panel gap > label pad > tick pad)
- **Aligned layouts** (heatmap + dendrogram + annotation tracks sharing axes): `hspace/wspace = 0.02`
- **Heterogeneous multi-panel composites** (independent axes with their own labels, colorbars, legends): use **SubFigures + `layout='constrained'`** (preferred) or nested GridSpec with `hspace=0.30-0.40`
- Label pad: `1pt`
- Tick pad: `1pt`
- NEVER use flat `hspace/wspace=0.02` on multi-panel figures with independent axes

### Anti-Overlap Mandate
- **NO text may touch any other element** -- not other text, not axes, not data points, not borders, not colorbars
- This is the #1 rejection reason for journal figures
- Minimum clearance: 1pt between any text element and any other figure element

### Breathing Room
| Element pair | Minimum clearance |
|---|---|
| Text to text | 1pt |
| Text to axis line | 1pt (via labelpad/tickpad) |
| Text to data (bars, points) | 2pt |
| Panel to panel (aligned layout) | 0.02 in figure fraction |
| Panel to panel (heterogeneous) | 0.30-0.40 hspace via SubFigures or nested GridSpec |
| Colorbar to heatmap | 0.008 width fraction gap |

### Data-to-Ink Ratio
- Target: >70% of figure area showing data
- Remove all chart junk: unnecessary gridlines, borders, backgrounds, legends that duplicate axis info
- Fill the entire figure area

### Visual Weight Balance
- Distribute visual density evenly across the figure
- A dendrogram on the left balances annotation tracks on the right
- A colorbar should be compact and context-appropriate (see Section 5), never dominant

---

## 2. TYPOGRAPHY LAW

**ALL text: 6pt Arial. No exceptions.**

This is enforced by `apply_tara_style()`. If writing a standalone script without the module, use the raw rcParams from Section 11.

### Font Embedding (critical for journal/Illustrator compatibility)
```python
mpl.rcParams['pdf.fonttype'] = 42      # TrueType in PDF
mpl.rcParams['ps.fonttype'] = 42       # TrueType in PostScript
mpl.rcParams['svg.fonttype'] = 'none'  # Embed fonts in SVG
```

### TikZ Typography
- Use `\fontsize{6}{7.2}\selectfont\sffamily` for all node text
- Document preamble: `\usepackage[scaled=0.9]{helvet}` with `\renewcommand*\familydefault{\sfdefault}`

### Panel Labels and Titles
- **Panel labels** (`A`, `B`, `C`, ...) are the ONLY bold text in a figure -- 6pt bold Arial
- **NO panel titles** -- titles belong in the figure caption/legend, not on the panel itself
- Remove all `ax.set_title()` calls
- Panel label position: `ax.text(-0.12, 1.08, letter, transform=ax.transAxes, fontsize=6, fontweight='bold', va='top', ha='left')`

### Text Content Rules
- **NO unicode subscripts** -- write `Log2` not `Log_2`, write `CO2` not `CO_2`
- Abbreviate aggressively in dense figures: `"2119"` instead of `"PF02119"`
- Use sparse labeling: every Nth item when >20 items on an axis
- **NO `fontweight='bold'`** anywhere except panel labels

---

## 3. COLOR SYSTEMS

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
| R-squared/Performance | `OCEAN_CMAP` | Sequential, NOT diverging |
| Chlorophyll/Productivity | `FOREST_CMAP` | `get_sequential_cmap('forest')` |
| Temperature | `THERMAL_CMAP` | `get_sequential_cmap('thermal')` |
| Correlations (-1 to +1) | `DIVERGING_CMAP` | `get_diverging_cmap()` |
| Residuals/Z-scores | `DIVERGING_CMAP` | Centered at zero |
| Basins | `BASIN_COLORS` | Dict lookup |
| Lineages | `LINEAGE_COLORS` | Dict lookup |
| Modules/Clusters | `get_categorical_colors(n)` | 10-color Earth palette |

### Color Rules
- **White = missing/NaN** -- always, in every context (`CLOUD_WHITE` from palette.py)
- Colorblind-safe: all project palettes pass deuteranopia simulation
- Grayscale-distinguishable: patterns must survive B&W conversion
- **NEVER use**: rainbow/jet, default matplotlib colors (tab10), `RdBu_r` for non-centered data, diverging maps for non-diverging data

### Fallback Colorblind Palettes (non-project contexts)
When project palette.py is not available (e.g., standalone utility figures):
```python
OKABE_ITO = ['#E69F00', '#56B4E9', '#009E73', '#F0E442',
             '#0072B2', '#D55E00', '#CC79A7', '#000000']
WONG = ['#000000', '#E69F00', '#56B4E9', '#009E73',
        '#F0E442', '#0072B2', '#D55E00', '#CC79A7']
```

---

## 4. ANTI-OVERLAP PROTOCOL

Apply these strategies in order of preference:

### Strategy 1: Rotation
- Rotate x-axis labels 45deg when >6 labels
- `ha='right', rotation_mode='anchor'`

### Strategy 2: Sparse Labeling
- When >20 items: label every Nth item
- `ax.set_xticks(ticks[::N])`

### Strategy 3: Abbreviation
- Strip common prefixes: `"PF02119"` -> `"2119"`
- Truncate long names to 15 chars + `...`
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

## 5. MATPLOTLIB IMPLEMENTATION

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
ax.set_xticks(range(0, n_cols, label_every_n))
ax.set_yticks(range(0, n_rows, label_every_n))
```

**Standalone heatmap** (correlation matrix -- compact square cells):
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

Use `save_figure()` from `tara_style` module. If unavailable:
```python
for fmt in ['pdf', 'svg']:
    fig.savefig(f'figure_name.{fmt}', format=fmt,
                transparent=True, edgecolor='none')
# bbox_inches='tight' is NOT needed with layout='constrained'
```

**NEVER save PNG for publication figures.**

---

## 6. TikZ IMPLEMENTATION

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

### Node Styles (MODIS Ocean Categorical Palette)
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

### Spacing
| Element pair | Distance |
|---|---|
| node distance (default) | 0.12cm |
| Title to first box | `below=0.2cm` |
| Between sequential stages | `below=0.1cm` |
| Parallel branch offset | `right=2.5cm` |

### Line Weights
| Element | Width |
|---|---|
| Box borders | 0.25pt |
| Main arrows | 0.6pt |
| Branch arrows | 0.4pt |

Build TikZ incrementally -- compile after adding each stage.

---

## 7. LAYOUT ARCHITECTURE PATTERNS

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

### Space-Saving Techniques
1. **Shared axes** -- multiple panels use same x/y coordinates
2. **Inline legends** -- color bars AS data tracks, not separate boxes
3. **Sparse labeling** -- every 5th PFAM labeled
4. **Compact colorbars** -- context-dependent (see Section 5)
5. **Merged annotations** -- taxa as colored bar, not text labels
6. **Compact heatmap cells** -- `aspect='equal'` + narrow GridSpec column

---

## 8. SEABORN INTEGRATION

When seaborn is appropriate (statistical comparisons, distributions, faceted exploration), configure it to respect project standards:

```python
import seaborn as sns
from tara_style import apply_tara_style
apply_tara_style()

# Layer seaborn on top of project rcParams
sns.set_theme(style='ticks', context='paper', font_scale=1.0)
# Do NOT call sns.set_palette() -- use project palette.py colors
sns.despine()
```

### When to Use Seaborn
- Box + strip overlays for group comparisons
- Violin plots for distribution shape
- `clustermap()` for hierarchically-clustered heatmaps (exploratory)
- `FacetGrid` / `relplot` for faceted small multiples
- Regression plots with confidence bands

### Seaborn Rules
- Always apply `apply_tara_style()` BEFORE any seaborn configuration
- Use `ax=` parameter (axes-level functions) when building multi-panel figures
- Use figure-level functions (`relplot`, `catplot`) only for standalone exploratory figures
- Override seaborn palette with project colors: `palette=[rgb_to_hex(c) for c in get_categorical_colors(n)]`
- Always `sns.despine()` -- remove top/right spines
- Show individual data points when possible: `sns.stripplot(..., alpha=0.3, size=3)` over box/bar

---

## 9. MANDATORY POST-CREATION VALIDATION

After EVERY figure is generated, perform ALL of these checks **individually** before reporting completion. Do NOT rubber-stamp -- each check must be verified separately.

### Checklist

| # | Check | How to Verify | Pass Criteria |
|---|-------|--------------|---------------|
| 1 | **View the figure** | Read tool on output PDF/SVG | File opens, looks reasonable |
| 2 | **Text overlap** | Inspect at 400% zoom | NO text touching any other element |
| 3 | **Font verification** | Spot-check multiple text elements | ALL text is 6pt Arial, no size variation |
| 4 | **Transparent background** | Confirm `transparent=True` in savefig | No white rectangle behind figure |
| 5 | **Vector format** | Check file extension | PDF and/or SVG only, never PNG |
| 6 | **Data-to-ink ratio** | Visual estimate | >70% of area is data |
| 7 | **Color verification** | Compare against palette.py | Project palettes used, white for NaN |
| 8 | **Line weight** | Measure or inspect | Axes/ticks at 0.25pt |
| 9 | **Figure dimensions** | `check_figure_size(fig, 'cell')` | Width matches journal column spec |
| 10 | **Colormap appropriateness** | Check data type vs. cmap | Sequential for non-negative; diverging only for centered data |

### If ANY check fails:
- Fix the issue immediately
- Re-export the figure
- Re-run the ENTIRE checklist from #1
- Do NOT report completion until all checks pass

### Reporting Format
When reporting validation results, list each check individually:
```
Validation:
 1. View: PASS (figure renders correctly)
 2. Text overlap: PASS (no collisions at 400%)
 3. Font: PASS (6pt Arial throughout)
 ...
```

---

## 10. COMMON FAILURE MODES

| Failure | Root Cause | Fix |
|---|---|---|
| Text overlapping axes | Default labelpad | Set `labelpad=1`, `tickpad=1` (via `apply_tara_style()`) |
| Labels overlapping each other | Too many labels | Sparse labeling or 45deg rotation |
| Fonts not 6pt | Mixed sizes or forgot rcParams | `apply_tara_style()` at script top |
| White background in PDF | Omitted `transparent=True` | Use `save_figure()` or explicit `transparent=True` |
| Blurry figure | Saved as PNG | PDF + SVG only |
| Default ugly colors | Forgot custom colormap | Import from `palette.py` |
| Multi-panel overlap/collision | Flat spacing on heterogeneous figure | SubFigures or nested GridSpec |
| Oversized heatmap cells | `aspect='auto'` with wide allocation | `aspect='equal'` + narrow `width_ratios` |
| Invisible sliver colorbars | `fraction=0.008` on scatter panel | `shrink=0.6, pad=0.02` for non-heatmaps |
| Unwanted panel titles | `set_title()` on panels | Remove; describe in caption |
| Bold text on non-labels | `fontweight='bold'` on axis labels | Bold ONLY on panel letters |
| Uneditable fonts in PDF | Wrong fonttype | `pdf.fonttype = 42` (via `apply_tara_style()`) |
| Diverging cmap on non-diverging data | Wrong cmap choice | Sequential for R-squared, abundance, counts |
| Seaborn overrides project style | Called `sns.set_theme()` first | Always `apply_tara_style()` BEFORE seaborn config |
| Figure too large for journal | Unchecked figsize | `check_figure_size()` before export |
| Unicode in labels | Subscript characters | Write `Log2` not `Log_2` |
| PDF composition width mismatch | Different native widths | Source PDFs must match physical width |
| Panel labels shifted by colorbar axes | `fig.get_axes()` includes colorbars | Collect panel axes explicitly in a list as you create them |
| Full-width panel label misaligned | `-0.12` transAxes scales with panel width | Compute label x from figure coords, align with Row 1 |
| Too much whitespace between rows | Default `hspace` too large | Start at `hspace=0.28`; increase only if elements collide |

---

## 11. FIGURE SIZE STANDARDS

| Context | Width | Notes |
|---|---|---|
| Single column | 3.5 in (89mm) | Nature, Science, Cell |
| 1.5 column | 5.5 in (140mm) | Some journals |
| Double column | 7 in (178mm) | Full-width figures |
| Full page | 8.27 x 11.69 in (A4) | Supplementary |

Use `check_figure_size(fig, journal, width)` to validate before export.

### Journal Dimension Reference (mm)

| Journal | Single | Double | Max Height |
|---------|--------|--------|------------|
| Nature | 89 | 183 | 247 |
| Science | 55 | 175 | 233 |
| Cell | 85 | 178 | 230 |
| PLOS | 83 | 173 | 233 |

---

## 12. THE `tara_style` MODULE

This is the source for `figures/tara_style.py`. **Create this file if it does not exist.**

```python
#!/usr/bin/env python3
"""
TARA Oceans Manuscript -- Figure Style Infrastructure
=====================================================

Single-call style application, figure size validation, and
publication-quality export for all manuscript figures.

Usage:
    from tara_style import apply_tara_style, check_figure_size, save_figure
    apply_tara_style()

Created: 2026-04-12
"""

import matplotlib as mpl
import matplotlib.pyplot as plt
from pathlib import Path
from datetime import datetime
from typing import List, Optional


# ══════════════════════════════════════════════════════════════════════
# JOURNAL SPECIFICATIONS
# ══════════════════════════════════════════════════════════════════════

JOURNAL_SPECS = {
    'nature': {'single': 89, 'double': 183, 'max_height': 247},
    'science': {'single': 55, 'double': 175, 'max_height': 233},
    'cell': {'single': 85, 'double': 178, 'max_height': 230},
    'plos': {'single': 83, 'double': 173, 'max_height': 233},
    'acs': {'single': 82.5, 'double': 178, 'max_height': 247},
}


# ══════════════════════════════════════════════════════════════════════
# STYLE APPLICATION
# ══════════════════════════════════════════════════════════════════════

def apply_tara_style(target: str = 'cell') -> None:
    """
    Apply full TARA Oceans publication style to matplotlib.

    Sets ALL rcParams: 6pt Arial, 0.25pt lines, minimal padding,
    TrueType embedding, viridis default cmap, constrained layout.

    Parameters
    ----------
    target : str
        Journal target for DPI. 'cell', 'nature', 'science'.
        All use 600 DPI for combination figures.
    """
    style = {
        # Font embedding (Illustrator compatibility)
        'pdf.fonttype': 42,
        'ps.fonttype': 42,
        'svg.fonttype': 'none',

        # ALL 6pt Arial
        'font.family': 'sans-serif',
        'font.sans-serif': ['Arial', 'Helvetica'],
        'font.size': 6,
        'axes.labelsize': 6,
        'axes.titlesize': 6,
        'xtick.labelsize': 6,
        'ytick.labelsize': 6,
        'legend.fontsize': 6,

        # Line weights: 0.25pt for publication
        'axes.linewidth': 0.25,
        'xtick.major.width': 0.25,
        'ytick.major.width': 0.25,
        'xtick.major.size': 2,
        'ytick.major.size': 2,

        # Minimal padding
        'axes.labelpad': 1,
        'xtick.major.pad': 1,
        'ytick.major.pad': 1,

        # Clean appearance
        'axes.spines.top': False,
        'axes.spines.right': False,
        'axes.grid': False,
        'axes.axisbelow': True,
        'axes.edgecolor': 'black',
        'axes.labelcolor': 'black',
        'legend.frameon': False,

        # Figure defaults
        'figure.dpi': 100,
        'figure.facecolor': 'white',
        'figure.constrained_layout.use': True,

        # Line defaults
        'lines.linewidth': 1.2,
        'lines.markersize': 3,
        'lines.markeredgewidth': 0.4,

        # Export defaults
        'savefig.dpi': 600,
        'savefig.format': 'pdf',
        'savefig.transparent': True,
        'savefig.facecolor': 'none',
        'savefig.edgecolor': 'none',

        # Image defaults
        'image.cmap': 'viridis',
    }

    mpl.rcParams.update(style)


def check_figure_size(fig, journal: str = 'cell',
                      width: str = 'double') -> dict:
    """
    Validate figure dimensions against journal specifications.

    Parameters
    ----------
    fig : matplotlib.figure.Figure
    journal : str
        Journal name (cell, nature, science, plos, acs).
    width : str
        Column width: 'single' or 'double'.

    Returns
    -------
    dict with keys: width_mm, height_mm, target_mm, compliant, message
    """
    journal = journal.lower()
    specs = JOURNAL_SPECS.get(journal, JOURNAL_SPECS['cell'])

    w_in, h_in = fig.get_size_inches()
    w_mm = w_in * 25.4
    h_mm = h_in * 25.4
    target_mm = specs[width] if width in specs else specs['double']
    max_h = specs['max_height']

    tolerance = 5  # mm
    w_ok = abs(w_mm - target_mm) < tolerance
    h_ok = h_mm <= max_h

    result = {
        'width_mm': round(w_mm, 1),
        'height_mm': round(h_mm, 1),
        'target_mm': target_mm,
        'max_height_mm': max_h,
        'width_ok': w_ok,
        'height_ok': h_ok,
        'compliant': w_ok and h_ok,
    }

    status = 'PASS' if result['compliant'] else 'FAIL'
    print(f"Figure size check ({journal.upper()} {width}): {status}")
    print(f"  Actual:  {w_mm:.1f} x {h_mm:.1f} mm")
    print(f"  Target:  {target_mm} mm wide, max {max_h} mm tall")
    if not w_ok:
        print(f"  WARNING: Width {w_mm:.1f} mm != {target_mm} mm")
    if not h_ok:
        print(f"  WARNING: Height {h_mm:.1f} mm > {max_h} mm max")

    return result


def save_figure(fig, name: str, output_dir: str = 'figures',
                formats: Optional[List[str]] = None) -> List[Path]:
    """
    Save figure as PDF + SVG with transparent background.

    Refuses PNG. Adds provenance metadata as PDF keyword.

    Parameters
    ----------
    fig : matplotlib.figure.Figure
    name : str
        Base filename without extension.
    output_dir : str
        Directory to save into.
    formats : list of str, optional
        Override formats. Default: ['pdf', 'svg'].

    Returns
    -------
    list of Path : saved file paths
    """
    if formats is None:
        formats = ['pdf', 'svg']

    # Refuse PNG
    if 'png' in formats:
        print("WARNING: PNG removed from export formats. "
              "Use PDF + SVG for publication figures.")
        formats = [f for f in formats if f != 'png']

    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    saved = []
    for fmt in formats:
        path = out / f"{name}.{fmt}"
        fig.savefig(path, format=fmt,
                    transparent=True,
                    edgecolor='none')
        saved.append(path)
        print(f"  Saved: {path}")

    return saved
```

---

## 13. SCRIPT TEMPLATE

Every new figure script should follow this skeleton:

```python
#!/usr/bin/env python3
"""Figure N: [description]. Generated YYYY-MM-DD."""

import sys, os
import numpy as np
import matplotlib.pyplot as plt

# Project imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from tara_style import apply_tara_style, check_figure_size, save_figure
from palette import (OCEAN_CMAP, DIVERGING_CMAP, get_categorical_colors,
                     BASIN_COLORS, LINEAGE_COLORS)

# ---------- style ----------
apply_tara_style()

# ---------- data ----------
# Load real data only -- never synthesize
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

## 14. DATA-DENSE MULTI-PANEL FIGURES (>8 panels)

Lessons learned from building 10+ panel composite figures. These override simpler defaults above.

### Planning Protocol

**MANDATORY: Present a numbered-row ASCII layout grid BEFORE writing any code.** Use 1-based row numbering (Row 1, Row 2, ...). Get explicit user approval before proceeding.

```
Row 1: [A cluster-size] [B prevalence] [C coupling] [D scatter]
Row 2: [E dark-frac] [F violins] [G sig-rates]
Row 3: [H ──── pLDDT profiles (full width) ────]
Row 4: [I Foldseek] [J violins] [K fold-enrichment]
```

### Panel Axes Tracking

**NEVER rely on `fig.get_axes()` ordering for panel labels.** Colorbars, insets, and shared axes insert extra axes objects that shift indices unpredictably. Instead, collect panel axes explicitly as you create them:

```python
panel_axes = []
for i, draw_fn in enumerate([draw_a, draw_b, draw_c, draw_d]):
    ax = fig.add_subplot(gs[0, i])
    draw_fn(ax)
    panel_axes.append(ax)

# Later — labels go on exactly these axes, in order
for letter, ax in zip('ABCD', panel_axes):
    ax.text(-0.12, 1.08, letter, ...)
```

### Full-Width Panel Label Alignment

A panel label at `-0.12` in `transAxes` on a full-width panel is much further left in absolute terms than on a quarter-width panel. Align full-width labels with the other rows using figure coordinates:

```python
ax_a_bbox = panel_axes[0].get_position()
label_x_fig = ax_a_bbox.x0 - 0.02

# For the full-width panel:
ax_pos = ax_fullwidth.get_position()
x_axes = (label_x_fig - ax_pos.x0) / ax_pos.width
ax_fullwidth.text(x_axes, 1.08, 'H', transform=ax_fullwidth.transAxes, ...)
```

### Row Height Ratios

Start compact — you can always add space, but excess whitespace between rows wastes the data-to-ink ratio. Rules of thumb for a 4-row figure:

| Row type | Height ratio |
|---|---|
| 4-panel row (charts/bars) | 0.19–0.22 |
| 3-panel row (wider panels) | 0.19–0.22 |
| Full-width compact (heatmap, profiles) | 0.12–0.16 |
| 3-panel row with tall content (heatmap + violins) | 0.24–0.27 |

Use `hspace=0.28` for tight but readable inter-row gaps. Default `hspace=0.35+` wastes too much vertical space.

### Heterogeneous Row Widths

When rows have different numbers of panels (e.g., Row 1 has 4, Row 2 has 3), each panel in the 3-panel row is ~33% wider. This makes text appear proportionally smaller even though the absolute point size is identical. This is a visual consistency issue, not a bug. Accept it or constrain 3-panel rows with `width_ratios` that don't fill the full width.

### Heatmap Orientation by Context

| Context | Orientation | Why |
|---|---|---|
| Full-width row | Transposed (databases=rows, domains=cols) | Fits the aspect ratio |
| Narrow panel in multi-panel row | Original (domains=rows, databases=cols) | Tall-narrow fits better |

### Iteration Workflow

For data-dense figures, expect 4–8 render cycles. The workflow is:
1. Get layout approved (ASCII grid)
2. First render — check structure, not details
3. Fix overlaps, label collisions, legend placement
4. Tighten spacing (reduce row heights, hspace)
5. Final validation

**Update `main.tex` includegraphics path AND compile with `tectonic` after each iteration** so the user can review in `main.pdf`, not a standalone PDF viewer.

---

*Artist mode v2 is now active. Every figure produced in this session will conform to these standards. No exceptions.*
