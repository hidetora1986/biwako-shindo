#!/usr/bin/env python3
"""Common AI development harness policy gate (stdlib only; no network/credentials)."""
from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any

VERSION = "1.0.0"
ALLOWED_KEYS = {"schema_version", "project", "harness_version", "forbidden_paths", "allow_paths", "review_required_paths", "native_ci_checks", "notes"}


def matches(path: str, patterns: list[str]) -> bool:
    name = path.replace("\\", "/").lstrip("/").lower()
    return any(fnmatch.fnmatchcase(name, pattern.lower()) or
               (pattern.startswith("**/") and fnmatch.fnmatchcase(name, pattern[3:].lower()))
               for pattern in patterns)


def read_config(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("project policy must be a JSON object")
    if data.get("schema_version") != 1:
        raise ValueError("unsupported schema_version; expected 1")
    if not isinstance(data.get("project"), str) or not data["project"].strip():
        raise ValueError("project must be a non-empty string")
    for key in ("forbidden_paths", "allow_paths", "review_required_paths", "native_ci_checks"):
        values = data.get(key, [])
        if not isinstance(values, list) or not all(isinstance(v, str) and v for v in values):
            raise ValueError(f"{key} must be a list of non-empty strings")
    unknown = set(data) - ALLOWED_KEYS
    if unknown:
        raise ValueError(f"unsupported policy keys: {', '.join(sorted(unknown))}")
    if not data.get("forbidden_paths"):
        raise ValueError("forbidden_paths must contain at least one pattern")
    return data


def changed_paths(repo: Path, base: str) -> list[str]:
    p = subprocess.run(["git", "-C", str(repo), "diff", "--name-only", "-z", f"{base}...HEAD"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if p.returncode:
        raise RuntimeError("git diff failed; ensure full history and a valid base ref (details deliberately omitted)")
    return sorted({v.decode("utf-8", errors="replace") for v in p.stdout.split(b"\0") if v})


def evaluate(config: dict[str, Any], repo: Path, files: list[str], *, diff_verified: bool) -> dict[str, Any]:
    forbidden = []
    review = []
    for path in files:
        if matches(path, config.get("allow_paths", [])):
            continue
        if matches(path, config.get("forbidden_paths", [])):
            forbidden.append(path)
        if matches(path, config.get("review_required_paths", [])):
            review.append(path)
    missing = []
    if not (repo / "AGENTS.md").is_file():
        missing.append("AGENTS.md")
    if not (repo / ".harness" / "project.json").is_file():
        missing.append(".harness/project.json")
    policy_pass = bool(diff_verified) and not forbidden and not missing
    return {
        "schema_version": 1,
        "harness_version": VERSION,
        "project": config["project"],
        "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "commit": os.getenv("GITHUB_SHA", "LOCAL_UNKNOWN"),
        "diff_verified": diff_verified,
        "changed_file_count": len(files),
        "forbidden_files": forbidden,
        "manual_review_files": review,
        "missing_required_files": missing,
        "policy_status": "PASS" if policy_pass else "BLOCKED",
        "native_ci_checks": config.get("native_ci_checks", []),
        "native_ci_status": "NOT_EVALUATED_BY_THIS_GATE",
        "human_approval": "REQUIRED",
        "release_status": "BLOCKED_PENDING_SEPARATE_GATES",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only common harness policy gate")
    ap.add_argument("mode", choices=("audit", "gate"))
    ap.add_argument("--repo", default=".")
    ap.add_argument("--config", default=".harness/project.json")
    ap.add_argument("--base", help="Git base ref (required for gate unless --changed-file is given)")
    ap.add_argument("--changed-file", action="append", default=None,
                    help="Explicit changed path; for local testing only, not CI")
    ap.add_argument("--report", default="artifacts/harness-report.json")
    args = ap.parse_args()
    repo = Path(args.repo).resolve()
    try:
        config = read_config(repo / args.config)
        if args.mode == "audit":
            files, verified = [], False
        elif args.changed_file is not None:
            if os.getenv("GITHUB_ACTIONS") == "true":
                raise ValueError("--changed-file is not allowed in GitHub Actions")
            files, verified = sorted(set(args.changed_file)), True
        else:
            base = args.base or (f"origin/{os.environ['GITHUB_BASE_REF']}" if os.getenv("GITHUB_BASE_REF") else None)
            if not base:
                raise ValueError("gate requires --base or GITHUB_BASE_REF")
            files, verified = changed_paths(repo, base), True
        result = evaluate(config, repo, files, diff_verified=verified)
        if args.mode == "audit":
            result["policy_status"] = "NOT_EVALUATED_AUDIT_ONLY"
        target = repo / args.report
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({"policy_status": result["policy_status"],
                          "release_status": result["release_status"],
                          "report": args.report, "forbidden": result["forbidden_files"],
                          "missing": result["missing_required_files"]}, ensure_ascii=False))
        return 0 if args.mode == "audit" or result["policy_status"] == "PASS" else 2
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        print(f"BLOCKED: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
