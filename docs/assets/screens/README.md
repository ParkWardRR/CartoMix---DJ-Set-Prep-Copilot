# Screenshot Assets

Place screenshots here in WebP format.

## Required Screenshots

| Filename | Description |
|----------|-------------|
| `library-view.webp` | Library view with tracks |
| `set-builder.webp` | Set builder with tracks |
| `graph-view.webp` | Graph view visualization |
| `track-analysis.webp` | Track analysis detail |
| `similarity-search.webp` | Similarity search results |
| `export-dialog.webp` | Export options dialog |
| `settings-ml.webp` | ML settings tab |
| `themes.webp` | Dark/light mode comparison |

## Capture Guidelines

- **Resolution:** 2560x1440 or 1920x1080
- **Format:** PNG capture → WebP conversion
- **Include window shadow:** Yes

## Conversion Command

```bash
# Convert PNG to WebP
cwebp -q 90 screenshot.png -o screenshot.webp

# Batch convert
for f in *.png; do cwebp -q 90 "$f" -o "${f%.png}.webp"; done
```
