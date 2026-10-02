# Bible Pic and agent-base

This repository holds two things:

| Part | What it is | Where |
| --- | --- | --- |
| **Bible Pic** | A Flutter app that shows Bible verses you enter on photos you upload, by topic, with swiping, themes, backup and an Android home-screen widget. Runs on Android and in a browser. | [`app/`](app/) |
| **agent-base** | Reusable Claude Code configuration for Flutter apps: instructions, skills, permission defaults, vocabulary and decision records. Bible Pic was built from it. | everything else |

Bible Pic lives in this repository by choice ([ADR 0006](docs/decisions/0006-bible-pic-app-lives-in-app-directory.md)).
Other app repositories adopt agent-base by copying `templates/flutter-app/` into themselves.

## Bible Pic

### Run it

Run these in PowerShell from the repository root. Each step needs the one before it.

| Step | Command | Why |
| --- | --- | --- |
| 1 | `cd app` | Every Flutter command below runs inside `app/`, where `pubspec.yaml` is. |
| 2 | `flutter pub get` | Downloads the packages. |
| 3 | `dart run build_runner build --delete-conflicting-outputs` | Generates the database code (`lib/db/database.g.dart`, not committed). |
| 4 | `dart run tool/fetch_web_assets.dart` | Web only: downloads `sqlite3.wasm` and `drift_worker.js` into `web/` (not committed). |
| 5a | `flutter run -d chrome` | Runs the web version. |
| 5b | `.\tool\setup_android.ps1`, then `flutter run` | Android only: generates the Android project and installs the widget files, then runs on a connected phone. |

Check your work with `flutter analyze` and `flutter test` from `app/`.

### Publish the web version

The workflow in [`.github/workflows/web.yml`](.github/workflows/web.yml) analyses, tests, builds and publishes the site
to GitHub Pages on every push to `main` that changes `app/`.

- In the repository, open **Settings → Pages** and set **Source** to **GitHub Actions** once.
- The site is served at `https://<owner>.github.io/<repository>/`. The workflow sets the base path from the repository name.
- To publish from a branch other than `main`, run the workflow manually (**Actions → Web build and deploy → Run workflow**).

Details, the browser test suite, and the layout of `app/` are in [`app/README.md`](app/README.md).

## agent-base

### Skills

| Command | Does |
| --- | --- |
| `/audit-agent-config` | Audits every `CLAUDE.md` and skill for stale paths, vagueness, duplication, broken references and weak triggers. `--fix` applies the safe findings. |
| `/adopt-base` | Installs or updates the base in a Flutter app repo, reconciling anything the app has customised. |
| `/flutter-stack-decide` | Closes a `TBD` stack placeholder: presents options, takes the decision, writes an ADR and a checkable instruction. |
| `/vocabulary` | Records, amends or retires a term in `docs/vocabulary.md`. |
| `/model-upgrade` | Recalibrates the configuration for a new model generation: re-tests every compensation, proposes additions, runs the evals, updates the baseline. |

### Repository layout

```
CLAUDE.md                     instructions for working in this repository
.claude-plugin/plugin.json    makes the repo a plugin so `claude plugin eval .` runs
.claude/
  settings.json               permission defaults
  skills/                     the five skills above
.github/workflows/web.yml     builds, tests and publishes Bible Pic's web version
docs/
  vocabulary.md               agreed terms
  model-baseline.md           which model generation the config is tuned for
  asking-for-improvements.md  prompts that make this repo better
  adoption.md                 how an app repo consumes the base
  lessons.md                  corrections worth keeping across sessions
  decisions/                  ADRs, numbered and immutable once accepted
evals/                        behavioural tests for the skills
templates/flutter-app/        what gets copied into an app repo
app/                          the Bible Pic Flutter app (has its own CLAUDE.md and README.md)
```

### Common tasks

| I want to | Do this |
| --- | --- |
| Set up a new Flutter app from the base | Follow [docs/adoption.md](docs/adoption.md). |
| Change the base | Read [CLAUDE.md](CLAUDE.md), then run `/audit-agent-config` before committing. |
| Look up a term | See [docs/vocabulary.md](docs/vocabulary.md). |
| Recalibrate for a new model | Run `/model-upgrade <model-id>`; other prompts are in [docs/asking-for-improvements.md](docs/asking-for-improvements.md). |
| Test the skills | Run `claude plugin eval . --no-publish`; see [evals/README.md](evals/README.md). |

In the template, every Flutter stack choice in `templates/flutter-app/CLAUDE.md` is marked `TBD` and is closed
explicitly rather than assumed ([ADR 0002](docs/decisions/0002-stack-choices-stay-open-until-decided.md)).
