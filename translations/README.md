Prism Launcher Translations
---

Translation files for SsaninaMC, a fork of [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher).

Upstream keeps these in a separate repository
([PrismLauncher/Translations](https://github.com/PrismLauncher/Translations)) and serves the compiled
`.qm` files from a web host, which the launcher downloads at runtime. Here the sources live next to
the launcher and the compiled translations are baked into the binary, so no hosting is involved.

Layout
---

* `*.ts` — Qt translation sources, one per language, generated from the launcher sources by `lupdate`
* `.template.ts` — every source string, used to seed new languages
* `release.sh` — compiles the `.ts` files into `.qm` plus `build/index_v2.json`, for inspecting the
  output outside of a build
* `update.sh` — regenerates the `.ts` files from `../launcher`

How they get into the build
---

`cmake/GenerateTranslations.cmake` runs at build time. It compiles every `.ts` into
`mmc_<lang>.qm`, works out the statistics the language picker shows, and writes `index_v2.json`
together with a `.qrc`. The launcher links that `.qrc` in, and on startup unpacks the files into its
data directory where the translation model expects them.

This needs `lrelease` from Qt's LinguistTools, which is part of the `qttools` module. `lconvert` and
`msgfmt` are only needed by `release.sh`, not by the build:

    sudo apt install gettext qt6-l10n-tools

If Qt was installed without `qttools` the build still succeeds, but the launcher falls back to
downloading translations from `Launcher_TRANSLATION_FILES_URL`.

Adding a language
---

Drop the `.ts` file in here and rebuild. Anything matching `*.ts` is picked up automatically, except
`.template.ts`.

Syncing with upstream
---

    git remote add pl-translations https://github.com/PrismLauncher/Translations.git
    cd translations
    git fetch pl-translations master
    git checkout pl-translations/master -- '*.ts' .template.ts

Translations are licensed under the Apache 2.0 license, see [LICENSE](LICENSE).
