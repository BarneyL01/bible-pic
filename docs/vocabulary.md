# Vocabulary

The shared language for this project. A term defined here means exactly this in conversation,
files, skill names, and commit messages.

Maintained with the `/vocabulary` skill. Do not edit a definition in place without following
its amend/supersede procedure.

Last reviewed: 2026-10-02 (Bible Pic app terms, web surface)

## Repository and configuration

| Term | Definition | Notes |
| --- | --- | --- |
| **agent-base** | The portable configuration in this repository (`templates/`, `.claude/skills/`, `docs/`, `evals/`): reusable Claude Code configuration for Flutter apps. | Not a dependency. Established by ADR 0001; the repository also holds the Bible Pic app in `app/` (ADR 0006). |
| **the base** | Short form of *agent-base* when the repository is already the subject. | Use the full name in commit messages and file headers. |
| **app repo** | A separate repository containing one Flutter application, which has adopted the base. | Owns its configuration after adoption; the base does not reach into it. |
| **adoption** | The one-time act of copying `templates/flutter-app/` into an app repo. | Performed by `/adopt-base`. An *update* is a later re-run against an app that already adopted. |
| **template** | A file under `templates/` that becomes live instruction in an app repo when copied. | Audited as live instructions, never as inert examples. See rubric R3. |
| **agent configuration** | The set of `CLAUDE.md` files, skills, and `.claude/settings.json` that shape Claude's behaviour in a repo. | The subject of `/audit-agent-config`. Excludes application code. |
| **skill** | A directory under `.claude/skills/<name>/` containing a `SKILL.md`, loaded only when its description matches the request. | Contrast with `CLAUDE.md`, which loads on every turn. |
| **trigger** | The "when to use it" half of a skill description, which decides whether the skill loads. | A skill with no trigger clause effectively does not exist. |
| **finding** | A defect reported by `/audit-agent-config`, carrying a severity, a location, and a concrete fix. | An observation with no stated fix is not a finding. |
| **placeholder** / **TBD** | An explicitly undecided choice recorded in a `CLAUDE.md`, awaiting a user decision. | Closed only by `/flutter-stack-decide`. Filling one with an assumed default is a blocking finding. |
| **ADR** | Architecture Decision Record: a numbered, immutable file in `docs/decisions/` recording one choice and its reasoning. | Superseded rather than edited once its status is `Accepted`. |
| **drift** | Divergence between what the configuration says and what is true. | *Divergence* that is deliberate and recorded is not drift. |
| **provenance** | The recorded reason an instruction exists: its category, the model generation it was written against if any, and how to re-test it. | Carried as an HTML comment beside the instruction. ADR 0004; rubric M4. |
| **compensation** | A provenance category: an instruction that exists because a model generation misbehaved. | Re-tested by `/model-upgrade` on every new generation. The only category a model change can retire. |
| **environment fact** | A provenance category: an instruction recording something true about the world the agent works in. | Re-checked when the environment changes, not when the model does. Example: no Flutter SDK in cloud containers. |
| **preference** | A provenance category: an instruction that is the owner's choice. | Retired only by the owner. Never removed on the grounds that the model no longer needs it. |
| **contract** | A provenance category: an instruction describing how a tool, skill, or mechanism works. | Changes when the mechanism does. |
| **baseline** | The model generation and Claude Code version the configuration was last calibrated against, recorded in `docs/model-baseline.md`. | Updated only by `/model-upgrade`. |
| **recalibration** | The act of re-testing compensations, adding guidance for a new model's documented behaviours, and updating the baseline. | Performed by `/model-upgrade`. Produces a report and a proposed diff, never an applied one. |
| **eval case** | One directory under `evals/` holding a prompt phrased as a user would type it and one or more graders. | Run by `claude plugin eval`. ADR 0005. |
| **retest probe** | The one-line check recorded in a compensation's provenance tag that shows whether the compensation is still needed. | A probe not run leaves the compensation `untested`, never `still needed` by default. |

## Flutter delivery

| Term | Definition | Notes |
| --- | --- | --- |
| **surface** | A build target the app ships to: `web` or `android`. | Used instead of "platform" to avoid collision with Flutter's own platform channels. |
| **primary surface** | The surface whose constraints win when web and Android requirements conflict. | Declared per app during adoption; not assumed. |
| **stack choice** | A decision about which library or pattern the app uses for one concern (state, routing, networking, testing, CI). | Each one is either decided in an ADR or marked TBD. There is no third state. |

## Bible Pic app

| Term | Definition | Notes |
| --- | --- | --- |
| **verse** | A Bible passage the owner entered: reference, text, optional translation label. | Never fetched from an online source. |
| **topic** | A named tag linking verses and photos. | A verse or photo can have several. |
| **canvas** | The full-window area holding the photo, a plain margin colour, and the text box. | Text box geometry is stored as fractions of the canvas. On a window wider than 9:16 the canvas is the phone frame. |
| **phone frame** | The centred 9:16 column the app is shown in on a window wider than a phone. | Keeps the canvas phone-shaped on desktop web (ADR 0008). |
| **text box** | The movable, resizable panel that holds a verse on the canvas. | May extend past the photo's edge onto the margin. Width is stored; height fits the text. |
| **theme** | A named style preset: font, verse and reference sizes, text colour, alignment, panel colour, opacity, corner radius. | Excludes position. Applied: the verse's own theme, then the theme of the photo it is shown on, then a topic theme, then the default. ADR 0010. |
| **pairing** | Choosing the photo shown with a verse: pinned photo, then topic-matched photo, then any photo. | Recently shown photos are skipped where enough exist. |
| **selection mode** | The Photo library state in which tapping a photo selects it, entered by a long press or the checklist button. | Actions apply to every selected photo: set topics, set theme, delete. |
| **pinned photo** | A photo fixed to one verse. | Set by the lock button or the verse editor. |
| **verse of the day** | The verse chosen by a random draw seeded by the date. | Same all day; changes at midnight. Used by the widget, not the main screen. |
| **backup file** | The zip holding `manifest.json`, `data.json`, and `photos/`. | Restore is *Replace* or *Merge*. |

## Retired

| Term | Retired | Replaced by |
| --- | --- | --- |
| *(none yet)* | | |
