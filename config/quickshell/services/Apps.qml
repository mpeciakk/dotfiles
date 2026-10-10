pragma Singleton

import QtQuick
import Quickshell
import "../lib/fuzzy.js" as F

// Desktop application index + fuzzy search over Quickshell's DesktopEntries.
// Self-contained (no fuzzysort/sqlite plugin): lib/fuzzy.js ranks the name by
// prefix/word start/substring/subsequence, with a weaker pass over comment/keywords.
Singleton {
    id: root

    readonly property var list: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    function launch(entry: DesktopEntry): void {
        if (entry)
            entry.execute();
    }

    // Score for a hit only in genericName/comment/keywords: below a name prefix/word start/
    // substring, above a scattered name subsequence (lib/fuzzy.js leaves 2000 free for this).
    readonly property int extraScore: 2000

    // Returns [{entry: DesktopEntry, ranges: [[start, end)]}], best match first; `ranges`
    // are the matched characters of entry.name (empty for the empty query and for
    // keyword/comment hits). Empty query lists everything alphabetically.
    function query(search: string): list<var> {
        const q = search.trim();
        if (q === "")
            return root.list.slice().sort((a, b) => a.name.localeCompare(b.name)).map(entry => ({
                        entry,
                        ranges: []
                    }));

        const scored = [];
        for (const entry of root.list) {
            const m = F.match(q, entry.name ?? "");
            if (m) {
                scored.push({
                    entry,
                    ranges: m.ranges,
                    score: m.score
                });
                continue;
            }
            const extra = [entry.genericName ?? "", entry.comment ?? "", (entry.keywords ?? []).join(" ")].join(" ").toLowerCase();
            if (extra.includes(q.toLowerCase()))
                scored.push({
                    entry,
                    ranges: [],
                    score: root.extraScore
                });
        }
        scored.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return scored.map(r => ({
                    entry: r.entry,
                    ranges: r.ranges
                }));
    }
}
