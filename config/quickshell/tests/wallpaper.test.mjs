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

test("both Images of the desktop wallpaper's cross-fade request the same sourceSize", () => {
    // The old wallpaper moves to the back Image while the front still holds it: a cache hit only at the same size.
    const sizes = [...src("Wallpaper.qml").matchAll(/sourceSize\.width:[^\n]*\n\s*sourceSize\.height:[^\n]*/g)].map(m => m[0].replace(/\s+/g, " "));
    assert.equal(sizes.length, 2);
    assert.equal(sizes[0], sizes[1]);
});

test("the lock surface's wallpaper uses the island window's real ratio of its output, so it is the same cache hit", () => {
    // WlSessionLockSurface has no devicePixelRatio of its own (surface.devicePixelRatio is undefined: a NaN size), and
    // the screen's is rounded up (2 at 1.5): a 5120x2880 synchronous decode on every lock. The island window of the
    // same output reports its ratio (IslandState.ratioByOutput); the screen's is only the fallback before it has.
    const size = sourceSizeOf({ file: "Lock.qml", ref: "surface" });
    assert.ok(!/surface\.devicePixelRatio/.test(size), size);
    assert.match(size, /IslandState\.ratioByOutput\[\s*@\.screen\.name\s*\]\s*\?\?\s*@\.screen\.devicePixelRatio/);
    const island = src("Island.qml");
    assert.match(island, /IslandState\.reportRatio\(\s*root\.screen\.name\s*,\s*root\.devicePixelRatio\s*\)/);
    assert.match(island, /onDevicePixelRatioChanged:\s*IslandState\.reportRatio\(/);
});

test("a hidden content layer (opacity 0) allocates no offscreen layer for the blur", () => {
    // Measured on pc: the layers of the four hidden-and-warmed states held 16-24 MiB of GPU memory.
    const m = src("IslandContent.qml").match(/layer\.enabled:[^\n]*/);
    assert.ok(m, "IslandContent has no layer.enabled");
    assert.match(m[0], /slot\.blur > 0/);
    assert.match(m[0], /slot\.opacity > 0/);
});

test("the cross-fade hands the shown wallpaper back before retargeting the front, and only a settled one", () => {
    // back must take the old url while front still holds it (a cache hit), and front must be hidden before its
    // new source is set (a cache hit is Ready inside the assignment). Mid-change the back keeps what is shown.
    const m = src("Wallpaper.qml").match(/onUrlChanged:\s*\{([\s\S]*?)\n    \}/);
    assert.ok(m, "Wallpaper.qml: no onUrlChanged");
    const body = m[1];
    const at = re => { const i = body.search(re); assert.ok(i >= 0, `${re}`); return i; };
    assert.match(body, /if \(front\.status === Image\.Ready && !fade\.running\)\s*back\.source = front\.source;/);
    assert.ok(at(/back\.source = front\.source/) < at(/front\.source = root\.url/));
    assert.ok(at(/front\.opacity = 0/) < at(/front\.source = root\.url/));
});

test("no wallpaper until the host config has loaded: a start does not show the fallback first", () => {
    const theme = src("Theme.qml");
    assert.match(theme, /readonly property string wallpaper: \{\s*if \(!root\.hostLoaded\)\s*return "";/);
    assert.match(theme, /onLoaded: \{[\s\S]*?root\.hostLoaded = true;/);
    assert.match(theme, /onLoadFailed: \{[\s\S]*?root\.hostLoaded = true;/);
});
