# Eazo template precedence policy

Precedence order:

1. Checked-out template AGENTS.md
2. Checked-out template implementation and package scripts
3. Checked-out template .env.example and deployment configuration
4. Plugin references
5. General framework conventions

Required reads before implementation:
- `AGENTS.md`
- `package.json`
- `.env.example`
- `src/app/layout.tsx`
- only the capability examples selected in `product-spec.json`

Policy:
- The canonical starter template is `https://github.com/EazoAI/eazo-creator-nextjs-template.git` on branch `main`.
- Follow higher-precedence sources when guidance conflicts.
- Treat the checked-out template as the source of truth for runnable implementation details, scripts, and deployment wiring.
- Use plugin references to constrain artifact shapes, review policy, and art direction when the template does not specify them.
- Do not import unused capability examples; read and apply only the examples selected in `product-spec.json`.
- Fall back to general framework conventions only when the template and plugin references are silent.
