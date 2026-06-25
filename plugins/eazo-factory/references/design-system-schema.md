# design-tokens.json schema

Purpose: stable contract for art direction, tokens, and component-level design constraints.

Rules:
- Use the exact top-level keys shown below.
- `art_direction` must be one of these approved slugs: `matisse-cut-paper`, `bauhaus-playful`, `quiet-editorial`.
- Token values may vary by product, but the shape must remain stable.
- `components` should cover only components required by the selected product capabilities and screens.

```json
{
  "schema_version": "1.0",
  "art_direction": "quiet-editorial",
  "palette": {
    "canvas": "#F6F2EA",
    "surface": "#FFFDFC",
    "ink": "#181512",
    "accent": "#6E8C7A",
    "accent_secondary": "#C9A66B"
  },
  "typography": {
    "display_family": "Cormorant Garamond",
    "body_family": "Inter",
    "scale": {
      "display": "48/52",
      "h1": "32/38",
      "h2": "24/30",
      "body": "16/24",
      "caption": "13/18"
    }
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32
  },
  "radii": {
    "sm": 8,
    "md": 16,
    "lg": 24
  },
  "shadows": {
    "soft": "0 12px 32px rgba(24,21,18,0.10)",
    "focus": "0 0 0 3px rgba(110,140,122,0.28)"
  },
  "illustration": {
    "style": "Layered paper-like abstract forms",
    "density": "Minimal",
    "subjects": ["Breath rhythm", "Calm horizon", "Leaf silhouette"]
  },
  "motion": {
    "pace": "Gentle",
    "durations_ms": {
      "micro": 120,
      "standard": 220,
      "emphasis": 480
    },
    "easing": "ease-out"
  },
  "components": {
    "button": {
      "shape": "Rounded rectangle",
      "padding": "12px 18px",
      "emphasis": "High contrast fill only for primary action"
    },
    "card": {
      "surface": "Plain",
      "border": "1px solid rgba(24,21,18,0.08)"
    }
  }
}
```
