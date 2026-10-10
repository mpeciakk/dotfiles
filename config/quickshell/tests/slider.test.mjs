import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain } from "./qmljs.mjs";

const S = load("lib/slider.js");
const STEP = 0.05;
const near = (a, b) => assert.ok(Math.abs(a - b) < 1e-9, `${a} !~ ${b}`);

test("wheel: a full notch (120) moves one step, up or down", () => {
    near(S.wheelFraction(0.5, 120, STEP, 0), 0.55);
    near(S.wheelFraction(0.5, -120, STEP, 0), 0.45);
});

test("wheel: smooth-scroll deltas move a proportional part of a step", () => {
    near(S.wheelFraction(0.5, 15, STEP, 0), 0.5 + STEP / 8);
    near(S.wheelFraction(0.5, 30, STEP, 0), 0.5 + STEP / 4);
    near(S.wheelFraction(0.5, -30, STEP, 0), 0.5 - STEP / 4);
});

test("wheel: a zero delta (horizontal tilt) is ignored, not read as a step down", () => {
    assert.equal(S.wheelFraction(0.5, 0, STEP, 0), null);
    assert.equal(S.wheelFraction(0.5, NaN, STEP, 0), null);
    assert.equal(S.wheelFraction(0.5, undefined, STEP, 0), null);
});

test("wheel: the result stays within [min, 1]", () => {
    assert.equal(S.wheelFraction(0.98, 120, STEP, 0), 1);
    assert.equal(S.wheelFraction(0.02, -120, STEP, 0), 0);
    assert.equal(S.wheelFraction(0.07, -120, STEP, 0.05), 0.05);
});

test("wheel: a brightness floor is never crossed and never raises on wheel-down", () => {
    assert.equal(S.wheelFraction(0.05, -120, STEP, 0.05), 0.05);
    assert.equal(S.wheelFraction(0.02, -120, STEP, 0.05), null);
    near(S.wheelFraction(0.02, 120, STEP, 0.05), 0.07);
});

test("wheel: steps from the value the caller passes (muted volume starts from the stored level)", () => {
    // Audio.volume is 0.3 while muted; the caller passes it, not the displayed 0.
    near(S.wheelFraction(0.3, 120, STEP, 0), 0.35);
    near(S.wheelFraction(0.3, -120, STEP, 0), 0.25);
});

test("wheel: above 1.0 (overamplified) up leaves it alone, down steps from the real value, capped at 1", () => {
    assert.equal(S.wheelFraction(1.2, 120, STEP, 0), null);
    assert.equal(S.wheelFraction(1.2, -120, STEP, 0), 1);
    near(S.wheelFraction(1.0, -120, STEP, 0), 0.95);
});

test("drag: the pointer position as a fraction of the track, clamped to [min, 1]", () => {
    assert.equal(S.dragFraction(50, 200, 0), 0.25);
    assert.equal(S.dragFraction(-10, 200, 0), 0);
    assert.equal(S.dragFraction(250, 200, 0), 1);
    assert.equal(S.dragFraction(0, 200, 0.05), 0.05);
    assert.equal(S.dragFraction(-30, 200, 0.05), 0.05);
});

test("drag: a track without width gives nothing", () => {
    assert.equal(S.dragFraction(10, 0, 0), null);
    assert.equal(S.dragFraction(NaN, 200, 0), null);
});

test("coalescer: idle sends nothing and is not cooling", () => {
    assert.deepStrictEqual(plain(S.idle()), { pending: null, cooling: false, last: null });
});

test("coalescer: the first request goes out at once and starts a cooldown", () => {
    const r = plain(S.request(S.idle(), 0.4));
    assert.equal(r.send, 0.4);
    assert.deepStrictEqual(r.state, { pending: null, cooling: true, last: 0.4 });
});

test("coalescer: requests during the cooldown only keep the last one pending", () => {
    const s = S.request(S.idle(), 0.4).state;
    let r = plain(S.request(s, 0.5));
    assert.equal(r.send, null);
    r = plain(S.request(S.request(s, 0.5).state, 0.6));
    assert.equal(r.send, null);
    assert.deepStrictEqual(r.state, { pending: 0.6, cooling: true, last: 0.6 });
});

test("coalescer: a tick sends the last pending value and keeps cooling; an empty tick ends the cooldown", () => {
    const s = S.request(S.request(S.idle(), 0.4).state, 0.6).state;
    let t = plain(S.tick(s));
    assert.equal(t.send, 0.6);
    assert.deepStrictEqual(t.state, { pending: null, cooling: true, last: 0.6 });
    t = plain(S.tick(S.tick(s).state));
    assert.equal(t.send, null);
    assert.equal(t.state.cooling, false);
});

test("coalescer: flush (release) sends the pending value now, and nothing when none is pending", () => {
    const s = S.request(S.request(S.idle(), 0.4).state, 0.7).state;
    const f = S.flush(s);
    assert.equal(f.send, 0.7);
    assert.equal(f.state.pending, null);
    assert.equal(S.flush(f.state).send, null);
    assert.equal(S.flush(S.idle()).send, null);
});

test("coalescer: the wheel base is the last requested value while cooling, the real one otherwise", () => {
    assert.equal(S.base(S.idle(), 0.3), 0.3);
    const s = S.request(S.idle(), 0.6).state;
    assert.equal(S.base(s, 0.3), 0.6);
    const done = S.tick(S.tick(s).state).state;
    assert.equal(S.base(done, 0.3), 0.3);
});

test("coalescer: it does not mutate the state it was given", () => {
    const s = S.idle();
    S.request(s, 0.5);
    assert.deepStrictEqual(plain(s), { pending: null, cooling: false, last: null });
});

test("control panel: no code path writes the Wi-Fi or Bluetooth radio state", () => {
    const here = dirname(fileURLToPath(import.meta.url));
    const src = readFileSync(join(here, "..", "states", "Control.qml"), "utf8").replace(/\/\/.*$/gm, "");
    assert.doesNotMatch(src, /wifiEnabled\s*=[^=]/);
    assert.doesNotMatch(src, /\.enabled\s*=[^=]/);
});
