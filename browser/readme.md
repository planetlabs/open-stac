# STAC Browser overlays

Planet branding and config applied on top of [radiantearth/stac-browser](https://github.com/radiantearth/stac-browser) during `make browser`.

| File | Purpose |
|------|---------|
| `config.mjs` | `SB_CONFIG` overlay (title, `preprocessSTAC`, `allowExternalAccess`) |
| `assets/planet-logo.svg` | Header logo (`catalogImage`, path set in Makefile) |
| `components/HeaderTitle.vue` | Allows path-absolute `catalogImage` (upstream returns null without `://`) |
| `theme/variables.scss` | Planet palette / fonts (based on a radiant release) |
| `theme/custom.scss` | Safe extra CSS (Inter Tight Variable `@font-face`) |

Build uses Node 26 (see `NODE` in the root `Makefile`); radiant v5 / Vite 7 need Node `^20.19 || >=22`.

## Bumping STAC Browser

1. Set `STAC_BROWSER_SHA` in the root `Makefile` to a radiant release tag SHA (prefer tags like `v5.0.x`).
2. Diff upstream `src/theme/variables.scss` against `browser/theme/variables.scss` and re-apply Planet colors if the structure changed.
3. `rm -rf build/.browser-* stac-browser && make preview`
