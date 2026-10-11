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
