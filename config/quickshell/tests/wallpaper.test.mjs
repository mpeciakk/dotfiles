import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { strip } from "./qmljs.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = f => strip(readFileSync(join(root, f), "utf8"));

// The wallpaper Images of the desktop and of the lock's way in must request the same url + sourceSize, or the
// pixmap cache decodes the wallpaper once per Image instead of once. `ref` is the object that knows its screen
// and its window's pixel ratio in that file.
const IMAGES = [
    { file: "Wallpaper.qml", ref: "root" },
    { file: "LockOverlay.qml", ref: "over" },
];

const sourceSizeOf = ({ file, ref }) => {
    const m = src(file).match(/sourceSize\.width:[^\n]*\n\s*sourceSize\.height:[^\n]*/);
    assert.ok(m, `${file}: no wallpaper sourceSize`);
    return m[0].replace(/\s+/g, " ").replaceAll(ref, "@");
};

test("wallpaper sourceSize uses the window's real pixel ratio, not the screen's rounded-up one", () => {
    // Screen.devicePixelRatio is an integer (2 at scale 1.5): the decode would be 5120x2880 for a 3840x2160 output.
    for (const img of IMAGES) {
        const size = sourceSizeOf(img);
        assert.ok(!/screen\.devicePixelRatio/.test(size), `${img.file}: ${size}`);
        assert.ok(/devicePixelRatio/.test(size), `${img.file}: ${size}`);
    }
});

test("the desktop and the lock overlay request the same wallpaper sourceSize", () => {
    const [first, ...rest] = IMAGES.map(sourceSizeOf);
    for (const s of rest) assert.equal(s, first);
});

test("the lock surface's wallpaper asks the screen for its ratio: WlSessionLockSurface has none of its own", () => {
    // WlSessionLockSurface has only contentItem, visible, width, height and screen: surface.devicePixelRatio is
    // undefined in QML and the sourceSize would be NaN.
    const size = sourceSizeOf({ file: "Lock.qml", ref: "surface" });
    assert.ok(/screen\.devicePixelRatio/.test(size), size);
    assert.ok(!/surface\.devicePixelRatio/.test(size), size);
});

test("a hidden content layer (opacity 0) allocates no offscreen layer for the blur", () => {
    // Measured on pc: the layers of the four hidden-and-warmed states held 16-24 MiB of GPU memory.
    const m = src("IslandContent.qml").match(/layer\.enabled:[^\n]*/);
    assert.ok(m, "IslandContent has no layer.enabled");
    assert.match(m[0], /slot\.blur > 0/);
    assert.match(m[0], /slot\.opacity > 0/);
});
