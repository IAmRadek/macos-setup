# tasks.py
# Pure parameterized version (no env defaults).
# Usage:
#   inv -l
#   inv colima.start --profile=dev --cpu=4 --mem=8 --disk=20 --vm=qemu --k8s --gpu --arch=x86_64
#   inv colima.status --profile=dev
#   inv colima.nuke --profile=dev --yes

import json
from typing import List, Tuple
import shutil

from invoke import task, Collection


def _parse_hsize(s: str) -> float:
    s = s.strip()
    lower = s.lower()
    try:
        if lower.endswith("gb"):
            return float(lower[:-2]) * 1024**3
        if lower.endswith("mb"):
            return float(lower[:-2]) * 1024**2
        if lower.endswith("kb"):
            return float(lower[:-2]) * 1024
        if lower.endswith("b"):
            return float(lower[:-1])
        return float(lower)
    except Exception:
        return 0.0


def _extract_ports(j, wanted_profile: str) -> List[str]:
    lines: List[str] = []

    def walk(o):
        if isinstance(o, dict):
            name = o.get("name") or o.get("profile")
            if isinstance(name, str) and name == wanted_profile:
                # scan nested for host/port/proto triplets
                def deep(x):
                    if isinstance(x, dict):
                        if all(k in x for k in ("host", "port", "proto")):
                            lines.append(f"{x['proto']}://{x['host']}:{x['port']}")
                        else:
                            for v in x.values():
                                deep(v)
                    elif isinstance(x, list):
                        for it in x:
                            deep(it)
                deep(o)
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for it in o:
                walk(it)

    walk(j)
    return sorted(set(lines))

@task(default=True)
def help(c):
    """Show available tasks and usage."""
    c.run("inv -l", pty=True)

@task(
    help={
        "profile": "Colima profile name",
        "cpu": "vCPUs",
        "mem": "Memory in GB",
        "disk": "Disk in GB",
        "vm": "VM backend: vz|qemu",
        "k8s": "Enable Kubernetes",
        "gpu": "Enable GPU (vz/aarch64)",
        "arch": "Guest arch: x86_64|aarch64",
        "dns": "Custom DNS server",
        "mirror": "Docker registry mirror URL",
    }
)
def start(c,
          profile="default",
          cpu=4, mem=6, disk=5, vm="vz",
          k8s=False, gpu=False,
          arch="", dns="", mirror=""):
    """Start Colima and set Docker/K8s contexts."""
    args = [
        "colima", "start",
        "--profile", profile,
        "--cpu", str(cpu),
        "--memory", str(mem),
        "--disk", str(disk),
        "--vm-type", vm,
    ]
    if arch:
        args += ["--arch", arch]
    if k8s:
        args.append("--kubernetes")
    if gpu:
        args.append("--gpu")
    if dns:
        args += ["--dns", dns]
    if mirror:
        args += ["--registry-mirror", mirror]

    print("→", " ".join(args))
    c.run(" ".join(args), pty=True)

    if shutil.which("docker"):
        c.run(f"docker context use colima-{profile}", warn=True, hide=True)
        c.run("docker context use colima", warn=True, hide=True)
    if shutil.which("kubectl") and k8s:
        c.run(f"kubectl config use-context colima-{profile}", warn=True, hide=True)

    status(c, profile=profile)


@task(help={"profile": "Colima profile"})
def stop(c, profile="default"):
    """Stop Colima."""
    print(f"→ colima stop --profile {profile}")
    c.run(f"colima stop --profile {profile}", pty=True)


@task(help={"profile": "Colima profile"})
def restart(c, profile="default"):
    """Restart Colima."""
    print(f"→ colima restart --profile {profile}")
    c.run(f"colima restart --profile {profile}", pty=True)


@task(help={"profile": "Colima profile"})
def status(c, profile="default"):
    """Show Colima status and Docker/K8s contexts."""
    c.run(f"colima status --profile {profile}", warn=True, pty=True)
    if shutil.which("docker"):
        r = c.run("docker context show", warn=True, hide=True)
        ctx = r.stdout.strip() if r.ok else "n/a"
        print(f"Docker context: {ctx}")
    if shutil.which("kubectl"):
        r = c.run("kubectl config current-context", warn=True, hide=True)
        if r.ok and r.stdout.strip():
            print(r.stdout.strip())


@task(help={"profile": "Colima profile"})
def logs(c, profile="default"):
    """Show Colima logs."""
    c.run(f"colima logs --profile {profile}", pty=True)


@task
def prune(c):
    """Docker prune (incl. volumes) + builder prune."""
    print("→ docker system prune -f --volumes")
    c.run("docker system prune -f --volumes", warn=True, pty=True)
    print("→ docker builder prune -f")
    c.run("docker builder prune -f", warn=True, pty=True)


@task(help={"profile": "Colima profile", "yes": "Skip confirmation"})
def nuke(c, profile, yes=False):
    """STOP and DELETE the Colima profile (DANGEROUS)."""
    if not yes:
        try:
            ans = input(f"This will STOP and DELETE Colima profile '{profile}'. Continue? (y/N) ").strip().lower()
        except EOFError:
            ans = "n"
        if ans != "y":
            print("Aborted.")
            return
    c.run(f"colima stop --profile {profile}", warn=True, pty=True)
    c.run(f"colima delete --profile {profile}", pty=True)


@task(help={"profile": "Colima profile"})
def ssh(c, profile="default"):
    """SSH into the Colima VM."""
    c.run(f"colima ssh --profile {profile}", pty=True)


@task
def images(c):
    """List Docker images by size (desc)."""
    r = c.run('docker images --format "{{.Repository}}:{{.Tag}}\\t{{.Size}}"', warn=True, hide=True)
    if not r.ok:
        return
    rows: List[Tuple[str, str, float]] = []
    for line in r.stdout.strip().splitlines():
        if "\t" not in line:
            continue
        name, size = line.split("\t", 1)
        rows.append((name, size, _parse_hsize(size)))
    for name, size, _ in sorted(rows, key=lambda t: t[2], reverse=True):
        print(f"{name}\t{size}")


@task(help={"profile": "Colima profile"})
def ports(c, profile="default"):
    """Show forwarded ports as proto://host:port."""
    r = c.run("colima list --json", warn=True, hide=True)
    if not r.ok or not r.stdout.strip():
        return
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        print(r.stdout.strip())
        return
    for line in _extract_ports(data, profile):
        print(line)


# ----------------- namespace -----------------
ns = Collection()
for f in ():
    ns.add_task(f)
