# Video Assets

Place hero videos here in WebP format.

## Required Files

- `cartomix-hero.webp` - Main hero video (default)
- `cartomix-hero-dark.webp` - Dark mode version
- `cartomix-hero-light.webp` - Light mode version

## Recording Guidelines

See [../demo/DEMO_PROCEDURES.md](../demo/DEMO_PROCEDURES.md) for:
- Screen recording setup
- Video capture tips
- WebP conversion commands

## Conversion Command

```bash
# High quality hero video (10-15 seconds)
ffmpeg -i demo.mov -vf "fps=30,scale=1280:-1" -loop 0 -quality 80 cartomix-hero.webp

# File size target: < 5MB
```
