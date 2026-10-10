import { test } from "node:test";
import assert from "node:assert/strict";
import { load, plain } from "./qmljs.mjs";

const F = load("lib/fuzzy.js");

test("prefix beats word start beats subsequence", () => {
    const p = F.match("fi", "Firefox").score, w = F.match("fo", "Files Folder").score, s = F.match("fx", "Firefox").score;
    assert.ok(p > s && w > s);
    assert.ok(F.match("fi", "Firefox").score > F.match("fi", "Wifi Files").score);
});

test("ranks prefix > word start > substring > subsequence", () => {
    const prefix = F.match("fi", "Firefox").score;
    const word = F.match("fi", "Wifi Files").score;
    const sub = F.match("fi", "Wifi").score;
    const seq = F.match("fx", "Firefox").score;
    assert.ok(prefix > word && word > sub && sub > seq && seq > 0);
});

test("among equal tiers the shorter text wins", () => {
    assert.ok(F.match("fi", "Fi").score > F.match("fi", "Firefox").score);
    assert.ok(F.match("fo", "A Folder").score > F.match("fo", "A Very Long Folder").score);
});

test("ranges mark matched characters, merged", () => {
    assert.deepStrictEqual(plain(F.match("fire", "Firefox").ranges), [[0, 4]]);
    assert.deepStrictEqual(plain(F.match("ffx", "Firefox").ranges), [[0, 1], [4, 5], [6, 7]]);
});

test("a contiguous occurrence is highlighted in preference to scattered letters", () => {
    assert.deepStrictEqual(plain(F.match("ab", "a_xab").ranges), [[3, 5]]);
    assert.deepStrictEqual(plain(F.match("fo", "Files Folder").ranges), [[6, 8]]);
    assert.deepStrictEqual(plain(F.match("fi", "Wifi Files").ranges), [[5, 7]]);
    assert.deepStrictEqual(plain(F.match("fox", "Firefox").ranges), [[4, 7]]);
});

test("case-insensitive in both directions", () => {
    assert.deepStrictEqual(plain(F.match("FIRE", "firefox").ranges), [[0, 4]]);
    assert.deepStrictEqual(plain(F.match("fire", "FIREFOX").ranges), [[0, 4]]);
});

test("no match is null; empty query matches everything with no ranges", () => {
    assert.equal(F.match("zz", "Firefox"), null);
    assert.deepStrictEqual(plain(F.match("", "Firefox")), { score: 0, ranges: [] });
    assert.equal(F.match("firefoxx", "Firefox"), null);
    assert.equal(F.match("a", ""), null);
    assert.deepStrictEqual(plain(F.match("", "")), { score: 0, ranges: [] });
});

test("ranges are indices into the original text, with Polish diacritics", () => {
    assert.deepStrictEqual(plain(F.match("żół", "Żółw").ranges), [[0, 3]]);
    assert.deepStrictEqual(plain(F.match("w", "Żółw").ranges), [[3, 4]]);
    assert.deepStrictEqual(plain(F.match("ść", "Łódź Śćma").ranges), [[5, 7]]);
});

test("diacritics are not folded: plain letters do not match accented ones", () => {
    assert.equal(F.match("zol", "Żółw"), null);
});

test("case mapping that changes length keeps indices aligned", () => {
    assert.deepStrictEqual(plain(F.match("stan", "İstanbul").ranges), [[1, 5]]);
    assert.deepStrictEqual(plain(F.match("i", "İstanbul").ranges), [[0, 1]]);
    assert.deepStrictEqual(plain(F.match("ße", "Straße").ranges), [[4, 6]]);
});

test("word start follows a separator", () => {
    assert.ok(F.match("ed", "Text-Editor").score > F.match("ed", "Tedious").score);
    assert.deepStrictEqual(plain(F.match("ed", "Text-Editor").ranges), [[5, 7]]);
});

test("rank(): exact > prefix > word start > substring > extras > subsequence", () => {
    const scores = [
        F.rank("term", "Term", []),
        F.rank("term", "Terminal", []),
        F.rank("term", "Kitty Terminal", []),
        F.rank("term", "Xterm", []),
        F.rank("term", "Kitty", ["Terminal emulator"]),
        F.rank("term", "The Witcher 3: Wild Hunt - Remastered", [])
    ].map(r => r.score);
    for (let i = 1; i < scores.length; i++)
        assert.ok(scores[i - 1] > scores[i], `tier ${i - 1} > tier ${i}: ${scores}`);
});

test("rank(): an extras hit beats a pure name subsequence even when the name also subsequence-matches", () => {
    const name = "The Witcher 3: Wild Hunt - Remastered";
    assert.ok(F.match("term", name), "name is a subsequence match");
    const viaExtras = F.rank("term", name, ["terminal", "game"]);
    const pure = F.rank("term", name, ["game"]);
    assert.equal(viaExtras.score, 2000);
    assert.ok(viaExtras.score > pure.score);
    assert.deepStrictEqual(plain(viaExtras.ranges), plain(F.match("term", name).ranges));
});

test("rank(): extras-only hit has no ranges, is case-insensitive; no hit anywhere is null", () => {
    assert.deepStrictEqual(plain(F.rank("TERM", "kitty", ["Terminal"])), { score: 2000, ranges: [] });
    assert.equal(F.rank("term", "kitty", ["browser"]), null);
});

test("rank(): a name prefix/word-start/substring match is returned as-is, extras do not change it", () => {
    assert.deepStrictEqual(plain(F.rank("fi", "Firefox", ["fi"])), plain(F.match("fi", "Firefox")));
});

test("rank(): empty query matches with no ranges and no extras promotion", () => {
    assert.deepStrictEqual(plain(F.rank("", "Firefox", ["x"])), { score: 0, ranges: [] });
});
