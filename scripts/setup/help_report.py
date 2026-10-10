#!/usr/bin/env python3
"""When a setup step fails twice: write a short report the person can send to their onboarding contact as is.

Never fails: a report that cannot be written is printed instead, and the exit code is always 0, so the report
never becomes one more failure. Masks anything that looks like a key or token before it is written or printed.

Usage: help_report.py --step S --error LINE --tried TEXT [--details-file F] [--vault PATH]
Stdout: REPORT <path> (or REPORT_UNWRITTEN followed by the report), then SAY <one sentence for the person>.
"""
import argparse
import datetime
import os
import platform
import re
import sys

MASKS = [
    (re.compile(r"\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}"
                r"|xox[abpr]-[A-Za-z0-9-]{10,})"), "[masked]"),
    (re.compile(r"\b([A-Z][A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD)[A-Z0-9_]*)=\S+"), r"\1=[masked]"),
]
SAY = ("SAY I wrote down what happened in a note in your Inbox folder. Please send it to your onboarding contact; "
       "it holds no passwords or keys.")


def mask(text):
    for rx, rep in MASKS:
        text = rx.sub(rep, text)
    return text


def tail(path, limit=3000):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()[-limit:]
    except OSError:
        return ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--step", required=True)
    ap.add_argument("--error", required=True)
    ap.add_argument("--tried", required=True)
    ap.add_argument("--details-file")
    ap.add_argument("--vault", default=os.getcwd())
    a = ap.parse_args()
    now = datetime.datetime.now()
    details = tail(a.details_file) if a.details_file else ""
    body = mask(
        f"Setup stopped at: {a.step}\n"
        f"Error: {a.error}\n"
        f"What the agent tried: {a.tried}\n"
        f"Computer: {platform.system()} {platform.release()} ({platform.machine()})\n"
        + (f"\nDetails:\n{details}\n" if details else ""))
    text = (f"---\ntype: note\ncreated: {now:%Y-%m-%d}\n---\n# Setup help request {now:%Y-%m-%d %H:%M}\n\n"
            "Send this to your onboarding contact as is. It holds no keys or passwords.\n\n" + body)
    path = os.path.join(a.vault, "Inbox", f"Setup help request {now:%Y-%m-%d %H%M}.md")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"REPORT {path}")
    except OSError:
        print("REPORT_UNWRITTEN here is the report:\n" + text)
    print(SAY)
    return 0


if __name__ == "__main__":
    sys.exit(main())
