import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

// Source guards for the smoke scripts (tests/smoke/*.sh). niri posts a notification for every screenshot and the
// test instance is the notification daemon (CLAUDE.md gotcha 7): whatever is asserted after a `shot` can see a toast.

const dir = join(dirname(fileURLToPath(import.meta.url)), "smoke");
const smokes = readdirSync(dir).filter(f => f.endsWith(".sh")).map(f => ({
    name: f,
    lines: readFileSync(join(dir, f), "utf8").split("\n").map(l => l.trim()).filter(l => l !== "" && !l.startsWith("#"))
}));

test("smokes: a script with a shot ends on a shot, and asserts nothing after its first one", () => {
    const offenders = [];
    for (const { name, lines } of smokes) {
        const first = lines.findIndex(l => /^shot\s/.test(l));
        if (first < 0) continue;
        if (!/^shot\s/.test(lines[lines.length - 1])) offenders.push(`${name}: the last line is not a shot`);
        if (lines.slice(first + 1).some(l => /^expect\s/.test(l))) offenders.push(`${name}: expect after the first shot`);
    }
    assert.deepEqual(offenders, []);
});

test("smokes: 09-rest reads the unread count first and asserts relative to it", () => {
    const rest = smokes.find(s => s.name === "09-rest.sh").lines.join("\n");
    assert.doesNotMatch(rest, /expect notifs unread \d/, "an absolute unread count");
    assert.match(rest, /prop get notifs unread/);
    assert.match(rest, /expect notifs unread "?\$\(\(\s*\w+\s*\+\s*2\s*\)\)"?/);
});

// `notify-send` / `gdbus` talk to the session bus: on the user's bus they would hit the live shell's notification
// daemon. A smoke that uses them says `# smoke: private-bus` and smoke.sh then runs it under `dbus-run-session`,
// where the test instance owns org.freedesktop.Notifications.
const marker = /^# smoke: private-bus$/m;
const raw = name => readFileSync(join(dir, name), "utf8");

test("smokes: only a private-bus smoke may call notify-send or gdbus", () => {
    const offenders = smokes
        .filter(s => s.lines.some(l => /\b(notify-send|gdbus)\b/.test(l)) && !marker.test(raw(s.name)))
        .map(s => s.name);
    assert.deepEqual(offenders, []);
});

test("smokes: smoke.sh re-runs a private-bus smoke under dbus-run-session, once", () => {
    const sh = readFileSync(join(dir, "..", "smoke.sh"), "utf8");
    assert.match(sh, /grep -q '\^# smoke: private-bus\$' "\$1"/);
    assert.match(sh, /exec env WYSPA_PRIVATE_BUS=1 dbus-run-session -- "\$0" "\$@"/);
    assert.match(sh, /-z "\$\{WYSPA_PRIVATE_BUS:-\}"/);
});

test("smokes: 22-notifs-dbus drives replace, close and transient notifications over the private bus", () => {
    const s = smokes.find(x => x.name === "22-notifs-dbus.sh");
    assert.ok(s, "22-notifs-dbus.sh exists");
    assert.match(raw(s.name), marker);
    const text = s.lines.join("\n");
    assert.match(text, /notify-send -p /);
    assert.match(text, /notify-send -r /);
    assert.match(text, /notify-send -e /);
    assert.match(text, /CloseNotification/);
    assert.doesNotMatch(text, /^shot\s/m, "no shot: niri's screenshot notification is not on this bus, and nothing here needs one");
});
