pragma Singleton

import QtQuick
import Quickshell

// Desktop application index + fuzzy search over Quickshell's DesktopEntries.
// Self-contained (no fuzzysort/sqlite plugin): a small JS scorer ranks by name
// prefix/substring/subsequence, with a weaker pass over comment/keywords.
Singleton {
    id: root

    readonly property var list: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    function launch(entry: DesktopEntry): void {
        if (entry)
            entry.execute();
    }

    // Returns matching DesktopEntry objects, best match first. Empty query lists
    // everything alphabetically.
    function query(search: string): list<var> {
        const q = search.trim().toLowerCase();
        if (q === "")
            return root.list.slice().sort((a, b) => a.name.localeCompare(b.name));

        const scored = [];
        for (const app of root.list) {
            const s = root.score(app, q);
            if (s > 0)
                scored.push({
                    app,
                    s
                });
        }
        scored.sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name));
        return scored.map(e => e.app);
    }

    function score(app: var, q: string): int {
        const name = (app.name ?? "").toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 600 - name.length;
        const idx = name.indexOf(q);
        if (idx >= 0)
            return 300 - idx;

        const extra = [app.genericName ?? "", app.comment ?? "", (app.keywords ?? []).join(" ")].join(" ").toLowerCase();
        if (extra.includes(q))
            return 100;
        if (root.subsequence(q, name))
            return 40;
        return 0;
    }

    // Does `q` appear in `text` as an in-order subsequence? (fuzzy "gimp" -> "GNU…")
    function subsequence(q: string, text: string): bool {
        let i = 0;
        for (let j = 0; j < text.length && i < q.length; j++)
            if (text[j] === q[i])
                i++;
        return i === q.length;
    }
}
