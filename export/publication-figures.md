# Publication Figures (Artist Mode)

Binding rules for publication-quality scientific figures. Covers matplotlib, TikZ, seaborn, and SVG workflows.

---

## 1. The Render-Check-Fix Loop (Mandatory)

Every figure MUST go through this cycle. Do NOT declare a figure "done" after one render.

```
1. RENDER  ->  Generate the figure at final DPI (300+) and target physical dimensions
2. VIEW    ->  Inspect the output image
3. MEASURE ->  Run programmatic overlap detection
4. CROP    ->  View dense regions individually (axis labels, legends, colorbars)
5. FIX     ->  Apply corrections in code
6. REPEAT  ->  Go back to step 1. Minimum 2 full cycles.
```

### Programmatic Validation (Non-Negotiable)

Run this after every render:

```python
def validate_figure(fig):
    renderer = fig.canvas.get_renderer()
    issues = []
    all_texts = list(fig.texts)
    for ax in fig.get_axes():
        all_texts.extend(ax.texts)
        all_texts.append(ax.title)
        all_texts.append(ax.xaxis.label)
        all_texts.append(ax.yaxis.label)
        all_texts.extend(ax.get_xticklabels())
        all_texts.extend(ax.get_yticklabels())
    all_texts = [t for t in all_texts if t.get_text().strip()]
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
    for t in all_texts:
        size = t.get_fontsize()
        if size > 6.5:
            issues.append(f"FONT SIZE {size}pt on '{t.get_text()[:20]}' (must be <=6pt)")
    for t in all_texts:
        weight = t.get_fontproperties().get_weight()
        if weight in ('bold', 'heavy', 700, 800, 900):
            text = t.get_text().strip()
            if len(text) > 1 or not text.isalpha():
                issues.append(f"UNEXPECTED BOLD on '{text[:20]}' (only panel labels may be bold)")
    if issues:
        print(f"VALIDATION FAILED - {len(issues)} issue(s):")
        for issue in issues:
            print(f"  x {issue}")
    else:
        print("VALIDATION PASSED")
    return issues
```

### When to Stop Iterating

- `validate_figure()` returns zero issues, AND
- You have visually inspected the output at least twice, AND
- You have viewed at least one cropped dense region

---

## 2. Universal Design Laws

### Spatial Hierarchy
- Padding MUST decrease inward: outer margin > panel gap > label pad > tick pad
- Aligned layouts: `hspace/wspace = 0.02`
- Heterogeneous multi-panel: use SubFigures + `layout='constrained'` or nested GridSpec with `hspace=0.30-0.40`
- Label pad: 1pt, Tick pad: 1pt

### Anti-Overlap Mandate
NO text may touch any other element. Minimum clearance: 1pt between any text element and any other figure element.

| Element pair | Minimum clearance |
|---|---|
| Text to text | 1pt |
| Text to axis line | 1pt |
| Text to data | 2pt |
| Panel to panel (aligned) | 0.02 figure fraction |
| Panel to panel (heterogeneous) | 0.30-0.40 hspace |

### Data-to-Ink Ratio
Target >70% of figure area showing data. Remove chart junk: unnecessary gridlines, borders, backgrounds, redundant legends.

---

## 3. Typography Law

**ALL text: 6pt Arial. No exceptions.**

```python
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
    'axes.labelpad': 1,
    'xtick.major.pad': 1,
    'ytick.major.pad': 1,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'savefig.dpi': 600,
    'savefig.transparent': True,
}
```

### Panel Labels and Titles
- Panel labels (A, B, C, ...) are the ONLY bold text: 6pt bold Arial
- NO panel titles — titles belong in figure captions
- Position: `ax.text(-0.12, 1.08, letter, transform=ax.transAxes, fontsize=6, fontweight='bold', va='top', ha='left')`

### Text Content Rules
- NO unicode subscripts: write `Log2` not `Log2`, write `CO2` not `CO2`
- Abbreviate aggressively: `"2119"` instead of `"PF02119"`
- Sparse labeling: every Nth item when >20 items on an axis
- NO `fontweight='bold'` except on panel labels

---

## 4. Anti-Overlap Protocol

Apply in order of preference:

1. **Rotation:** 45 degrees for x-axis labels when >6 labels, `ha='right', rotation_mode='anchor'`
2. **Sparse Labeling:** When >20 items, label every Nth: `ax.set_xticks(ticks[::N])`
3. **Abbreviation:** Strip prefixes, truncate to 15 chars
4. **adjustText:** `adjust_text(texts, arrowprops=dict(arrowstyle='-', color='gray', lw=0.25))`
5. **Explicit Padding:** `axes.labelpad=1, xtick.major.pad=1, ytick.major.pad=1`
6. **Post-Generation Detection:** Use `validate_figure()` from Section 1

---

## 5. Color Systems

### Colormap Selection Rules

| Data Type | Colormap |
|-----------|----------|
| Abundance/Counts | Sequential (ocean blues) |
| Performance (R2) | Sequential, NOT diverging |
| Correlations (-1 to +1) | Diverging, centered at zero |
| Categorical groups | Distinct hue palette |

### Color Rules
- White = missing/NaN, always
- Colorblind-safe: all palettes must pass deuteranopia simulation
- Grayscale-distinguishable: patterns must survive B&W conversion
- NEVER use rainbow/jet, default matplotlib tab10, or diverging maps for non-diverging data

### Fallback Colorblind Palette
```python
OKABE_ITO = ['#E69F00', '#56B4E9', '#009E73', '#F0E442',
             '#0072B2', '#D55E00', '#CC79A7', '#000000']
```

---

## 6. Layout Patterns

### Heterogeneous Multi-Panel (SubFigures, preferred)
```python
fig = plt.figure(figsize=(7, 9), layout='constrained')
(row0, row1, row2) = fig.subfigures(3, 1, height_ratios=[1, 1.4, 1])
axs_r0 = row0.subplots(1, 4)
```

### Nested GridSpec (alternative)
```python
fig = plt.figure(figsize=(7, 10))
outer = gridspec.GridSpec(4, 1, figure=fig,
    height_ratios=[1, 1.1, 1.4, 1.0], hspace=0.35)
gs_row0 = gridspec.GridSpecFromSubplotSpec(1, 4,
    subplot_spec=outer[0], wspace=0.30)
```

### Planning Protocol (mandatory for >4 panels)
Present a numbered-row ASCII layout grid BEFORE writing any code. Get user approval.

### Panel Axes Tracking
NEVER rely on `fig.get_axes()` ordering. Colorbars and insets insert extra axes. Collect panel axes explicitly:
```python
panel_axes = []
for i, draw_fn in enumerate([draw_a, draw_b, draw_c]):
    ax = fig.add_subplot(gs[0, i])
    draw_fn(ax)
    panel_axes.append(ax)
```

---

## 7. Export

```python
for fmt in ['pdf', 'svg']:
    fig.savefig(f'figure_name.{fmt}', format=fmt,
                transparent=True, edgecolor='none')
```

NEVER save PNG for publication figures.

Font embedding for Illustrator compatibility:
```python
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42
mpl.rcParams['svg.fonttype'] = 'none'
```

---

## 8. Figure Size Standards

| Context | Width | Notes |
|---|---|---|
| Single column | 3.5 in (89mm) | Nature, Science, Cell |
| 1.5 column | 5.5 in (140mm) | Some journals |
| Double column | 7 in (178mm) | Full-width figures |

| Journal | Single | Double | Max Height |
|---------|--------|--------|------------|
| Nature | 89mm | 183mm | 247mm |
| Science | 55mm | 175mm | 233mm |
| Cell | 85mm | 178mm | 230mm |
| PLOS | 83mm | 173mm | 233mm |

---

## 9. Post-Creation Validation Checklist

| # | Check | Pass Criteria |
|---|-------|---------------|
| 1 | Programmatic validation | Zero issues from `validate_figure()` |
| 2 | View the figure | File renders correctly |
| 3 | Crop-and-zoom | No overlap in dense regions |
| 4 | Font verification | ALL text 6pt Arial |
| 5 | Transparent background | `transparent=True` in savefig |
| 6 | Vector format | PDF and/or SVG, never PNG |
| 7 | Data-to-ink ratio | >70% of area is data |
| 8 | Color verification | Project palettes, white for NaN |
| 9 | Line weight | 0.25pt, not matplotlib default |
| 10 | Figure dimensions | Width matches journal column |

If ANY check fails: fix, re-render, re-validate from #1. Do not report completion until all pass on the same render.

---

## 10. Common Failure Modes

| Failure | Fix |
|---|---|
| Text overlapping axes | `labelpad=1, tickpad=1` |
| Labels overlapping each other | Sparse labeling or 45 deg rotation |
| Fonts not 6pt | Set rcParams at script top |
| White background in PDF | `transparent=True` |
| Blurry figure | PDF + SVG only, never PNG |
| Default ugly colors | Use custom colormap |
| Multi-panel overlap | SubFigures or nested GridSpec |
| Bold text on non-labels | Bold ONLY on panel letters |
| Diverging cmap on non-diverging data | Use sequential |
| Declared victory after one render | Minimum 2 render-check-fix cycles |
