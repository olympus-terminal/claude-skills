---
description: Enter artist mode for publication-quality visualization
---

# ARTIST MODE ACTIVATED

You are now operating in **artist mode**. Every pixel justifies its existence. Spatial awareness is paramount. These are binding rules, not suggestions.

---

## 1. UNIVERSAL DESIGN LAWS (all tools)

These apply to EVERY visualization regardless of whether it uses matplotlib, TikZ, or any other tool.

### Spatial Hierarchy
- Padding between nested elements MUST decrease inward (outer margin > panel gap > label pad > tick pad)
- Outer figure margins: handled by `bbox_inches='tight'`
- Panel gaps: `hspace/wspace = 0.02`
- Label pad: `1pt`
- Tick pad: `1pt`

### Anti-Overlap Mandate
- **NO text may touch any other element** — not other text, not axes, not data points, not borders, not colorbars
- This is the #1 rejection reason for journal figures
- Minimum clearance: 1pt between any text element and any other figure element
- After placing text, mentally trace a 1pt bounding box around it — if it intersects anything, fix it

### Breathing Room
| Element pair | Minimum clearance |
|---|---|
| Text to text | 1pt |
| Text to axis line | 1pt (via labelpad/tickpad) |
| Text to data (bars, points) | 2pt |
| Panel to panel | 0.02 in figure fraction |
| Colorbar to heatmap | 0.008 width fraction gap |

### Data-to-Ink Ratio
- Target: >70% of figure area showing data
- Remove all chart junk: unnecessary gridlines, borders, backgrounds, legends that duplicate axis info
- Fill the entire figure area — no large empty regions

### Visual Weight Balance
- Distribute visual density evenly across the figure
- A dendrogram on the left balances annotation tracks on the right
- A colorbar should be compact (0.008 width fraction), never dominant

---

## 2. TYPOGRAPHY LAW

**ALL text: 6pt Arial. No exceptions.**

```python
import matplotlib as mpl

# CRITICAL: Journal font compatibility
mpl.rcParams['pdf.fonttype'] = 42      # TrueType in PDF (Illustrator-editable)
mpl.rcParams['ps.fonttype'] = 42       # TrueType in PostScript
mpl.rcParams['svg.fonttype'] = 'none'  # Embed fonts in SVG

# Font configuration - ALL 6pt Arial
mpl.rcParams['font.family'] = 'sans-serif'
mpl.rcParams['font.sans-serif'] = ['Arial', 'Helvetica']
mpl.rcParams['font.size'] = 6
mpl.rcParams['axes.labelsize'] = 6
mpl.rcParams['axes.titlesize'] = 6
mpl.rcParams['xtick.labelsize'] = 6
mpl.rcParams['ytick.labelsize'] = 6
mpl.rcParams['legend.fontsize'] = 6
```

### TikZ Typography
- Use `\fontsize{6}{7.2}\selectfont\sffamily` for all node text
- Document preamble: `\usepackage[scaled=0.9]{helvet}` with `\renewcommand*\familydefault{\sfdefault}`
- Font sizing via `Scale=0.5` on a 12pt base document gives 6pt effective

### Text Content Rules
- **NO unicode subscripts** — write `Log2` not `Log₂`, write `CO2` not `CO₂`
- Abbreviate aggressively in dense figures: `"2119"` instead of `"PF02119"`
- Use sparse labeling: every Nth item when >20 items on an axis

---

## 3. COLOR SYSTEMS

Three mandatory palette systems. NEVER use default matplotlib colors, rainbow/jet colormaps, or arbitrary colors.

### Blackbody Palette (abundance, expression, intensity data)
```python
# White → black → red → orange → yellow
blackbody_colors = [
    (1.0, 1.0, 1.0),    # White (NaN/zero)
    (0.95, 0.95, 0.95),  # Very light gray
    (0.1, 0.1, 0.1),     # Near black
    (0.4, 0.0, 0.0),     # Dark red
    (0.7, 0.0, 0.0),     # Red
    (0.9, 0.2, 0.0),     # Orange-red
    (1.0, 0.5, 0.0),     # Orange
    (1.0, 0.7, 0.0),     # Yellow-orange
    (1.0, 0.9, 0.2),     # Yellow
]
```

### Diverging Palette (correlations, z-scores, fold changes)
```python
# Deep blue → white → deep red
diverging_colors = [
    (0.0, 0.3, 0.7),    # Deep blue (negative)
    (0.3, 0.5, 0.9),    # Medium blue
    (0.7, 0.8, 0.95),   # Light blue
    (0.95, 0.95, 0.95), # Near white (zero)
    (0.95, 0.8, 0.7),   # Light red
    (0.9, 0.4, 0.3),    # Medium red
    (0.7, 0.1, 0.1),    # Deep red (positive)
]
```

### MODIS Ocean Categorical Palette (TikZ diagrams, process flows)
```
Data sources:    modisDeepLight    RGB(198,219,239)  — blue
Processing:      modisTealLight    RGB(204,236,239)  — teal
ML/Analysis:     modisChloroLight  RGB(232,245,208)  — green
Environmental:   modisThermalLight RGB(255,237,204)  — warm orange
Validation:      modisVioletLight  RGB(229,216,246)  — violet
```
Dark accent variants for borders/text:
```
modisDeep    RGB(8,48,107)
modisTeal    RGB(0,109,119)
modisChloro  RGB(120,147,60)
modisThermal RGB(204,102,0)
modisViolet  RGB(106,61,154)
```

### Color Rules
- **White = missing/NaN** — always, in every context
- Colorblind-safe: all palettes above pass deuteranopia simulation
- Grayscale-distinguishable: patterns must survive B&W conversion

---

## 4. ANTI-OVERLAP PROTOCOL

This is the core spatial awareness system. Apply these strategies in order of preference.

### Strategy 1: Rotation
- Rotate x-axis labels 45° when >6 labels
- Use `ha='right', rotation_mode='anchor'` for matplotlib
- For TikZ: `rotate=45, anchor=east`

### Strategy 2: Sparse Labeling
- When >20 items on an axis, label every Nth item
- Show every 5th PFAM, every 10th sample, etc.
- `ax.set_xticks(ticks[::N])`

### Strategy 3: Abbreviation
- Strip common prefixes: `"PF02119"` → `"2119"`
- Truncate long names to first 15 characters + `...`
- Use taxa as colored bars instead of text labels

### Strategy 4: adjustText Library
- For scatter plots with point labels, always use `adjustText`:
```python
from adjustText import adjust_text
texts = [ax.text(x, y, label, fontsize=6) for x, y, label in zip(xs, ys, labels)]
adjust_text(texts, arrowprops=dict(arrowstyle='-', color='gray', lw=0.25))
```

### Strategy 5: Explicit Padding (never rely on defaults)
```python
# Matplotlib
mpl.rcParams['axes.labelpad'] = 1
mpl.rcParams['xtick.major.pad'] = 1
mpl.rcParams['ytick.major.pad'] = 1
```
```tex
% TikZ
inner xsep=5pt,
inner ysep=3pt
```

### Strategy 6: Post-Generation Overlap Detection
```python
# After drawing, check for overlapping text elements
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

### Full rcParams Configuration
Apply this at the top of EVERY matplotlib script:
```python
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# Journal font compatibility
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42
mpl.rcParams['svg.fonttype'] = 'none'

# ALL 6pt Arial
mpl.rcParams['font.family'] = 'sans-serif'
mpl.rcParams['font.sans-serif'] = ['Arial', 'Helvetica']
mpl.rcParams['font.size'] = 6
mpl.rcParams['axes.labelsize'] = 6
mpl.rcParams['axes.titlesize'] = 6
mpl.rcParams['xtick.labelsize'] = 6
mpl.rcParams['ytick.labelsize'] = 6
mpl.rcParams['legend.fontsize'] = 6

# Line weights — 0.25pt for publication
mpl.rcParams['axes.linewidth'] = 0.25
mpl.rcParams['xtick.major.width'] = 0.25
mpl.rcParams['ytick.major.width'] = 0.25
mpl.rcParams['xtick.major.size'] = 2
mpl.rcParams['ytick.major.size'] = 2

# Minimal padding
mpl.rcParams['axes.labelpad'] = 1
mpl.rcParams['xtick.major.pad'] = 1
mpl.rcParams['ytick.major.pad'] = 1
```

### GridSpec Patterns

#### Standard biclustering layout (6-row, 5-col):
```python
gs = gridspec.GridSpec(6, 5, figure=fig,
    height_ratios=[0.5, 0.8, 0.3, 4, 0.2, 0.3],
    width_ratios=[0.15, 0.5, 3, 0.3, 0.15],
    hspace=0.02, wspace=0.02)
# Row 0: column dendrogram
# Row 1: environmental variable tracks
# Row 2: metadata color bars
# Row 3: MAIN HEATMAP (dominates)
# Row 4: colorbar strip
# Row 5: legend
# Col 0: row dendrogram
# Col 1: row annotation bars
# Col 2: MAIN HEATMAP
# Col 3: statistics side panel
# Col 4: additional annotations
```

#### Two-panel with side statistics:
```python
gs = gridspec.GridSpec(1, 3, figure=fig,
    width_ratios=[3, 0.1, 1],
    wspace=0.02)
# Col 0: main panel, Col 1: gap, Col 2: statistics
```

### Heatmap Recipe
```python
im = ax.imshow(data, aspect='auto', cmap=custom_cmap,
               interpolation='nearest')
ax.set_xticks(range(0, n_cols, label_every_n))
ax.set_yticks(range(0, n_rows, label_every_n))
# Grid lines: subtle
for i in range(0, n_rows, 5):
    ax.axhline(i - 0.5, color='gray', lw=0.15, alpha=0.2)
```

### Colorbar Recipe
```python
cbar = fig.colorbar(im, ax=ax, fraction=0.008, pad=0.01, aspect=30)
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

### Export — MANDATORY
```python
# ONLY vector formats. NEVER PNG.
for fmt in ['pdf', 'svg']:
    fig.savefig(f'figure_name.{fmt}', format=fmt,
                bbox_inches='tight',
                transparent=True,  # CRITICAL: transparent background
                edgecolor='none')
```

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
mainArrow/.style={
    ->, >={Stealth[length=2mm,width=1.5mm]},
    line width=0.6pt, black
},
branchArrow/.style={
    ->, >={Stealth[length=1.6mm,width=1.2mm]},
    line width=0.4pt, black!60, densely dashed
},
mergeArrow/.style={
    ->, >={Stealth[length=2mm,width=1.5mm]},
    line width=0.6pt, modisThermal
}
```

### Spacing Table
| Element pair | Distance |
|---|---|
| node distance (default) | 0.12cm |
| Title to first box | `below=0.2cm` |
| Between sequential stages | `below=0.1cm` |
| Parallel branch offset | `right=2.5cm` |
| Inner padding (x) | 5pt |
| Inner padding (y) | 3pt |
| Box rounded corners | 2pt |

### Line Weights
| Element | Width |
|---|---|
| Box borders | 0.25pt |
| Main arrows | 0.6pt |
| Branch arrows | 0.4pt |
| Arrow heads (main) | length=2mm, width=1.5mm |
| Arrow heads (branch) | length=1.6mm, width=1.2mm |

### Compilation
```bash
tectonic filename.tex
# Run twice if references are used
# Verify: pdfinfo output.pdf
```

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
- Side panels: aligned exactly to main heatmap rows
- Top panels: aligned exactly to main heatmap columns
- Shared axes ensure pixel-perfect alignment

### Space-Saving Techniques
1. **Shared axes** — multiple panels use same x/y coordinates
2. **Inline legends** — color bars AS data tracks, not separate boxes
3. **Sparse labeling** — every 5th PFAM labeled
4. **Compact colorbars** — 0.008 width fraction
5. **Merged annotations** — taxa as colored bar, not text labels

### TikZ Pipeline Layout
- Main flow: top-to-bottom (stages connected by `mainArrow`)
- Parallel branches: offset to the right (connected by `branchArrow`)
- Merge points: orange `mergeArrow` when data streams converge
- Legend at bottom with box-type and arrow-type explanations
- Build incrementally: compile after adding each stage

---

## 8. MANDATORY POST-CREATION VALIDATION

After EVERY figure is generated, perform ALL of these checks before reporting completion:

### Checklist
1. **View the figure** — Use Read tool on the output file (PDF/SVG)
2. **Text overlap check** — Inspect at effective 400% zoom. NO text touching any other element
3. **Font verification** — ALL text must be 6pt Arial. NO variation in sizes
4. **Transparent background** — Confirm `transparent=True` was used (no white rectangle behind figure)
5. **Vector format** — Output must be PDF and/or SVG. NEVER PNG for publication figures
6. **Data-to-ink ratio** — >70% of figure area should be data, not decoration
7. **Color verification** — Uses project palettes, not matplotlib defaults. White for NaN
8. **Line weight check** — Axes/ticks at 0.25pt, not matplotlib default 0.8pt

### If ANY check fails:
- Fix the issue immediately
- Re-export the figure
- Re-run the entire checklist
- Do NOT report completion until all checks pass

---

## 9. COMMON FAILURE MODES

| Failure | Root Cause | Fix |
|---|---|---|
| Text overlapping axes | Default labelpad too small or too large | Set `labelpad=1`, `tickpad=1` explicitly |
| Labels overlapping each other | Too many labels at full density | Sparse labeling (every Nth) or rotation 45deg |
| Fonts not 6pt | Forgot rcParams or mixed sizes | Set ALL font rcParams at script top |
| White background in PDF | Used `facecolor='white'` or omitted transparent | `transparent=True` in savefig |
| Blurry figure | Saved as PNG | Save as PDF + SVG only |
| Default ugly colors | Forgot custom colormap | Apply blackbody/diverging palette |
| TikZ text overlap | Relied on default positioning | Use explicit `inner sep`, position with `calc` |
| Too much detail at once (TikZ) | Added all elements before compiling | Build incrementally, compile after each addition |
| TikZ default spacing | Used `node distance` without explicit override | Set spacing explicitly for every `below=`/`right=` |
| Full-page PDF from TikZ | Missing `border=` in documentclass | Use `\documentclass[tikz,border=3pt]{standalone}` |
| LaTeX float issues | Used `[H]` float specifier | Use `[!htb]` instead |
| Colorbar dominates figure | Default colorbar size | `fraction=0.008, pad=0.01, aspect=30` |
| Unicode in labels | Used subscript characters | Write `Log2` not `Log_2`, `CO2` not `CO_2` |
| Uneditable fonts in PDF | Wrong fonttype | `mpl.rcParams['pdf.fonttype'] = 42` |

---

## 10. FIGURE SIZE STANDARDS

| Context | Width | Notes |
|---|---|---|
| Single column | 3.5 in (89mm) | Nature, Science, Cell |
| 1.5 column | 5.5 in (140mm) | Some journals |
| Double column | 7 in (178mm) | Full-width figures |
| Full page | 8.27 x 11.69 in (A4) | Supplementary |

Always check the target journal's specific requirements.

---

*Artist mode is now active. Every figure produced in this session will conform to these standards. No exceptions.*
