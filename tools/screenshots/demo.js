.pragma library

var HOUR = 3600000
var FIVE_HOURS = 5 * HOUR
var WEEK = 7 * 24 * HOUR
var MONTH = 30 * 24 * HOUR

function resetsAt(now, windowMs, elapsed) {
    return new Date(now + windowMs * (1 - elapsed)).toISOString()
}

// Rich 6-provider payload for the panel and full showcase.
function allProviders(now) {
    return JSON.stringify({
        providers: [
            {
                id: "claude",
                name: "Claude",
                state: "ok",
                detail: "MAX",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 38.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.62) },
                    { id: "seven_day", label: "7d", percent: 55.0, resetsAt: resetsAt(now, WEEK, 0.43) }
                ],
                extraUsage: {
                    label: "Extra Usage Limit",
                    enabled: true,
                    status: "Enabled",
                    amount: "$13.51 / $50.00",
                    percent: 27.0
                }
            },
            {
                id: "codex",
                name: "Codex",
                state: "ok",
                detail: "ChatGPT plus",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 84.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.48) },
                    { id: "seven_day", label: "7d", percent: 31.0, resetsAt: resetsAt(now, WEEK, 0.18) }
                ]
            },
            {
                id: "opencode",
                name: "OpenCode Go",
                state: "ok",
                detail: "OpenCode Go",
                cached: false,
                windows: [
                    { id: "rolling", label: "5h", percent: 24.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.72) },
                    { id: "weekly", label: "Weekly", percent: 42.0, resetsAt: resetsAt(now, WEEK, 0.55) },
                    { id: "monthly", label: "Monthly", percent: 81.0, resetsAt: resetsAt(now, MONTH, 0.88) }
                ]
            },
            {
                id: "zai",
                name: "Z.ai",
                state: "ok",
                detail: "GLM Coding Plan",
                cached: false,
                windows: [
                    { id: "zai_0", label: "5h", percent: 26.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.35) },
                    { id: "zai_1", label: "Monthly", percent: 48.0, resetsAt: resetsAt(now, MONTH, 0.60) }
                ]
            },
            {
                id: "antigravity",
                name: "Antigravity",
                state: "ok",
                detail: "Google Antigravity",
                cached: false,
                windows: [
                    { id: "ag_0", label: "Claude/GPT 5h", percent: 18.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.40) },
                    { id: "ag_1", label: "Gemini 5h", percent: 64.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.52) }
                ]
            },
            {
                id: "commandcode",
                name: "Command Code",
                state: "ok",
                detail: "GOAT",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 19.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.58) },
                    { id: "weekly", label: "Weekly", percent: 34.0, resetsAt: resetsAt(now, WEEK, 0.42) },
                    { id: "credits", label: "Credits", percent: 57.6, resetsAt: "" }
                ],
                extraUsage: {
                    label: "Monthly Credits",
                    enabled: true,
                    status: "$29.68 left",
                    amount: "$40.32 / $70.00",
                    percent: 57.6
                }
            }
        ]
    })
}

// Focused 3-provider payload for the un-scrolled popup hero & style tiles.
function heroPopup(now) {
    return JSON.stringify({
        providers: [
            {
                id: "claude",
                name: "Claude",
                state: "ok",
                detail: "MAX",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 38.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.62) },
                    { id: "seven_day", label: "7d", percent: 55.0, resetsAt: resetsAt(now, WEEK, 0.43) }
                ],
                extraUsage: {
                    label: "Extra Usage Limit",
                    enabled: true,
                    status: "Enabled",
                    amount: "$13.51 / $50.00",
                    percent: 27.0
                }
            },
            {
                id: "codex",
                name: "Codex",
                state: "ok",
                detail: "ChatGPT plus",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 84.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.48) },
                    { id: "seven_day", label: "7d", percent: 31.0, resetsAt: resetsAt(now, WEEK, 0.18) }
                ]
            },
            {
                id: "commandcode",
                name: "Command Code",
                state: "ok",
                detail: "GOAT",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 22.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.58) },
                    { id: "credits", label: "Credits", percent: 57.6, resetsAt: "" }
                ],
                extraUsage: {
                    label: "Monthly Credits",
                    enabled: true,
                    status: "$29.68 left",
                    amount: "$40.32 / $70.00",
                    percent: 57.6
                }
            }
        ]
    })
}

// Compact 3-provider payload for individual panel style tiles.
function tileProviders(now) {
    return JSON.stringify({
        providers: [
            {
                id: "claude",
                name: "Claude",
                state: "ok",
                detail: "MAX",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 38.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.62) },
                    { id: "seven_day", label: "7d", percent: 62.0, resetsAt: resetsAt(now, WEEK, 0.43) }
                ]
            },
            {
                id: "codex",
                name: "Codex",
                state: "ok",
                detail: "ChatGPT plus",
                cached: false,
                windows: [
                    { id: "five_hour", label: "5h", percent: 84.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.48) },
                    { id: "seven_day", label: "7d", percent: 31.0, resetsAt: resetsAt(now, WEEK, 0.25) }
                ]
            },
            {
                id: "opencode",
                name: "OpenCode Go",
                state: "ok",
                detail: "OpenCode Go",
                cached: false,
                windows: [
                    { id: "rolling", label: "5h", percent: 24.0, resetsAt: resetsAt(now, FIVE_HOURS, 0.72) },
                    { id: "monthly", label: "Monthly", percent: 96.0, resetsAt: resetsAt(now, MONTH, 0.88) }
                ]
            }
        ]
    })
}
