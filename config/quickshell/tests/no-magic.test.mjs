import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const ALLOWED = new Set(["0", "1", "2", "0.5"]);

function uiFiles() {
    const files = readdirSync(root).filter(f => f.endsWith(".qml") && f !== "Theme.qml");
    for (const d of ["states", "components", "modules"]) {
        const p = join(root, d);
        if (existsSync(p))
            for (const f of readdirSync(p))
                if (f.endsWith(".qml")) files.push(join(d, f));
    }
    return files;
}

const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");

test("UI QML takes colours, sizes and times only from Theme", () => {
    const offenders = [];
    for (const f of uiFiles()) {
        strip(readFileSync(join(root, f), "utf8")).split("\n").forEach((line, i) => {
            if (/^\s*import\s/.test(line)) return;
            if (/#[0-9a-fA-F]{3,8}\b|rgba?\(|Qt\.rgba|Qt\.hsla/.test(line))
                offenders.push(`${f}:${i + 1}: colour literal: ${line.trim()}`);
            const code = line.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`/g, '""');
            for (const m of code.matchAll(/(?<![\w.$#])\d+(?:\.\d+)?(?![\w.])/g))
                if (!ALLOWED.has(m[0])) offenders.push(`${f}:${i + 1}: number ${m[0]}: ${line.trim()}`);
        });
    }
    assert.deepEqual(offenders, []);
});
