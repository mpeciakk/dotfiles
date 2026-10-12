import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { strip } from "./qmljs.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const rest = strip(readFileSync(join(root, "states/Rest.qml"), "utf8"));
const smoke = readFileSync(join(root, "tests/smoke/22-notch.sh"), "utf8");

// Rest beside a notch (DESIGN W14). The layout is QML; these pin its wiring, the picture is the smoke shot.

test("Rest asks Theme for the notch of its own output", () => {
    assert.match(rest, /Theme\.notchFor\(root\.output\)/);
});

test("Rest keeps the notch's width empty and splits the rest evenly into the two sides", () => {
    assert.match(rest, /root\.notch\.w/);
    assert.match(rest, /\(root\.width - root\.notch\.w\) \/ 2/);
});

test("Rest has one badge, one clock and one dots Repeater in both layouts (the pieces are moved, not copied)", () => {
    assert.equal((rest.match(/text: Time\.timeStr/g) ?? []).length, 1);
    assert.equal((rest.match(/model: root\.dots/g) ?? []).length, 1);
    assert.equal((rest.match(/IslandState\.request\("center"\)/g) ?? []).length, 1);
});

test("22-notch smoke: the badge split is checked (restBadge 505 wide) and the shot is the last line", () => {
    assert.match(smoke, /notifs inject/);
    assert.match(smoke, /expect island targetW 505/);
    const lines = smoke.trimEnd().split("\n");
    assert.match(lines[lines.length - 1], /^shot notch$/);
});
