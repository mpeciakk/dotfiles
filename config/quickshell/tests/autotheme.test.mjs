import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const A = load("lib/autotheme.js", { Date });

const hours = d => d.getUTCHours() + d.getUTCMinutes() / 60;
const utc = (y, m, d, h = 12) => new Date(Date.UTC(y, m - 1, d, h));
const near = (got, want, tol, msg) => assert.ok(Math.abs(got - want) <= tol, `${msg}: ${got} vs ${want}`);

test("sunTimes(): equator at the March equinox is ~06:00/18:00 UTC", () => {
    const t = A.sunTimes(new Date(Date.UTC(2026, 2, 20, 12)), 0, 0);
    const h = d => d.getUTCHours() + d.getUTCMinutes() / 60;
    assert.ok(h(t.sunrise) > 5.9 && h(t.sunrise) < 6.25, String(t.sunrise));
    assert.ok(h(t.sunset) > 17.95 && h(t.sunset) < 18.3, String(t.sunset));
});

test("sunTimes(): polar day is null", () => {
    assert.equal(A.sunTimes(new Date(Date.UTC(2026, 5, 21, 12)), 78, 15), null);
});

test("sunTimes(): polar night is null", () => {
    assert.equal(A.sunTimes(utc(2026, 12, 21), 78, 15), null);
});

test("sunTimes(): Warsaw in June (CEST 04:15 / 21:00 = 02:15 / 19:00 UTC)", () => {
    const t = A.sunTimes(utc(2026, 6, 21), 52.2, 21.0);
    near(hours(t.sunrise), 2.25, 0.25, "sunrise");
    near(hours(t.sunset), 19.0, 0.25, "sunset");
});

test("sunTimes(): Warsaw in December (CET 07:40 / 15:25 = 06:40 / 14:25 UTC)", () => {
    const t = A.sunTimes(utc(2026, 12, 21), 52.2, 21.0);
    near(hours(t.sunrise), 6.667, 0.25, "sunrise");
    near(hours(t.sunset), 14.417, 0.25, "sunset");
});

test("sunTimes(): southern hemisphere has the seasons swapped (Sydney)", () => {
    const len = t => (t.sunset - t.sunrise) / 3600000;
    near(len(A.sunTimes(utc(2026, 6, 21), -33.87, 151.21)), 9.9, 0.4, "June day length");
    near(len(A.sunTimes(utc(2026, 12, 21), -33.87, 151.21)), 14.4, 0.4, "December day length");
});

test("sunTimes(): at lon 180 the day is the local solar one, its sunrise on the previous UTC day", () => {
    const noon = Date.UTC(2026, 2, 20, 0);     // local solar noon at lon 180
    const t = A.sunTimes(new Date(noon), 0, 180);
    assert.ok(t.sunrise < t.sunset);
    assert.ok(t.sunrise.getTime() <= noon && noon <= t.sunset.getTime(), "noon is inside the day");
    near(hours(t.sunrise), 18.0, 0.25, "sunrise UTC");
    assert.equal(t.sunrise.getUTCDate(), 19);
});

test("sunTimes(): at lon -180 the sunset falls on the next UTC day", () => {
    const noon = Date.UTC(2026, 2, 20, 23, 59);
    const t = A.sunTimes(new Date(noon), 0, -180);
    assert.ok(t.sunrise.getTime() <= noon && noon <= t.sunset.getTime());
    near(hours(t.sunrise), 18.0, 0.25, "sunrise UTC");
    assert.equal(t.sunset.getUTCDate(), 21);
});

test("sunTimes(): missing, NaN or out-of-range location is null", () => {
    const d = utc(2026, 6, 21);
    assert.equal(A.sunTimes(d, null, 21), null);
    assert.equal(A.sunTimes(d, 52, null), null);
    assert.equal(A.sunTimes(d, undefined, undefined), null);
    assert.equal(A.sunTimes(d, NaN, 21), null);
    assert.equal(A.sunTimes(d, 52, NaN), null);
    assert.equal(A.sunTimes(d, "", ""), null);
    assert.equal(A.sunTimes(d, 91, 0), null);
    assert.equal(A.sunTimes(d, 0, 181), null);
    assert.equal(A.sunTimes(new Date(NaN), 52, 21), null);
});

test("sunTimes(): numeric strings are accepted, other strings are not", () => {
    const num = A.sunTimes(utc(2026, 6, 21), 52.2, 21.0);
    const str = A.sunTimes(utc(2026, 6, 21), "52.2", "21.0");
    assert.equal(str.sunrise.getTime(), num.sunrise.getTime());
    assert.equal(A.sunTimes(utc(2026, 6, 21), "north", "21"), null);
});

test("luminance()", () => {
    assert.equal(A.luminance(0, 0, 0), 0);
    assert.ok(Math.abs(A.luminance(255, 255, 255) - 1) < 1e-9);
    assert.ok(A.luminance(0, 255, 0) > A.luminance(255, 0, 0));
});

test("luminance(): channels are sRGB-linearised, so mid grey is far below 0.5", () => {
    near(A.luminance(128, 128, 128), 0.2159, 0.001, "128 grey");
});

test("nextMode(): hysteresis", () => {
    assert.equal(A.nextMode("dark", 0.55, 0.6, 0.5), "dark");
    assert.equal(A.nextMode("dark", 0.65, 0.6, 0.5), "light");
    assert.equal(A.nextMode("light", 0.55, 0.6, 0.5), "light");
    assert.equal(A.nextMode("light", 0.45, 0.6, 0.5), "dark");
});

test("nextMode(): with no current mode the dead band splits at its middle", () => {
    assert.equal(A.nextMode("", 0.52, 0.6, 0.5), "dark");
    assert.equal(A.nextMode("", 0.58, 0.6, 0.5), "light");
    assert.equal(A.nextMode("", 0.9, 0.6, 0.5), "light");
    assert.equal(A.nextMode("", 0.1, 0.6, 0.5), "dark");
    assert.equal(A.nextMode(undefined, 0.1, 0.6, 0.5), "dark");
});

test("islandCrop(): the island's footprint in the image, the wallpaper being cover-cropped to the screen", () => {
    // 4000x2000 image on a 1000x1000 screen: scale 1/2, the screen shows the middle 2000 columns.
    assert.deepEqual(plain(A.islandCrop(4000, 2000, 1000, 1000, 200, 36)), { x: 1800, y: 0, width: 400, height: 72 });
    // 1000x2000 image on a 1000x1000 screen: scale 1, the screen shows the middle 1000 rows.
    assert.deepEqual(plain(A.islandCrop(1000, 2000, 1000, 1000, 200, 36)), { x: 400, y: 500, width: 200, height: 36 });
});

test("islandCrop(): an unusable size gives null", () => {
    assert.equal(A.islandCrop(0, 100, 1000, 1000, 200, 36), null);
    assert.equal(A.islandCrop(100, 100, 0, 1000, 200, 36), null);
});
