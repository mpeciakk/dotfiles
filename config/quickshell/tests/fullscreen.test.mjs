import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const F = load("lib/fullscreen.js");
const tl = (title, screens, fullscreen = true) => ({ title, appId: "mpv", screens, fullscreen });
const win = (title, workspace_id) => ({ title, app_id: "mpv", workspace_id });

test("fullscreen window on the active workspace marks its output", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("film", 1)], { "DP-2": 1 })), ["DP-2"]);
});

test("fullscreen window on an inactive workspace does not", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("film", 2)], { "DP-2": 1 })), []);
});

test("non-fullscreen and other outputs", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("a", ["DP-2"], false)], [win("a", 1)], { "DP-2": 1 })), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("b", ["HDMI-A-1"])], [win("b", 5)], { "DP-2": 1, "HDMI-A-1": 5 })), ["HDMI-A-1"]);
});

test("a toplevel on several screens marks each whose active workspace holds the window", () => {
    const active = { "DP-2": 1, "HDMI-A-1": 5 };
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("x", ["DP-2", "HDMI-A-1"])], [win("x", 5)], active)), ["HDMI-A-1"]);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("x", ["DP-2", "HDMI-A-1"])], [win("x", 1), win("x", 5)], active)), ["DP-2", "HDMI-A-1"]);
});

test("same title and appId on two workspaces: any match on the active workspace wins", () => {
    const windows = [win("dup", 2), win("dup", 1)];
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("dup", ["DP-2"])], windows, { "DP-2": 1 })), ["DP-2"]);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("dup", ["DP-2"])], windows, { "DP-2": 3 })), []);
});

test("title and appId must both match", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [{ title: "film", app_id: "vlc", workspace_id: 1 }], { "DP-2": 1 })), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("other", 1)], { "DP-2": 1 })), []);
});

test("an output is listed once, however many toplevels qualify", () => {
    const toplevels = [tl("a", ["DP-2"]), tl("b", ["DP-2"])];
    assert.deepStrictEqual(plain(F.fullscreenOutputs(toplevels, [win("a", 1), win("b", 1)], { "DP-2": 1 })), ["DP-2"]);
});

test("an output without an active workspace is never fullscreen", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [win("film", 1)], {})), []);
});

test("a window without a workspace never matches", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [{ title: "film", app_id: "mpv", workspace_id: null }], { "DP-2": 1 })), []);
});

test("a window without workspace_id does not match an output without an active workspace", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([tl("film", ["DP-2"])], [{ title: "film", app_id: "mpv" }], {})), []);
});

test("empty, null and malformed inputs give no outputs", () => {
    assert.deepStrictEqual(plain(F.fullscreenOutputs([], [], {})), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs(null, null, null)), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs(undefined, [win("a", 1)], { "DP-2": 1 })), []);
    const noScreens = { title: "film", appId: "mpv", fullscreen: true };
    assert.deepStrictEqual(plain(F.fullscreenOutputs([noScreens], [win("film", 1)], { "DP-2": 1 })), []);
    assert.deepStrictEqual(plain(F.fullscreenOutputs([null, tl("film", ["DP-2"])], [null, win("film", 1)], { "DP-2": 1 })), ["DP-2"]);
});

test("guard: the niri wyspa layer-rule renders nothing without a region (no saturation, no blur true)", async () => {
    const { readFileSync } = await import("node:fs");
    const kdl = readFileSync(new URL("../../niri/window_rules.kdl", import.meta.url), "utf8").replace(/\/\/.*$/gm, "");
    const rule = /layer-rule\s*\{\s*match namespace="\^wyspa\$"[\s\S]*?\n\}/.exec(kdl);
    assert.ok(rule, "wyspa layer-rule present");
    // In line mode the island sets no blur region; any of these then covers the whole full-screen surface.
    assert.doesNotMatch(rule[0], /\bsaturation\b|\bblur\s+true\b|\bnoise\b/);
});
