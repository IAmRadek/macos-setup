"""Kitty kitten for navi integration."""

import shutil
import subprocess

from kitty.boss import Boss


def main(args):
    # Find navi in PATH
    navi = shutil.which("navi")
    if not navi:
        return ""

    result = subprocess.run([navi, "--print"], capture_output=True, text=True)
    if result.returncode != 0:
        return ""
    return result.stdout


def handle_result(args, answer, target_window_id, boss: Boss):
    text = answer.strip()
    if not text:
        return
    w = boss.window_id_map.get(target_window_id)
    if w is not None:
        w.paste_text(text)
