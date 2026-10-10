.pragma library

// Fuzzy matcher for the launcher: case-insensitive, no diacritic folding.
// Tiers (higher is better): prefix 5000, word start 4000, contiguous substring 3000,
// scattered subsequence 1000. Each score is its tier minus a penalty capped at 999
// (shorter / earlier / tighter wins), so tiers never overlap; 2000 (EXTRA) is the weaker
// source (keywords/comment, see rank) ranked between substring and subsequence.

var PREFIX = 5000;
var WORD_START = 4000;
var SUBSTRING = 3000;
var EXTRA = 2000;
var SUBSEQUENCE = 1000;
var MAX_PENALTY = 999;
var SEPARATORS = " \t-_./:,;()[]&+";

// Lowercases one UTF-16 unit at a time and keeps only the first unit of the result, so
// the output has exactly the text's length ("İ".toLowerCase() is two units) and indices
// stay aligned with the original string.
function lower(s) {
    var out = "";
    for (var i = 0; i < s.length; i++)
        out += s.charAt(i).toLowerCase().charAt(0);
    return out;
}

function penalty(n) {
    return Math.min(n, MAX_PENALTY);
}

// Sorted char indices -> merged [start, end) runs.
function toRanges(indices) {
    var out = [];
    for (var i = 0; i < indices.length; i++) {
        var last = out.length - 1;
        if (last >= 0 && out[last][1] === indices[i])
            out[last][1] = indices[i] + 1;
        else
            out.push([indices[i], indices[i] + 1]);
    }
    return out;
}

function isWordStart(text, idx) {
    return idx === 0 || SEPARATORS.indexOf(text.charAt(idx - 1)) >= 0;
}

// -> {score, ranges: [[start, end)]} | null. Empty query matches anything with no ranges.
function match(query, text) {
    var q = lower(query);
    var t = lower(text);
    if (q.length === 0)
        return { score: 0, ranges: [] };
    if (q.length > t.length)
        return null;

    var first = -1;
    var from = 0;
    var at;
    while ((at = t.indexOf(q, from)) >= 0) {
        if (at === 0)
            return { score: PREFIX - penalty(t.length), ranges: [[0, q.length]] };
        if (isWordStart(text, at))
            return { score: WORD_START - penalty(at + t.length), ranges: [[at, at + q.length]] };
        if (first < 0)
            first = at;
        from = at + 1;
    }
    if (first >= 0)
        return { score: SUBSTRING - penalty(first + t.length), ranges: [[first, first + q.length]] };

    var indices = [];
    var j = 0;
    for (var i = 0; i < t.length && j < q.length; i++) {
        if (t.charAt(i) === q.charAt(j)) {
            indices.push(i);
            j++;
        }
    }
    if (j < q.length)
        return null;
    return { score: SUBSEQUENCE - penalty(indices[indices.length - 1] - indices[0] + 1), ranges: toRanges(indices) };
}

// Name match combined with a weaker source (genericName/comment/keywords): `extras` is an
// array of strings, hit when any contains the query (case-insensitive substring, joined by
// space). A hit scores EXTRA, above a scattered name subsequence even if the name also
// subsequence-matches (the name's ranges are kept), below a name substring or better.
// -> {score, ranges} | null.
function rank(query, name, extras) {
    var m = match(query, name);
    if (query.length === 0 || (m !== null && m.score > EXTRA))
        return m;
    if (extras.join(" ").toLowerCase().indexOf(query.toLowerCase()) >= 0)
        return { score: EXTRA, ranges: m !== null ? m.ranges : [] };
    return m;
}
