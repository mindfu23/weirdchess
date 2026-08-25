# WeirdChess "API error: 500" — cause, fix, and the monitoring gap

*2026-08-25*

## 1. What was happening

Commentary failed on web, Android and iOS simultaneously — because all three
call the same Netlify proxy, so it was never a client bug.

The chain:

1. The app sends `model: "claude-3-haiku-20240307"` to
   `/.netlify/functions/chess-commentary`.
2. Anthropic has **retired** that model. It answers `404 not_found_error`.
3. `callAnthropic()` threw on any non-OK response, and the handler's `catch`
   flattened *every* error to `statusCode: 500`.
4. The Flutter client's `_callNetlifyFunction` has no branch for 500, so it
   renders the generic `API error: ${response.statusCode}`.

Verified directly against the API:

```
claude-3-haiku-20240307  → 404 {"type":"not_found_error","message":"model: claude-3-haiku-20240307"}
claude-haiku-4-5-20251001 → 200
```

The API key was fine the whole time. Only the model was gone.

## 2. What was fixed

| File | Change |
|---|---|
| `netlify/functions/chess-commentary.js` | Defaults → `claude-haiku-4-5-20251001` / `gemini-2.5-flash`. Added `RETIRED_MODELS` remap. Upstream failures now return their real status via `UpstreamError` instead of a blanket 500. |
| `lib/services/config_service.dart` | Same defaults; added `kRetiredModels` + `resolveRetiredModel()`, applied on both the SharedPreferences path (rewriting the stale key so it migrates once) and the bundled-config path. |
| `lib/services/llm_service.dart` | Default model updated. |
| `assets/config.json` (+ `.example`) | **This ships inside the app bundle** and is the config used on a fresh install — it still pinned the retired ids. |
| `test/services/model_ids_test.dart` | New: fails the build if any shipped default is a retired id. |
| `netlify/functions/health.js` | New health endpoint (see §3). |
| `netlify.toml` | `/api/health` redirect, placed above the SPA catch-all. |

### Why the remap table matters more than the default

You cannot force-update an installed Android or iOS binary, and a user who ever
opened settings has a model id saved in SharedPreferences that outlives an app
update. Without the server-side `RETIRED_MODELS` table, those clients would stay
broken forever no matter what you ship. **The proxy fix is what actually
restores existing installs; the default-value fix only helps new ones.**

Verified: `flutter analyze` clean, 67/67 tests pass, `flutter build web` clean.

**Not yet deployed** — needs a Netlify deploy to take effect.

## 3. Why nothing warned you

You *did* build this. `generic_modules/health-check/` exists, is documented, and
lists WeirdChess in its monitor CSV. It never actually ran. A live sweep of all
20 apps in that CSV:

| Result | Count |
|---|---|
| Returning real health JSON | **2** (ShamAIn, CreateIt) |
| Degraded | 1 (ValueApe — `gemini: HTTP 400`) |
| `404` — health.js never deployed | 9 |
| `200` with **index.html** — SPA catch-all swallowed `/api/health` | 7 |
| Other | 1 (GPTWrapper, no `status` field) |

Four independent silent-pass defects, each of which alone would have hidden this:

1. **The `/api/health` redirect is missing in 7 apps.** Netlify applies the first
   matching rule, so `/*` → `/index.html` wins and `/api/health` returns HTML
   with HTTP 200. A plain uptime monitor reads that as "up".
2. **`health.js` with an empty `CHECKS` array reported `healthy`.** A copied but
   unconfigured template sat there permanently green while checking nothing.
3. **The daily sweep workflow counts a missing endpoint as a pass.** `404` was
   labelled "⏳ Not installed" and did not increment `FAILED`, and the Slack
   alert only fires on `FAILED != 0`. Even if the workflow had been installed,
   it would have reported "18/20 healthy" with 15 apps unmonitored.
4. **`.github/workflows/health-report.yml` was never copied into any repo.** The
   sweep has never run once.

All four are now fixed in `generic_modules/health-check/`:

- `netlify/functions/health.js` — empty `CHECKS` now reports
  `unhealthy` / `MISCONFIGURED`; new **`model` check type**; the commented-out
  Anthropic `auth` example had a latent bug (missing `anthropic-version`, would
  have 400'd the moment anyone enabled it) — fixed.
- `github-actions/health-report.yml` — missing/HTML endpoints now count as
  `UNMONITORED`, alert, and are reported as a separate coverage line.
- `scripts/sweep-health.sh` — new; run the sweep locally any time, non-zero exit
  if anything needs attention.
- `README.md` — documents the redirect-ordering trap and the model check.

### The `model` check — the one that would have caught this

A key-validity check passes right through model retirement. This one doesn't:

```
model "claude-3-haiku-20240307" is NOT in anthropic's live model list — likely retired
```

It asks the provider for its live model list and asserts the exact id the app
ships with is in it. Zero tokens, ~200ms, and it fails *before* users see an
error. Verified working in both the WeirdChess endpoint and the shared template.

## 4. What to do next

**Now**
1. Deploy WeirdChess (`git push`, or `netlify deploy --prod --no-build` — note
   `--dir=dist` triggers a rebuild and drops env vars).
2. `curl https://weirdchess.netlify.app/api/health` → expect `"status":"healthy"`.
3. Rebuild/resubmit the Android and iOS binaries so fresh installs get the new
   `assets/config.json`. Existing installs are fixed by the proxy deploy alone.

**This week — other apps carrying retired model ids in live code**

| App | File | Model |
|---|---|---|
| StoryPlot | `netlify/functions/ai-fill-form.js` | `claude-3-haiku-20240307`, `gemini-1.5-flash` |
| Novelizer | `web/storyplot/netlify/functions/ai-fill-form.js` | same |
| ShamAIn | `netlify/functions/aiConfig.js` | `claude-3-haiku-20240307` |
| apiTracker | `netlify/functions/test-api-key.js` | `claude-3-haiku-20240307` |
| GPTWrapper | `firebase/functions/aiConfig.js` | `claude-3-5-sonnet-20241022`, `claude-3-haiku-20240307` |
| IsHe | `web/netlify/functions/ai-verify.js` | `claude-3-5-sonnet-20241022` |
| Postboi | `config.py` + 6 others | `claude-3-5-sonnet-20241022` |
| ValueApe | already **degraded** on `gemini: HTTP 400` | investigate |

**Then — close the monitoring gap for real**

1. Install `health.js` + the `/api/health` redirect in the 16 apps missing it,
   each with a `model` check for every model it calls.
2. Copy `github-actions/health-report.yml` into one repo and set
   `SLACK_WEBHOOK_URL`. Until it runs somewhere, none of this reports anything.
3. Re-import `uptimerobot-keyword-monitors.csv` into UptimeRobot and confirm the
   monitors exist and are active — with 15 apps currently returning 404 or HTML,
   working keyword monitors would already be alerting loudly.

### The durable lesson

A monitor that cannot distinguish *"everything is fine"* from *"I am not
checking anything"* is worse than no monitor, because it converts an unknown
into a false all-clear. Every layer here defaulted to green on absence: no
checks → healthy, no endpoint → pass, valid key → assume the model works. Make
absence loud.
