#!/usr/bin/env python3
"""Print the Deploy (deploy.com) organization credit balance as JSON.

Deploy has no documented balance API and rejects API keys on this route, so
this calls the endpoint its web portal uses, authenticated with a portal session
cookie. The route is unofficial and may change; the session expires eventually.

Cookie source, first match wins:
  --cookie-file PATH
  $DEPLOY_PORTAL_COOKIE
  ~/.config/ai-limits/deploy-cookie   (keep it chmod 600)
The value is the Cookie request header copied from a logged-in portal.deploy.com
request. It is never printed.

Always prints one JSON object. Exit status is 0 only when state is "ok".
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

API_HOST = "https://ajax-portal.deploy.com/"
DEFAULT_COOKIE_FILE = os.path.expanduser("~/.config/ai-limits/deploy-cookie")
REQUEST_TIMEOUT = 15


class Failure(Exception):
    def __init__(self, state, detail):
        super().__init__(detail)
        self.state = state
        self.detail = detail


def load_cookie(path):
    if path:
        candidates = [path]
    else:
        env = os.environ.get("DEPLOY_PORTAL_COOKIE", "").strip()
        if env:
            return env
        candidates = [DEFAULT_COOKIE_FILE]
    try:
        with open(candidates[0]) as f:
            cookie = f.read().strip()
    except OSError:
        cookie = ""
    if not cookie:
        raise Failure("unauthenticated",
                      "No portal session cookie. Set DEPLOY_PORTAL_COOKIE or write "
                      f"it to {DEFAULT_COOKIE_FILE}.")
    return cookie


def get_json(path, cookie):
    req = urllib.request.Request(API_HOST + path, headers={
        "Cookie": cookie,
        "Accept": "application/json",
        "Origin": "https://portal.deploy.com",
        "Referer": "https://portal.deploy.com/",
        "User-Agent": "ai-limits/0.2",
    })
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            body = resp.read()
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            raise Failure("unauthenticated",
                          f"Portal rejected the session (HTTP {e.code}). "
                          "Log in again and refresh the cookie.") from None
        raise Failure("error", f"Portal returned HTTP {e.code}") from None
    except OSError as e:
        raise Failure("error", f"Could not reach the portal: {type(e).__name__}") from None
    try:
        return unwrap(json.loads(body))
    except ValueError:
        raise Failure("error", "Portal returned a response that is not JSON") from None


def unwrap(payload):
    """The portal wraps responses as {status_code, message, data}."""
    if isinstance(payload, dict) and "data" in payload and "status_code" in payload:
        return payload["data"]
    return payload


def find_organization(payload, org_id):
    if isinstance(payload, dict):
        orgs = payload.get("organizations") or payload.get("results") or [payload]
    else:
        orgs = payload
    orgs = [o for o in orgs or [] if isinstance(o, dict) and o.get("id") is not None]
    if org_id is not None:
        orgs = [o for o in orgs if str(o["id"]) == str(org_id)]
    if not orgs:
        raise Failure("error", "No matching organization on this account")
    if org_id is None and len(orgs) > 1:
        ids = ", ".join(str(o["id"]) for o in orgs)
        raise Failure("error", f"Several organizations ({ids}); choose one with --org-id")
    return orgs[0]


def read_balance(payload):
    """Return the balance; a missing value is an error, never a silent 0."""
    info = payload.get("billing_info") if isinstance(payload, dict) else None
    balance = info.get("balance") if isinstance(info, dict) else None
    if isinstance(balance, str):
        try:
            balance = float(balance)
        except ValueError:
            balance = None
    if isinstance(balance, bool) or not isinstance(balance, (int, float)):
        raise Failure("error", "Portal response has no billing_info.balance; "
                               "the unofficial route may have changed")
    return balance


def collect(cookie, org_id):
    org = find_organization(get_json("api/organization", cookie), org_id)
    balance = read_balance(get_json(f"api/organization/{org['id']}/balance", cookie))
    return {
        "state": "ok",
        "organizationId": org["id"],
        "organization": org.get("name"),
        "paymentModel": org.get("payment_model"),
        "balance": balance,
    }


def main():
    parser = argparse.ArgumentParser(description="Print the Deploy credit balance as JSON.")
    parser.add_argument("--org-id", help="organization id, if the account has several")
    parser.add_argument("--cookie-file", help="file holding the portal Cookie header")
    args = parser.parse_args()

    try:
        result = collect(load_cookie(args.cookie_file), args.org_id)
    except Failure as e:
        result = {"state": e.state, "detail": e.detail}
    result["provider"] = "deploy"
    result["fetchedAt"] = int(time.time())
    print(json.dumps(result))
    return 0 if result["state"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
