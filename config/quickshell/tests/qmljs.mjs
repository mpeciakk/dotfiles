import { readFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

// Loads a QML JS library (`.pragma library`) into a fresh context. Top-level
// `function`s and `var`s become properties of the returned context.
export function load(rel, extra = {}) {
    const file = join(root, rel);
    const src = readFileSync(file, "utf8").replace(/^\s*\.pragma\s+library\s*$/m, "");
    const ctx = vm.createContext({ console, ...extra });
    vm.runInContext(src, ctx, { filename: file });
    return ctx;
}

// Objects from the vm context have a foreign prototype; normalise before deepStrictEqual.
export const plain = x => JSON.parse(JSON.stringify(x));

// ---- Source guards: the QML files and lib/*.js as comment-free text ----

// Comments are dropped (a `//` inside a string such as "http://" stays: it follows no whitespace).
export const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|\s)\/\/.*$/gm, "$1");

// Every .qml under the config dir, `docs` and `tests` at the top level excluded.
export function qmlFiles(dir = root) {
    const out = [];
    for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.isDirectory()) {
            if (dir === root && (e.name === "docs" || e.name === "tests")) continue;
            out.push(...qmlFiles(join(dir, e.name)));
        } else if (e.name.endsWith(".qml")) {
            out.push(join(dir, e.name));
        }
    }
    return out;
}

// Every lib/*.js.
export const jsFiles = () => readdirSync(join(root, "lib")).filter(f => f.endsWith(".js")).map(f => join(root, "lib", f));

// The span of the first `function <name>(…) { … }`.
export function functionSpan(code, name) {
    const start = code.search(new RegExp(`function\\s+${name}\\s*\\(`));
    if (start < 0) return null;
    const open = code.indexOf("{", start);
    let depth = 0;
    for (let i = open; i < code.length; i++) {
        if (code[i] === "{") depth++;
        else if (code[i] === "}" && --depth === 0) return { start, end: i + 1 };
    }
    return null;
}
