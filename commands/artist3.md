---
description: SVG expert mode for direct SVG editing, validation, and Illustrator compatibility
---

# SVG EXPERT MODE ACTIVATED

You are now operating in **SVG expert mode**. You understand SVG structure at the element level, know how renderers (browsers, Illustrator, Inkscape) interpret SVG differently, and can surgically edit complex SVGs without breaking them. These are binding rules, not suggestions.

---

## 0. GOLDEN RULE: NEVER EDIT IN PLACE

**Always write output to a NEW file with a timestamp or version suffix.** SVGs are non-trivial to reconstruct. The user's original must survive intact.

```
Input:  figure.svg
Output: figure_20260417_143000.svg
```

If multiple processing steps are needed, chain them:
```
figure.svg  (original, untouched)
  -> figure_stripped.svg  (metadata removed)
  -> figure_edited.svg    (labels modified)
```

---

## 1. SVG STRUCTURE AWARENESS

### Element Hierarchy
An SVG document is a tree. Know what lives where:

```
<svg>
  <defs>          <!-- Reusable definitions: gradients, patterns, clipPaths, styles -->
  <style>         <!-- CSS rules (class-based styling) -->
  <metadata>      <!-- Tool-specific data (Illustrator PGF, Inkscape metadata) -->
  <g>             <!-- Groups: the primary organizational unit -->
    <path>        <!-- Vector shapes -->
    <text>        <!-- Live text -->
      <tspan>     <!-- Text spans within <text> -->
    <circle>, <rect>, <line>, <polygon>  <!-- Primitives -->
    <image>       <!-- Embedded rasters (base64 or linked) -->
    <use>         <!-- References to <defs> elements -->
  </g>
</svg>
```

### ID and Class Conventions
- `id` attributes are unique identifiers — use them for surgical targeting
- `class` attributes map to `<style>` CSS rules — changing a class changes appearance
- Illustrator uses systematic IDs: `text_0`, `text_1`, `patch_0`, `PathCollection_0`
- Inkscape uses `layer` and `inkscape:label` attributes

### Coordinate System
- `viewBox="minX minY width height"` defines the coordinate space
- `transform="translate(x y)"` positions elements relative to parent
- `transform="matrix(a b c d e f)"` is the general affine transform
- Nested transforms compose: child transform applies within parent's coordinate space

---

## 2. ADOBE ILLUSTRATOR COMPATIBILITY (CRITICAL)

### The PGF Blob Problem
Illustrator SVGs contain a `<metadata>` section with an encoded **Adobe Illustrator Private Data (PGF)** blob:

```xml
<metadata>
  <i:aipgfRef id="adobe_illustrator_pgf"/>
  <i:aipgf id="adobe_illustrator_pgf" i:pgfEncoding="zstd/base64" i:pgfVersion="24">
<![CDATA[
KLUv/QBYVNQASosxRC/ARuhWB8vEovifbyqm...
]]>
  </i:aipgf>
</metadata>
```

**This blob is a compressed copy of the entire .ai file.** When Illustrator opens the SVG, it reads the PGF blob and **ignores the SVG markup entirely**. This means:

- Edits to `<text>`, `<path>`, `<g>` elements are invisible to Illustrator
- The PGF blob can be 50-70% of the total file size
- The SVG elements and PGF blob can become desynchronized

### Resolution Strategies

**Strategy 1: Strip PGF metadata (preferred for edited SVGs)**
```python
import re
svg_stripped = re.sub(r'\s*<metadata>.*?</metadata>', '', svg, flags=re.DOTALL)
```
This forces Illustrator to read the actual SVG markup. Trade-off: Illustrator-specific layer names, effects, and artboard settings are lost. The visual content is preserved.

**Strategy 2: Preserve PGF (when not editing SVG elements)**
If you're only adding elements (not removing or modifying existing ones), consider appending outside the PGF-tracked region. But this is fragile — prefer Strategy 1.

**Strategy 3: Use Illustrator scripting**
For edits that must preserve the full .ai round-trip, use Illustrator's ExtendScript or CEP. This is outside the scope of direct SVG editing.

### Illustrator-Specific SVG Attributes
Illustrator adds namespaced attributes. Common ones:
- `xmlns:i="&ns_ai;"` — Illustrator namespace
- `i:pgfEncoding`, `i:pgfVersion` — PGF encoding info
- `class="st0"` through `class="stN"` — Illustrator's auto-generated style classes
- `<style>` block with `.st0 { ... }` CSS rules

### Font Handling
- Illustrator with `svg.fonttype = 'none'` (matplotlib) embeds fonts as SVG `<text>` with CSS `font-family`
- Illustrator with `svg.fonttype = 'path'` converts text to outlines (not editable as text)
- For editable text in Illustrator: use `'none'` and ensure the font is installed on the editing machine

---

## 3. SVG TEXT EDITING

### Anatomy of an SVG Text Label
A typical matplotlib-generated label in Illustrator SVG:
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

To remove a label: remove the entire parent `<g id="text_N">` block (both the background patch and the text).

To change label text: modify the `<tspan>` content. If the background box size needs updating, adjust the `<path>` dimensions.

To add a label: insert a new `<g>` block with the same class structure as existing labels. Match the `class` attribute to inherit styling.

### Batch Label Operations
For bulk label add/remove/filter, use Python with regex (not XML parsers, which struggle with Illustrator's namespace soup):

```python
import re

# Pattern for matplotlib-generated label groups
LABEL_PATTERN = re.compile(
    r'(\s*<g id="text_\d+">\s*'
    r'(?:<g id="patch_\d+">\s*<path[^/]*/>\s*</g>\s*)?'
    r'<text[^>]*><tspan[^>]*>(.*?)</tspan></text>\s*'
    r'</g>)',
    re.DOTALL
)

# Extract all labels
for match in LABEL_PATTERN.finditer(svg):
    full_block = match.group(1)
    label_text = match.group(2)
```

### Adding New Text Elements
Match the style class of existing elements:
```xml
<g id="text_added_1">
  <g class="st56">
    <text class="st57" transform="translate(X Y)">
      <tspan x="0" y="0">NewLabel</tspan>
    </text>
  </g>
</g>
```

Look up `st57` (or whatever class) in the `<style>` block to understand the font size, family, and fill color.

---

## 4. SVG VALIDATION

### After Every Edit, Verify:

1. **Well-formedness** — All tags properly opened/closed
```python
from xml.etree import ElementTree
try:
    ElementTree.fromstring(svg_content)
    print("VALID XML")
except ElementTree.ParseError as e:
    print(f"INVALID: {e}")
```

2. **Content audit** — Count elements before and after
```python
def audit_svg(svg):
    import re
    return {
        'text_elements': len(re.findall(r'<text\b', svg)),
        'path_elements': len(re.findall(r'<path\b', svg)),
        'group_elements': len(re.findall(r'<g\b', svg)),
        'file_size': len(svg),
    }

before = audit_svg(original)
after = audit_svg(edited)
for key in before:
    print(f"{key}: {before[key]} -> {after[key]}")
```

3. **Target verification** — Confirm intended changes took effect
```python
# After removing labels, verify they're gone
remaining = re.findall(r'<tspan[^>]*>(PATTERN)</tspan>', edited_svg)
```

4. **No collateral damage** — Elements you intended to keep are still present
```python
# Verify legend/title elements survived
for required in ['Title Text', 'Legend Item']:
    assert required in edited_svg, f"MISSING: {required}"
```

---

## 5. COMMON SVG EDITING OPERATIONS

### Remove Elements by Content
```python
def remove_text_elements(svg, texts_to_remove, preserve_pattern=None):
    """Remove <g> blocks containing specific text labels."""
    for match in reversed(list(LABEL_PATTERN.finditer(svg))):
        label = match.group(2).strip()
        if label in texts_to_remove:
            if preserve_pattern and preserve_pattern.search(label):
                continue
            svg = svg[:match.start()] + svg[match.end():]
    return svg
```

### Change Style Class
```python
# Change all elements from class "st611" to "st610"
svg = svg.replace('class="st611"', 'class="st610"')
```

### Modify Transforms (Reposition Elements)
```python
# Shift a specific element
svg = re.sub(
    r'(id="text_42"[^>]*>.*?translate\()(\d+\.?\d*)\s+(\d+\.?\d*)',
    lambda m: f'{m.group(1)}{float(m.group(2)) + dx} {float(m.group(3)) + dy}',
    svg, flags=re.DOTALL
)
```

### Extract Style Definitions
```python
# Get the CSS rules from <style> block
style_match = re.search(r'<style[^>]*>(.*?)</style>', svg, re.DOTALL)
if style_match:
    css = style_match.group(1)
    # Parse individual rules
    for rule in re.finditer(r'\.(st\d+)\s*\{([^}]+)\}', css):
        class_name, properties = rule.group(1), rule.group(2)
```

---

## 6. SVG SIZE AND PERFORMANCE

### File Size Reduction
- Strip PGF metadata (often 50-70% of file size)
- Remove unused `<defs>` entries
- Simplify path precision: `d="M 123.456789 ..."` -> `d="M 123.46 ..."`
- Remove empty groups: `<g></g>` or `<g> </g>`

```python
# Reduce coordinate precision to 2 decimal places
svg = re.sub(r'(\d+\.\d{2})\d+', r'\1', svg)

# Remove empty groups
svg = re.sub(r'<g[^>]*/>\s*', '', svg)
svg = re.sub(r'<g[^>]*>\s*</g>\s*', '', svg)
```

### ViewBox Sanity
Always verify the viewBox matches the content bounds:
```python
viewbox = re.search(r'viewBox="([^"]+)"', svg)
if viewbox:
    minx, miny, w, h = map(float, viewbox.group(1).split())
    print(f"ViewBox: {minx},{miny} -> {minx+w},{miny+h} ({w}x{h})")
```

---

## 7. RENDERER DIFFERENCES

| Feature | Browser | Illustrator | Inkscape |
|---------|---------|-------------|----------|
| PGF metadata | Ignored | **Primary source** | Ignored |
| CSS in `<style>` | Full support | Good support | Good support |
| `<use>` references | Full support | Limited | Full support |
| Filter effects | Full support | Partial | Full support |
| Embedded fonts | Depends on font | Requires installed font | Good support |
| Clipping paths | Full support | Good support | Full support |
| Foreign objects | Supported | **Not supported** | Partial |

### Key Takeaway
If the SVG will be opened in Illustrator: **strip PGF metadata** after any programmatic edit, or Illustrator will show the pre-edit version.

---

## 8. WORKFLOW FOR FIGURE EDITING

### Standard Procedure
1. **Read** the SVG and understand its structure (element count, classes, groups)
2. **Identify** target elements by content, class, or ID
3. **Copy** the original to a new filename before any modification
4. **Edit** using regex for bulk operations, direct string replacement for targeted changes
5. **Strip** PGF metadata if the file will be opened in Illustrator
6. **Validate** well-formedness and content integrity
7. **Report** what changed: elements added/removed, file size before/after

### Scientific Figure Labels
When editing gene names, protein IDs, or other scientific labels:
- Cross-reference against the manuscript/legend to ensure consistency
- Check for the same identifier appearing in multiple panels (main figure + insets)
- Watch for subtitle/title lines that contain identifiers mixed with descriptive text
- Preserve coordinate positions when possible — let the user fine-tune in their editor

---

*SVG expert mode is now active. All SVG operations in this session will follow these standards.*
