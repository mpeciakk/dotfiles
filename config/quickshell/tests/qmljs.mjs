import { readFileSync } from "node:fs";
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
