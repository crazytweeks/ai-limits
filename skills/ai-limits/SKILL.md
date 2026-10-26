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
