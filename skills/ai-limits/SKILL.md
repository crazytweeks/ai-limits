---
name: ai-limits
description: Check the user's current AI coding-assistant usage limits (Claude Code, Codex, OpenCode Go, Z.ai, Antigravity, Command Code) via the local `ai-limits` command. Use when asked about remaining quota, rate limits, reset times, or which provider has headroom before starting a large task or delegating work.
---

# ai-limits

`ai-limits` prints live usage for every AI provider signed in on this machine.
It shares one cached snapshot with the Plasma "Usage Limits" widgets, so a call
is normally instant and does not hit provider APIs.

## Commands

- `ai-limits` — human-readable bars, percentages and reset countdowns.
- `ai-limits --json` — machine-readable; prefer this when you need to reason over the numbers.
- `ai-limits --refresh` — force a fresh fetch (only when the user asks for up-to-the-minute data).
- `ai-limits --cached` — never touch the network.
- `ai-limits --all` — also list providers that are not signed in.
- `ai-limits --set-interval SECONDS` — change the shared poll interval (60–3600) for the CLI and all widgets.

## JSON shape

```json
{"providers": [{"id": "claude", "name": "Claude", "state": "ok", "detail": "PRO",
  "cached": false, "notice": "optional warning",
  "windows": [{"id": "five_hour", "label": "5h", "percent": 9.0,
               "resetsAt": "2026-10-26T15:30:00+00:00"}],
  "extraUsage": {"label": "...", "status": "...", "amount": "...", "percent": 0}}],
 "_fetched_at": 1793000000, "pollInterval": 900, "pollIntervalShared": true}
```

`state` is one of `ok | unauthenticated | token_expired | rate_limited | error`.
`cached: true` means the latest fetch failed and the last good data is shown
(see `notice` for why). `percent` is usage consumed, 0–100.

## Interpreting

- Treat a window at 80%+ as tight and 95%+ as exhausted until `resetsAt`.
- When choosing a provider for delegated work, prefer the one with the lowest 5-hour usage that is `state: ok`.
- A window missing from `windows` means its usage is unknown, not 0%. A provider with no 5-hour window cannot
  win the lowest-usage comparison.
- With `cached: true` the numbers may be stale, and real usage may be higher.
- Most providers are read through unofficial or undocumented endpoints that can change without notice, so treat
  all numbers as best-effort. Never quote them as exact remaining quota.

## Providers ai-limits does not (fully) track

- **OpenCode Go** (subscription, connected via `opencode` → `/connect`): models are `opencode-go/*`
  (e.g. `opencode-go/muse-spark-1.3-contributor`, `kimi-k3.1-pro`, `deepseek-v4-pro`, `qwen3.8-max`,
  `glm-5.3`, `mimo-v2.6-pro`). Has 5-hour, weekly and monthly windows; when a window is used up,
  agents stop with "OpenCode Go 5 hour usage limit reached". `ai-limits` may still list it as
  `unauthenticated`; check the Plasma "Usage Limits" widget instead.
- **Deploy** (via `opencode`): pay-per-use models that share one prepaid credit balance, which can be recharged.
  Not shown in `ai-limits`. Use them for bulk or long-running worker tasks when subscription windows are
  tight, and avoid wasting them on trivial jobs. New models appear in `opencode models` only after OpenCode
  restarts (`opencode service` / reopen OpenCode).

  | Model | Input / 1M | Output / 1M | Cache / 1M |
  |---|---|---|---|
  | `deploy/deepseek-ai/deepseek-v4.1-flash-1017` | $0.10 | $0.35 | $0.003 |
  | `deploy/zai-org/glm-5.3-flash` | $0.05 | $0.17 | $0.01 |

  Direct API: `POST https://api.deploy.com/api/v1/chat/completions` with `Authorization: Bearer <key>`; the
  model ID there drops the `deploy/` prefix. HTTP `405` from this endpoint can mean the credit has run out.

  Balance: run `scripts/deploy_balance.py` from this skill's directory. It prints JSON with `balance` in US
  dollars and needs a logged-in portal session cookie, not an API key. It uses an unofficial portal route, so
  `state` other than `ok` means the balance is unknown, not zero.
- **`opencode/*-free` models**: share a free-tier cap ("Free usage limit reached"). Treat them as
  unreliable for long tasks.
- T3 `delegate_task` uses its own cached OpenCode model list. If an `opencode-go/*` or `deploy/*` model is
  "not advertised", launch it through `hc run --bg ... opencode run --auto -m <model> "<task>"` instead.
