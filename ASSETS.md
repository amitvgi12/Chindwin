# Asset and dependency ledger

Every file under `game/assets/` and `marketing/`, and every addon under `game/addons/`, needs a row
here before it is committed. `make assets-check` enforces this, and CI runs it on
every push.

- **Path** is relative to the repository root. A path ending in `/` covers
  everything below that folder.
- **Placeholder** is `yes` for anything that must be replaced before release.

| Path | Source | Author | Licence | Placeholder | Notes |
|---|---|---|---|---|---|
| `game/addons/gut/` | https://github.com/bitwes/Gut/releases/tag/v9.7.1 | Tom "Butch" Wesley and contributors | MIT (game/addons/gut/LICENSE.md) | no | GUT 9.7.1 unit-test framework. Development only; excluded from exported builds. Bundles the Anonymous Pro, Courier Prime and Lobster Two fonts for its own panel. Their licences have not been checked individually; they never ship. |
| `marketing/concept/logo-concept.webp` | Supplied by Amit, 15 Nov 2026. AI-generated; carries the Google Gemini mark. | Amit Kumar, using Google Gemini | Not established. Gemini's terms for commercial use have not been checked. | yes | Title concept. Reference only: not used in the game or on any store page. |
| `marketing/concept/poster-concept.png` | Supplied by Amit, 15 Nov 2026. AI-generated with Google Gemini. | Amit Kumar, using Google Gemini | Not established. Gemini's terms for commercial use have not been checked. | yes | Poster concept. Reference only. Historical details are unverified: the cap badge, the rifle and the "Manipur" stone are the image generator's inventions. |
