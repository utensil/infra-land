#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# ///
"""
Mechanical LAN exposure audit and hardening helper for macOS.

This script intentionally avoids printing process names, arguments,
environment variables, config paths, or host-specific service names.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


PF_CONF = Path("/etc/pf.conf")
ALF_PLIST = "/Library/Preferences/com.apple.alf"
DEFAULT_ALLOWLIST = "54352"  # Apple Continuity/Handoff.


@dataclass(frozen=True)
class Listener:
    pid: str
    proto: str
    bind: str
    port: int
    scope: str


def run(cmd: list[str], *, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=check,
    )


def require_macos() -> None:
    if sys.platform != "darwin":
        raise SystemExit("This LAN hardening audit is macOS-only.")


def require_root() -> None:
    if os.geteuid() != 0:
        raise SystemExit("This action requires sudo/root.")


def parse_allowlist(value: str) -> set[int]:
    ports: set[int] = set()
    for part in re.split(r"[\s,]+", value.strip()):
        if not part:
            continue
        if not part.isdigit():
            raise SystemExit(f"Invalid allowlist port: {part}")
        port = int(part)
        if port < 1 or port > 65535:
            raise SystemExit(f"Allowlist port out of range: {part}")
        ports.add(port)
    return ports


def default_route_interface() -> str:
    proc = run(["route", "get", "default"])
    if proc.returncode != 0:
        return "en0"
    for line in proc.stdout.splitlines():
        line = line.strip()
        if line.startswith("interface:"):
            return line.split(":", 1)[1].strip()
    return "en0"


def parse_lsof_name(name: str) -> tuple[str, int] | None:
    endpoint = name.removeprefix("TCP ").split(" ", 1)[0]
    if endpoint.startswith("["):
        match = re.match(r"^\[(.*)\]:(\d+)$", endpoint)
        if not match:
            return None
        return match.group(1), int(match.group(2))
    if ":" not in endpoint:
        return None
    bind, port_text = endpoint.rsplit(":", 1)
    if not port_text.isdigit():
        return None
    return bind, int(port_text)


def scope_for_bind(bind: str) -> str:
    normalized = bind.lower()
    if normalized in {"127.0.0.1", "::1", "localhost"}:
        return "loopback"
    if normalized in {"*", "0.0.0.0", "::", "[::]"}:
        return "wildcard"
    return "interface"


def listeners() -> list[Listener]:
    proc = run(["lsof", "-iTCP", "-sTCP:LISTEN", "-P", "-n"])
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or "failed to list TCP listeners")

    found: list[Listener] = []
    for line in proc.stdout.splitlines()[1:]:
        cols = line.split()
        if len(cols) < 9:
            continue
        parsed = parse_lsof_name(" ".join(cols[8:]))
        if parsed is None:
            continue
        bind, port = parsed
        found.append(
            Listener(
                pid=cols[1],
                proto=cols[4],
                bind=bind,
                port=port,
                scope=scope_for_bind(bind),
            )
        )
    return sorted(found, key=lambda item: (item.scope, item.port, item.pid))


def firewall_state() -> tuple[str, str]:
    global_state = run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--getglobalstate"])
    stealth_state = run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--getstealthmode"])
    return (
        global_state.stdout.strip() or global_state.stderr.strip() or "unavailable",
        stealth_state.stdout.strip() or stealth_state.stderr.strip() or "unavailable",
    )


def pf_status() -> str:
    proc = run(["pfctl", "-s", "info"])
    if proc.returncode != 0:
        return "unavailable"
    for line in proc.stdout.splitlines():
        if line.strip().startswith("Status:"):
            return line.strip()
    return "available"


def pf_blocked_ports(lan_if: str) -> set[int]:
    proc = run(["pfctl", "-s", "rules"])
    if proc.returncode != 0:
        return pf_configured_ports(lan_if)
    return parse_pf_rules(proc.stdout, lan_if)


def pf_configured_ports(lan_if: str) -> set[int]:
    if not PF_CONF.exists():
        return set()
    return parse_pf_rules(PF_CONF.read_text(errors="replace"), lan_if)


def parse_pf_rules(text: str, lan_if: str) -> set[int]:
    blocked: set[int] = set()
    pattern = re.compile(
        rf"block(?:\s+\S+)*\s+in\s+on\s+{re.escape(lan_if)}\s+.*\s+port\s+(?:=\s+)?(\d+)"
    )
    for line in text.splitlines():
        match = pattern.search(line)
        if match:
            blocked.add(int(match.group(1)))
    return blocked


def exposed_items(allowlist: set[int]) -> list[Listener]:
    return [
        item
        for item in listeners()
        if item.scope != "loopback" and item.port not in allowlist
    ]


def print_audit(allowlist: set[int], lan_if: str) -> int:
    fw, stealth = firewall_state()
    blocked = pf_blocked_ports(lan_if)

    print("=== LAN Exposure Audit ===")
    print(f"Interface: {lan_if}")
    print(f"Allowlisted ports: {format_ports(allowlist)}")
    print(f"Firewall: {fw}")
    print(f"Stealth: {stealth}")
    print(f"PF: {pf_status()}")
    print(f"PF blocked ports on {lan_if}: {format_ports(blocked)}")
    print("")
    print("Scope      Status      Port   Proto  PID")
    print("---------  ----------  -----  -----  --------")

    remaining = 0
    for item in listeners():
        if item.scope == "loopback":
            status = "ok"
        elif item.port in allowlist:
            status = "allowed"
        elif item.port in blocked:
            status = "blocked"
        else:
            status = "exposed"
            remaining += 1
        print(
            f"{item.scope:<9}  {status:<10}  {item.port:<5}  "
            f"{item.proto:<5}  {item.pid:<8}"
        )

    print("")
    if remaining:
        print(f"Result: {remaining} non-allowlisted LAN-reachable listener(s) need protection.")
    else:
        print("Result: no unprotected non-allowlisted LAN listeners found.")
    return remaining


def format_ports(ports: set[int]) -> str:
    return ",".join(str(port) for port in sorted(ports)) if ports else "(none)"


def enable_firewall() -> None:
    run(["defaults", "write", ALF_PLIST, "globalstate", "-int", "1"], check=True)
    run(["defaults", "write", ALF_PLIST, "stealthenabled", "-int", "1"], check=True)
    run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--setglobalstate", "on"], check=True)
    run(["/usr/libexec/ApplicationFirewall/socketfilterfw", "--setstealthmode", "on"], check=True)
    run(["launchctl", "kickstart", "-k", "system/com.apple.alf.agent"])
    run(["launchctl", "kickstart", "-k", "system/com.apple.alf"])


def ensure_pf_blocks(ports: set[int], lan_if: str) -> None:
    if not ports:
        print("No PF rules needed.")
        return

    backup = PF_CONF.with_name(f"pf.conf.bak.{datetime.now():%Y%m%d-%H%M%S}")
    current = PF_CONF.read_text()
    updated = current
    for port in sorted(ports):
        rule = f"   block in on {lan_if} proto tcp from any to any port {port}"
        if rule not in updated.splitlines():
            updated = updated.rstrip() + "\n" + rule + "\n"

    with tempfile.NamedTemporaryFile("w", delete=False) as tmp:
        tmp.write(updated)
        tmp_path = Path(tmp.name)

    try:
        run(["pfctl", "-n", "-f", str(tmp_path)], check=True)
        shutil.copy2(PF_CONF, backup)
        PF_CONF.write_text(updated)
        status = pf_status()
        if "Enabled" in status:
            run(["pfctl", "-f", str(PF_CONF)], check=True)
        else:
            run(["pfctl", "-e", "-f", str(PF_CONF)], check=True)
        print(f"Backed up PF config to: {backup}")
    finally:
        tmp_path.unlink(missing_ok=True)


def fix_lan(allowlist: set[int], lan_if: str) -> int:
    require_root()
    enable_firewall()
    ports = {item.port for item in exposed_items(allowlist)}
    ensure_pf_blocks(ports, lan_if)
    return print_audit(allowlist, lan_if)


def main() -> int:
    require_macos()
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["audit", "strict", "fix", "verify"])
    parser.add_argument("--allowlist", default=DEFAULT_ALLOWLIST)
    parser.add_argument("--lan-if", default="")
    args = parser.parse_args()

    allowlist = parse_allowlist(args.allowlist)
    lan_if = args.lan_if.strip() or default_route_interface()

    if args.mode == "fix":
        return 1 if fix_lan(allowlist, lan_if) else 0

    remaining = print_audit(allowlist, lan_if)
    if args.mode in {"strict", "verify"} and remaining:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
