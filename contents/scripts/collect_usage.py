#!/usr/bin/env python3
"""Collect AI subscription usage limits from every provider signed in locally.

Providers: Claude Code, OpenAI Codex (ChatGPT plan), OpenCode Go, Z.ai GLM
Coding Plan, Google Antigravity, Command Code. Each one's credentials are
read from where its CLI already stores them; nothing is sent anywhere
except the provider's own endpoint.

Prints one JSON object on stdout and always exits 0:
{
  "providers": [
    {"id": "claude", "name": "Claude", "state": "ok", "detail": "...",
     "windows": [{"id": "five_hour", "label": "5h", "percent": 18.0,
                  "resetsAt": "2026-10-20T14:59:59+00:00"}], "cached": false},
    ...
  ],
  "_fetched_at": 1760000000
}

states: ok | unauthenticated | token_expired | rate_limited | error
Each provider is isolated: one failing never touches the others. A provider
that worked recently keeps serving its cached payload (marked "cached")
until a fetch succeeds again.
"""

import datetime
import glob
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
CACHE_DIR = os.path.join(HOME, ".cache", "ai-limits")
USER_AGENT = "ai-limits/0.2"
REQUEST_TIMEOUT = 10

CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
CODEX_REFRESH_URL = "https://auth.openai.com/oauth/token"
CODEX_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
CLAUDE_USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
CLAUDE_OAUTH_BETA = "oauth-2025-04-20"
OPENCODE_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"
ZAI_QUOTA_URL = "https://api.z.ai/api/monitor/usage/quota/limit"
ANTIGRAVITY_TOKEN_URL = "https://oauth2.googleapis.com/token"
ANTIGRAVITY_API_BASE = "https://daily-cloudcode-pa.googleapis.com/v1internal"
ANTIGRAVITY_HUB_UA = "antigravity/hub/2.9.1/linux/amd64"
COMMANDCODE_BASE = "https://api.commandcode.ai/alpha"


def http_json(url, headers, timeout=REQUEST_TIMEOUT):
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read()
        return resp.status, json.loads(body), {}
    except urllib.error.HTTPError as e:
        return e.code, None, {}
    except Exception:
        return 0, None, {}


def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None


def iso_from_epoch(value):
    """Epoch seconds or milliseconds to ISO 8601 UTC, or None."""
    try:
        value = float(value)
    except (TypeError, ValueError):
        return None
    if value > 1e11:  # milliseconds
        value /= 1000.0
    try:
        return time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime(value))
    except (OverflowError, OSError, ValueError):
        return None


def window(id_, label, percent, resets_iso):
    return {"id": id_, "label": label, "percent": round(float(percent), 1),
            "resetsAt": resets_iso or ""}


# --- Claude -----------------------------------------------------------------

def claude_windows(data):
    windows = []
    five = data.get("five_hour") or {}
    seven = data.get("seven_day") or {}
    windows.append(window("five_hour", "5h", five.get("utilization") or 0,
                          five.get("resets_at")))
    windows.append(window("seven_day", "7d", seven.get("utilization") or 0,
                          seven.get("resets_at")))
    for limit in data.get("limits") or []:
        if not isinstance(limit, dict):
            continue
        if limit.get("group") != "weekly" or limit.get("kind") == "weekly_all":
            continue
        percent = limit.get("percent") or 0
        resets = limit.get("resets_at") or ""
        if percent <= 0 and not resets:
            continue
        windows.append(window("weekly_scoped", scoped_label(limit), percent, resets))
    return windows


def scoped_label(limit):
    scope = limit.get("scope") or {}
    name = None
    model = scope.get("model") or {}
    name = model.get("display_name") or model.get("id")
    if not name:
        surface = scope.get("surface")
        if isinstance(surface, str):
            name = surface
        elif isinstance(surface, dict):
            name = surface.get("display_name") or surface.get("id")
    return "Weekly (" + (name or "scoped") + ")"


def collect_claude():
    folder = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(HOME, ".claude")
    cred_file = os.path.join(folder, ".credentials.json")
    creds = load_json(cred_file)
    oauth = (creds or {}).get("claudeAiOauth") if isinstance(creds, dict) else None
    if not isinstance(oauth, dict) or not oauth.get("accessToken"):
        return {"state": "unauthenticated",
                "detail": "Sign in with: claude (no .credentials.json found)"}

    expires_at = oauth.get("expiresAt") or 0
    try:
        if int(time.time() * 1000) > float(expires_at):
            return {"state": "token_expired",
                    "detail": "Token expired. Run claude in a terminal to refresh."}
    except (TypeError, ValueError):
        pass

    sub_type = str(oauth.get("subscriptionType") or "").strip().upper()

    # Identify as the installed Claude Code; the endpoint gates some fields
    # on the client. The token reaches curl... urllib via a header built in
    # process, so it never appears in argv.
    version = "2.1.280"
    versions_dir = os.path.join(HOME, ".local/share/claude/versions")
    try:
        found = [v for v in os.listdir(versions_dir) if v[0].isdigit()]
        if found:
            version = max(found, key=lambda v: [int(x) for x in v.split(".")])
    except OSError:
        pass

    headers = {
        "Authorization": "Bearer " + oauth["accessToken"],
        "anthropic-beta": CLAUDE_OAUTH_BETA,
        "Accept": "application/json",
        "User-Agent": f"claude-cli/{version} (external, cli)",
    }
    status, data, _ = http_json(CLAUDE_USAGE_URL, headers)
    if status == 0:
        return {"state": "error", "detail": "Could not reach the Anthropic API", "plan": sub_type}
    if status == 429:
        return {"state": "rate_limited", "detail": "Rate limited by Anthropic", "plan": sub_type}
    if status in (401, 403):
        return {"state": "token_expired",
                "detail": "Token rejected. Run claude in a terminal to refresh.", "plan": sub_type}
    if status != 200 or not isinstance(data, dict):
        return {"state": "error", "detail": f"API returned HTTP {status}", "plan": sub_type}
    if "error" in data:
        msg = data["error"]
        if isinstance(msg, dict):
            msg = msg.get("message", str(data))
        return {"state": "error", "detail": str(msg), "plan": sub_type}
    extra = data.get("extra_usage")
    extra_info = None
    if isinstance(extra, dict):
        enabled = bool(extra.get("is_enabled"))
        util = float(extra.get("utilization") or 0.0)
        used_cents = float(extra.get("used_credits") or 0.0)
        limit_cents = extra.get("monthly_limit")
        used_str = f"${used_cents / 100.0:.2f}"
        if limit_cents is not None:
            try:
                used_str += f" / ${float(limit_cents) / 100.0:.2f}"
            except (TypeError, ValueError):
                pass
        reason = extra.get("disabled_reason") or ""
        status_str = "Enabled" if enabled else (
            "Out of credits" if reason == "out_of_credits" else "Disabled")
        extra_info = {
            "label": "Extra Usage Limit",
            "enabled": enabled,
            "status": status_str,
            "amount": used_str,
            "percent": round(util, 1),
        }

    cedar = data.get("cedar_ember")
    reset_grant = None
    if isinstance(cedar, dict) and cedar.get("eligible") and isinstance(cedar.get("grants"), list):
        next_id = cedar.get("next_grant_id")
        for g in cedar["grants"]:
            if isinstance(g, dict) and g.get("id") == next_id and (g.get("resets_left") or 0) > 0:
                reset_grant = {
                    "id": str(g["id"]),
                    "label": str(g.get("label") or ""),
                    "resetsLeft": int(g["resets_left"]),
                    "resetsTotal": int(g.get("resets_total") or g["resets_left"]),
                    "endsAt": str(g.get("ends_at") or ""),
                    "usableNow": bool(g.get("usable_now")),
                    "atLimit": bool(cedar.get("at_limit")),
                }
                break

    result = {"state": "ok", "detail": sub_type, "windows": claude_windows(data)}
    if extra_info:
        result["extraUsage"] = extra_info
    if reset_grant:
        result["resetGrant"] = reset_grant
    return result


# --- Codex (ChatGPT plan) ---------------------------------------------------

def codex_tokens(auth):
    tokens = auth.get("tokens")
    if isinstance(tokens, dict):
        return tokens
    if isinstance(auth.get("access_token"), str):
        return auth
    return None


def refresh_codex_token(auth, refresh_token):
    """Exchange the refresh token and write auth.json back in place, keeping
    the inode: other tools may hold hardlinks to the same file."""
    body = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "client_id": CODEX_CLIENT_ID,
        "refresh_token": refresh_token,
    }).encode()
    req = urllib.request.Request(
        CODEX_REFRESH_URL,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded",
                 "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            payload = json.load(resp)
    except Exception:
        return None
    access = payload.get("access_token")
    if not isinstance(access, str) or not access:
        return None
    tokens = codex_tokens(auth)
    if tokens is None:
        return None
    tokens["access_token"] = access
    for key in ("refresh_token", "id_token"):
        if isinstance(payload.get(key), str) and payload[key]:
            tokens[key] = payload[key]
    auth_path = os.path.join(
        os.environ.get("CODEX_HOME") or os.path.join(HOME, ".codex"), "auth.json")
    try:
        with os.fdopen(os.open(auth_path, os.O_WRONLY), "wb") as stream:
            data = json.dumps(auth, separators=(",", ":")).encode()
            stream.write(data)
            stream.truncate(len(data))
    except OSError:
        pass
    return access


def codex_window(raw, id_, fallback_label):
    if not isinstance(raw, dict):
        return None
    percent = raw.get("used_percent")
    if percent is None:
        percent = raw.get("used_percentage") or raw.get("usedPercentage")
    if percent is None:
        return None
    duration = raw.get("limit_window_seconds")
    label = fallback_label
    try:
        label = "5h" if float(duration) <= 24 * 60 * 60 else "7d"
    except (TypeError, ValueError):
        pass
    return window(id_, label, percent, iso_from_epoch(raw.get("reset_at") or raw.get("resets_at")))


def collect_codex():
    auth_path = os.path.join(
        os.environ.get("CODEX_HOME") or os.path.join(HOME, ".codex"), "auth.json")
    auth = load_json(auth_path)
    tokens = codex_tokens(auth) if isinstance(auth, dict) else None
    if not tokens or not isinstance(tokens.get("access_token"), str):
        return {"state": "unauthenticated",
                "detail": "Sign in with: codex (ChatGPT plan login not found)"}

    headers = {
        "Authorization": "Bearer " + tokens["access_token"],
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
    }
    if isinstance(tokens.get("account_id"), str) and tokens["account_id"]:
        headers["ChatGPT-Account-Id"] = tokens["account_id"]

    status, data, _ = http_json(CODEX_USAGE_URL, headers)
    if status in (401, 403) and isinstance(tokens.get("refresh_token"), str):
        refreshed = refresh_codex_token(auth, tokens["refresh_token"])
        if refreshed:
            headers["Authorization"] = "Bearer " + refreshed
            status, data, _ = http_json(CODEX_USAGE_URL, headers)

    if status == 0:
        return {"state": "error", "detail": "Could not reach the Codex usage API"}
    if status == 429:
        return {"state": "rate_limited", "detail": "Codex usage endpoint is rate-limited"}
    if status in (401, 403):
        return {"state": "unauthenticated",
                "detail": "Codex login expired. Run: codex"}
    if status != 200 or not isinstance(data, dict):
        return {"state": "error", "detail": f"Codex usage returned HTTP {status}"}

    rate_limit = data.get("rate_limit")
    if not isinstance(rate_limit, dict):
        return {"state": "error", "detail": "Codex returned no rate-limit windows"}

    windows = []
    for id_, slot, label in (("five_hour", "primary_window", "5h"),
                             ("seven_day", "secondary_window", "7d")):
        win = codex_window(rate_limit.get(slot), id_, label)
        if win:
            windows.append(win)
    if not windows:
        return {"state": "error", "detail": "Codex returned empty rate-limit windows"}

    detail = data.get("plan_type")
    detail = f"ChatGPT {detail}" if isinstance(detail, str) and detail else "ChatGPT plan"
    return {"state": "ok", "detail": detail, "windows": windows}


# --- OpenCode Go ------------------------------------------------------------

def collect_opencode():
    auth = load_json(os.path.join(HOME, ".local/share/opencode/auth.json"))
    entry = (auth or {}).get("opencode-go")
    key = entry.get("key") if isinstance(entry, dict) else None
    if not key:
        return {"state": "unauthenticated",
                "detail": "Run opencode /connect and add OpenCode Go"}

    status, data, _ = http_json(OPENCODE_USAGE_URL, {
        "Authorization": "Bearer " + key,
        "Accept": "application/json",
        "User-Agent": USER_AGENT,  # requests without one get 403
    })
    if status == 0:
        return {"state": "error", "detail": "Could not reach opencode.ai"}
    if status == 429:
        return {"state": "rate_limited", "detail": "opencode.ai is rate-limiting"}
    if status in (401, 403):
        return {"state": "unauthenticated",
                "detail": "OpenCode Go key rejected. Reconnect in opencode."}
    if status != 200 or not isinstance(data, dict):
        return {"state": "error", "detail": f"OpenCode usage returned HTTP {status}"}

    usage = data.get("usage")
    if not isinstance(usage, dict):
        return {"state": "error", "detail": "OpenCode returned no usage object"}

    windows = []
    for id_, label in (("rolling", "5h"), ("weekly", "Weekly"), ("monthly", "Monthly")):
        raw = usage.get(id_)
        if not isinstance(raw, dict):
            continue
        if raw.get("status") not in (None, "ok"):
            continue
        percent = raw.get("percent")
        if percent is None:
            continue
        windows.append(window(id_, label, percent, raw.get("resetsAt")))
    if not windows:
        return {"state": "error", "detail": "OpenCode returned no usage windows"}
    return {"state": "ok", "detail": "OpenCode Go", "windows": windows}


# --- Z.ai GLM Coding Plan ---------------------------------------------------

def zai_api_key():
    # 1. explicit file, 2. environment, 3. opencode config (MCP env block).
    key_file = os.path.join(HOME, ".config/ai-limits/zai-api-key")
    if os.path.isfile(key_file):
        try:
            with open(key_file) as f:
                key = f.read().strip()
            if key:
                return key
        except OSError:
            pass
    if os.environ.get("Z_AI_API_KEY"):
        return os.environ["Z_AI_API_KEY"]
    cfg = load_json(os.path.join(HOME, ".config/opencode/opencode.json"))
    if isinstance(cfg, dict):
        for server in (cfg.get("mcp") or {}).values():
            env = (server or {}).get("environment") or {}
            if env.get("Z_AI_API_KEY"):
                return env["Z_AI_API_KEY"]
    return None


ZAI_UNIT_LABELS = {2: "min", 3: "h", 4: "d", 5: "Weekly", 6: "Monthly"}


def zai_window_label(limit):
    try:
        unit = int(limit.get("unit"))
        number = int(limit.get("number"))
    except (TypeError, ValueError):
        return "Window"
    name = ZAI_UNIT_LABELS.get(unit)
    if name in ("Weekly", "Monthly"):
        return name
    if name:
        return f"{number}{name}"
    return f"{number}·u{unit}"


def collect_zai():
    key = zai_api_key()
    if not key:
        return {"state": "unauthenticated",
                "detail": "No Z.ai API key. Save one in ~/.config/ai-limits/zai-api-key"}

    status, data, _ = http_json(ZAI_QUOTA_URL, {
        "Authorization": "Bearer " + key,
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
    })
    if status == 0:
        return {"state": "error", "detail": "Could not reach api.z.ai"}
    if status == 429:
        return {"state": "rate_limited", "detail": "api.z.ai is rate-limiting"}
    if status in (401, 403):
        return {"state": "unauthenticated", "detail": "Z.ai API key rejected"}
    if status != 200 or not isinstance(data, dict):
        return {"state": "error", "detail": f"Z.ai usage returned HTTP {status}"}

    payload = data.get("data") if isinstance(data.get("data"), dict) else data
    limits = payload.get("limits")
    if not isinstance(limits, list) or not limits:
        return {"state": "error", "detail": "Z.ai returned no quota limits"}

    windows = []
    for limit in limits:
        if not isinstance(limit, dict):
            continue
        kind = limit.get("type")
        percent = limit.get("percentage")
        if percent is None and limit.get("usage"):
            try:
                usage = float(limit["usage"])
                current = limit.get("currentValue")
                if current is not None:
                    percent = float(current) / usage * 100
            except (TypeError, ValueError, ZeroDivisionError):
                percent = None
        if percent is None:
            continue
        label = "MCP" if kind == "TIME_LIMIT" else zai_window_label(limit)
        resets = iso_from_epoch(limit.get("nextResetTime"))
        windows.append(window(f"zai_{len(windows)}", label, percent, resets))
    if not windows:
        return {"state": "error", "detail": "Z.ai quota response had no readable windows"}

    windows.sort(key=lambda w: 0 if w["label"] == "MCP" else 1)
    plan = payload.get("planName") or payload.get("plan") or payload.get("packageName") or "GLM Coding Plan"
    return {"state": "ok", "detail": str(plan), "windows": windows}


# --- Google Antigravity -----------------------------------------------------

def antigravity_oauth_file():
    """Antigravity OAuth credentials ({client_id, client_secret, refresh_token,
    project_id}), wherever they live on this machine."""
    override = os.path.join(HOME, ".config/ai-limits/antigravity-oauth.json")
    for path in (override,
                 os.path.join(HOME, ".codexbar/antigravity/oauth_creds.json")):
        creds = load_json(path)
        if isinstance(creds, dict) and creds.get("refresh_token"):
            return creds
    # T3 Code stores the token used by its embedded Antigravity CLI here.
    for path in glob.glob(os.path.join(
            HOME, ".t3/userdata/providers/antigravity/*/antigravity-acp/acp_token.json")):
        creds = load_json(path)
        if isinstance(creds, dict) and creds.get("refresh_token"):
            return creds
    return None


def antigravity_access_token(creds):
    body = urllib.parse.urlencode({
        "client_id": creds["client_id"],
        "client_secret": creds["client_secret"],
        "refresh_token": creds["refresh_token"],
        "grant_type": "refresh_token",
    }).encode()
    req = urllib.request.Request(
        ANTIGRAVITY_TOKEN_URL, data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded",
                 "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
        payload = json.load(resp)
    access = payload.get("access_token")
    return access if isinstance(access, str) and access else None


def antigravity_post(bearer, method, body):
    req = urllib.request.Request(
        f"{ANTIGRAVITY_API_BASE}:{method}",
        data=json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + bearer,
                 "Content-Type": "application/json",
                 "User-Agent": ANTIGRAVITY_HUB_UA})
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
        return json.load(resp)


def antigravity_group_label(name):
    lowered = str(name).lower()
    if "gemini" in lowered:
        return "Gemini"
    if "claude" in lowered or "gpt" in lowered:
        return "Claude/GPT"
    return str(name)


def antigravity_bucket_label(name):
    lowered = str(name).lower()
    if "weekly" in lowered:
        return "Weekly"
    if "five" in lowered or "5h" in lowered:
        return "5h"
    return None  # unknown cadence, not a headline window


def antigravity_model_family(model_id):
    lowered = str(model_id).lower()
    if lowered.startswith("gemini"):
        return "Gemini"
    if lowered.startswith(("claude", "gpt", "chat_")):
        return "Claude/GPT"
    return None


def antigravity_windows(summary, per_model, now_epoch):
    windows = []

    # Preferred: quota summary — named groups with weekly/5h buckets.
    for group in (summary or {}).get("groups") or []:
        if not isinstance(group, dict):
            continue
        family = antigravity_group_label(group.get("displayName") or "")
        for bucket in group.get("buckets") or []:
            if not isinstance(bucket, dict):
                continue
            cadence = antigravity_bucket_label(bucket.get("displayName")
                                               or bucket.get("bucketId") or "")
            if cadence is None:
                continue
            remaining = bucket.get("remainingFraction")
            if not isinstance(remaining, (int, float)):
                continue
            label = f"{family} {cadence}"
            windows.append(window(
                f"ag_{len(windows)}", label, (1.0 - remaining) * 100.0,
                antigravity_reset_iso(bucket.get("resetTime"))))

    # Fallback fill: per-model buckets, clustered by remaining + reset.
    if per_model and isinstance(per_model.get("buckets"), list):
        clusters = {}
        for bucket in per_model["buckets"]:
            if not isinstance(bucket, dict):
                continue
            family = antigravity_model_family(bucket.get("modelId") or "")
            if family is None:
                continue
            reset = antigravity_reset_iso(bucket.get("resetTime"))
            key = (family, reset)
            if key not in clusters:
                clusters[key] = 1.0
            remaining = bucket.get("remainingFraction")
            if isinstance(remaining, (int, float)) and remaining < clusters[key]:
                clusters[key] = remaining
        for (family, reset), remaining in clusters.items():
            if reset is None:
                continue  # no reset timestamp → unknown cadence, skip
            cadence = "5h" if hours_until(reset, now_epoch) <= 6 else "Weekly"
            label = f"{family} {cadence}"
            if any(w["label"] == label for w in windows):
                continue  # the summary already covers this window
            windows.append(window(f"ag_{len(windows)}", label,
                                  (1.0 - remaining) * 100.0, reset))

    # Deduplicate, keeping the tightest (most used) entry per label.
    best = {}
    for w in windows:
        old = best.get(w["label"])
        if old is None or w["percent"] > old["percent"]:
            best[w["label"]] = w
    return [best[label] for label in sorted(best)]


def antigravity_reset_iso(value):
    if not isinstance(value, str) or not value:
        return ""
    try:
        stamp = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
        return stamp.astimezone(datetime.timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%S+00:00")
    except ValueError:
        return ""


def hours_until(iso, now_epoch):
    try:
        stamp = datetime.datetime.strptime(
            iso.split("+")[0], "%Y-%m-%dT%H:%M:%S")
        epoch = stamp.replace(tzinfo=datetime.timezone.utc).timestamp()
        return (epoch - now_epoch) / 3600.0
    except ValueError:
        return 1e9


def collect_antigravity():
    creds = antigravity_oauth_file()
    if not creds:
        return {"state": "unauthenticated",
                "detail": ("No Antigravity login. Save the OAuth client file in "
                            "~/.config/ai-limits/antigravity-oauth.json, or sign "
                           "in once with: agy (Antigravity / Google account)")}

    try:
        bearer = antigravity_access_token(creds)
    except Exception:
        return {"state": "token_expired",
                "detail": "Antigravity token refresh failed; sign in again (agy)"}
    if not bearer:
        return {"state": "token_expired",
                "detail": "Antigravity token refresh returned no access token"}

    project = creds.get("project_id") or ""
    try:
        summary = antigravity_post(bearer, "retrieveUserQuotaSummary",
                                   {"project": project})
        if not isinstance(summary, dict):
            summary = {}
    except Exception:
        summary = {}

    try:
        per_model = antigravity_post(bearer, "retrieveUserQuota",
                                     {"project": project})
    except Exception:
        per_model = None

    windows = antigravity_windows(summary, per_model, time.time())
    if not windows:
        return {"state": "error",
                "detail": ("Antigravity answered but reported no quota windows "
                           "(OAuth access may be denied for this account)")}
    return {"state": "ok", "detail": "Google Antigravity", "windows": windows}


# --- Command Code -----------------------------------------------------------

def commandcode_api_key():
    # 1. environment, 2. explicit file, 3. the cmd CLI's login file.
    if os.environ.get("COMMAND_CODE_API_KEY"):
        return os.environ["COMMAND_CODE_API_KEY"]
    key_file = os.path.join(HOME, ".config/ai-limits/commandcode-api-key")
    if os.path.isfile(key_file):
        try:
            with open(key_file) as f:
                key = f.read().strip()
            if key:
                return key
        except OSError:
            pass
    auth = load_json(os.path.join(HOME, ".commandcode/auth.json"))
    if isinstance(auth, dict):
        found = []

        def scan(value):
            if isinstance(value, str) and value.startswith("user_"):
                found.append(value)
            elif isinstance(value, dict):
                for inner in value.values():
                    scan(inner)
            elif isinstance(value, list):
                for inner in value:
                    scan(inner)

        scan(auth)
        if found:
            return found[0]
    return None


def commandcode_reset_iso(value):
    if isinstance(value, (int, float)):
        return iso_from_epoch(value)
    if isinstance(value, str) and value:
        return antigravity_reset_iso(value)
    return ""


def commandcode_percent(raw):
    if not isinstance(raw, dict):
        return None, ""
    try:
        cap = float(raw.get("cap") or 0)
    except (TypeError, ValueError):
        return None, ""
    if cap <= 0:
        return None, ""
    try:
        used = float(raw.get("used") or 0)
    except (TypeError, ValueError):
        used = 0.0
    return min(100.0, max(0.0, used / cap * 100.0)), commandcode_reset_iso(
        raw.get("resetAt"))


# Plan catalog from https://commandcode.ai/pricing (planId → monthly credits).
COMMANDCODE_PLANS = {
    "individual-go": ("Go", 10.0),
    "individual-go-v1": ("Go", 10.0),
    "individual-goat": ("GOAT", 70.0),
    "individual-pro": ("Pro", 30.0),
    "individual-pro-v1": ("Pro", 80.0),
    "individual-max": ("Max", 150.0),
    "individual-ultra": ("Ultra", 300.0),
}


def collect_commandcode():
    key = commandcode_api_key()
    if not key:
        return {"state": "unauthenticated",
                "detail": ("No Command Code key. Run: cmd login, or save a "
                           "user_... API key in "
                           "~/.config/ai-limits/commandcode-api-key")}

    status, data, _ = http_json(f"{COMMANDCODE_BASE}/billing/credits", {
        "Authorization": "Bearer " + key,
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
    })
    if status == 0:
        return {"state": "error", "detail": "Could not reach api.commandcode.ai"}
    if status == 429:
        return {"state": "rate_limited", "detail": "api.commandcode.ai is rate-limiting"}
    if status in (401, 403):
        return {"state": "unauthenticated", "detail": "Command Code key rejected"}
    if status != 200 or not isinstance(data, dict):
        return {"state": "error", "detail": f"Command Code returned HTTP {status}"}

    credits = data.get("credits")
    if not isinstance(credits, dict) or "monthlyCredits" not in credits:
        return {"state": "error", "detail": "Command Code returned no credits object"}

    limit_source = data.get("windowLimits")
    if not isinstance(limit_source, dict):
        limit_source = credits.get("windowLimits")
    if not isinstance(limit_source, dict):
        limit_source = {}

    windows = []
    for id_, raw_key, label in (("five_hour", "fiveHour", "5h"),
                                ("weekly", "weekly", "Weekly")):
        percent, reset = commandcode_percent(limit_source.get(raw_key))
        if percent is not None:
            windows.append(window(id_, label, percent, reset))

    # Monthly credit pool: percent of the grant consumed. The credits
    # response only reports what is left, so the grant comes from the plan
    # catalog via the subscriptions lookup (public pricing page values).
    remaining = credits.get("monthlyCredits")
    granted = None
    plan_name = "Command Code"
    try:
        status, sub, _ = http_json(f"{COMMANDCODE_BASE}/billing/subscriptions", {
            "Authorization": "Bearer " + key,
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        })
        if status == 200 and isinstance(sub, dict) and sub.get("success"):
            payload = sub.get("data")
            if isinstance(payload, dict):
                plan_id = str(payload.get("planId") or "").lower()
                if plan_id in COMMANDCODE_PLANS:
                    plan_name, granted = COMMANDCODE_PLANS[plan_id]
    except Exception:
        pass

    extra_info = None
    if isinstance(granted, (int, float)) and isinstance(remaining, (int, float)) \
            and granted > 0:
        used = max(0.0, granted - remaining)
        used_pct = min(100.0, max(0.0, used / granted * 100.0))
        windows.append(window("credits", "Credits", used_pct, ""))
        extra_info = {
            "label": "Monthly Credits",
            "enabled": True,
            "status": f"${remaining:.2f} left",
            "amount": f"${used:.2f} / ${granted:.2f}",
            "percent": round(used_pct, 1),
        }

    if not windows:
        return {"state": "error",
                "detail": "Command Code returned no readable windows"}
    result = {"state": "ok", "detail": plan_name, "windows": windows}
    if extra_info:
        result["extraUsage"] = extra_info
    return result


# --- Assembly ---------------------------------------------------------------

PROVIDERS = (
    ("claude", "Claude", collect_claude),
    ("codex", "Codex", collect_codex),
    ("opencode", "OpenCode Go", collect_opencode),
    ("zai", "Z.ai", collect_zai),
    ("antigravity", "Antigravity", collect_antigravity),
    ("commandcode", "Command Code", collect_commandcode),
)


def cache_path(provider_id):
    return os.path.join(CACHE_DIR, f"{provider_id}.json")


def collect_provider(provider_id, collector):
    try:
        result = collector()
        if not isinstance(result, dict):
            raise ValueError("collector returned a non-dict")
    except Exception as e:
        result = {"state": "error", "detail": f"{type(e).__name__}: {e}"}

    if result.get("state") == "ok":
        result["cached"] = False
        try:
            os.makedirs(CACHE_DIR, exist_ok=True)
            tmp = cache_path(provider_id) + ".tmp"
            with open(tmp, "w") as f:
                json.dump(result, f)
            os.replace(tmp, cache_path(provider_id))
        except OSError:
            pass
        return result

    cached = load_json(cache_path(provider_id))
    if isinstance(cached, dict) and cached.get("state") == "ok":
        cached["cached"] = True
        if not cached.get("detail") and result.get("plan"):
            cached["detail"] = result["plan"]
        if result.get("detail") and result.get("state") != "rate_limited":
            cached["notice"] = result["detail"]
        else:
            cached.pop("notice", None)
        return cached
    result["cached"] = False
    return result


def main():
    providers = []
    for provider_id, name, collector in PROVIDERS:
        result = collect_provider(provider_id, collector)
        result["id"] = provider_id
        result["name"] = name
        providers.append(result)

    print(json.dumps({"providers": providers, "_fetched_at": int(time.time())}))


if __name__ == "__main__":
    main()
