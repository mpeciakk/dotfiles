# shotfix report — tests/shot.sh stale-screenshot fix

Commit: 842f6aa quickshell: shot.sh waits for a fresh screenshot, never crops a stale one
Branch: worktree-feat+wyspa-shell (worktree /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell)
File changed: config/quickshell/tests/shot.sh (only this file)

## Change
1. `rm -f "$RAW" "/tmp/wyspa-shots/$1.png"` before `niri msg action screenshot-screen`.
2. Fixed `sleep 0.5` replaced by a poll: every 0.1 s, up to 50 polls (5 s). Ready when `$RAW` is non-empty and its size equals the previous poll. Never ready → `shot: niri produced no screenshot` to stderr, exit 1.
3. Lock guard, W/H lookup, SCALE, crop and output echo unchanged.

## Evidence

### (a) Syntax
```
$ bash -n tests/shot.sh; echo "bash -n exit=$?"
bash -n exit=0
```

### RED — original script, stale decoy, fake niri that writes nothing
Decoy: 10×10 PNG, mtime 2020-01-01. Fake niri (in /tmp only) answers `msg -j focused-output` with `{"logical":{"scale":1.0}}` and does nothing for the screenshot action. Fake qs exits 1 (no instance).
```
$ env PATH=/tmp/shotfix-fakes/bin:/usr/bin:/bin tests/shot.sh shotfix-red; echo "exit=$?"
/tmp/wyspa-shots/shotfix-red.png
exit=0
$ ls -l /tmp/wyspa-shots/shotfix-red.png ; PIL size
-rw-r--r-- 1 m m 76 2026-10-10 22:39:22 /tmp/wyspa-shots/shotfix-red.png
shotfix-red.png size: (10, 10)
```
Expected failure reproduced: exit 0, "fresh" mtime, content is a crop of the stale decoy.

### GREEN (failure path) — fixed script, same fake niri
```
$ env PATH=/tmp/shotfix-fakes/bin:/usr/bin:/bin tests/shot.sh shotfix-red; echo "exit=$?"
shot: niri produced no screenshot
exit=1          (elapsed ~5.4 s)
$ ls /tmp/wyspa-shots/shotfix-red*
ls: cannot access ... No such file or directory
```
Exit 1 with the required message after the timeout; the stale RAW and stale crop were removed by the `rm -f`.

### Staleness proof — live, one real screenshot (the only live shot in this task)
Decoy `/tmp/wyspa-shots/shotfix-check-full.png`: 10×10, mtime 2020-01-01 (`ls` showed `2020-01-01 00:00:00`, date then 2026-10-10 22:39:43).
```
$ tests/shot.sh shotfix-check; echo "exit=$?"
/tmp/wyspa-shots/shotfix-check.png
exit=0
$ ls -l --time-style=full-iso shotfix-check-full.png shotfix-check.png
-rw-r--r-- 1 m m 7213519 2026-10-10 22:39:50.187 /tmp/wyspa-shots/shotfix-check-full.png
-rw-r--r-- 1 m m 1272928 2026-10-10 22:39:50.802 /tmp/wyspa-shots/shotfix-check.png
full: (3840, 2160)  crop: (1500, 930)
```
- New full screenshot: mtime now, 3840×2160 (decoy was 10×10) — the decoy was replaced, not cropped.
- Crop check: crop box (1170, 0, 2670, 930) taken from the real full image; `ImageChops.difference(ref, crop).getbbox()` = `None` → pixel-identical.

Note: the crop check ran a `qs ipc -p … prop get island targetW` by hand; it printed "No running instances" and started nothing. The live shot itself used the script's default W/H (800/500), consistent with the 1500 px crop width at scale 1.5.

## Tests not run
No `smoke.sh` run: it launches Quickshell instances, which this task forbade. There is no other test suite for this script.

## Cleanup
- /tmp/shotfix-fakes (fake niri/qs) removed.
- Remaining in /tmp/wyspa-shots: `shotfix-check-full.png` and `shotfix-check.png` (live evidence). Nothing written to the repo beyond the commit.

## Concerns
- The stability check compares sizes only, as specified. A PNG written in stages with an identical size across two polls would pass; the live run had no such problem, but it is a heuristic, not a completeness check.
- The `shot.sh` script itself is still fully unchanged outside the four-line poll block, the rm line, and the removed `sleep 0.5`.
