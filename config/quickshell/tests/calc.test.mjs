import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { load } from "./qmljs.mjs";

const C = load("lib/calc.js");

test("arithmetic and precedence", () => {
    assert.equal(C.evaluate("2+3*4"), 14);
    assert.equal(C.evaluate("(2+3)*4"), 20);
    assert.equal(C.evaluate("2^3^2"), 512);
    assert.equal(C.evaluate("-3+5"), 2);
    assert.equal(C.evaluate("7 % 4"), 3);
    assert.equal(C.evaluate("1,5*2"), 3);
});

test("unary minus binds looser than ^, tighter than * and works inside exponents", () => {
    assert.equal(C.evaluate("-2^2"), -4);
    assert.equal(C.evaluate("2^-1"), 0.5);
    assert.equal(C.evaluate("--3"), 3);
    assert.equal(C.evaluate("2*-3"), -6);
    assert.equal(C.evaluate("10-2-3"), 5);
    assert.equal(C.evaluate("8/2/2"), 2);
});

test("decimals with dot or comma, whitespace ignored", () => {
    assert.equal(C.evaluate("0.5+0,25"), 0.75);
    assert.equal(C.evaluate(".5"), 0.5);
    assert.equal(C.evaluate("  2 +  3 "), 5);
});

test("a comma inside parentheses is a decimal separator, not an argument separator", () => {
    assert.equal(C.evaluate("sqrt(2,25)"), 1.5);
});

test("functions and constants", () => {
    assert.equal(C.evaluate("sqrt(16)"), 4);
    assert.ok(Math.abs(C.evaluate("sin(pi/2)") - 1) < 1e-12);
    assert.ok(Math.abs(C.evaluate("ln(e)") - 1) < 1e-12);
    assert.equal(C.evaluate("log(1000)"), 3);
    assert.equal(C.evaluate("abs(-4)"), 4);
    assert.equal(C.evaluate("round(2.5)"), 3);
    assert.equal(C.evaluate("floor(-1.5)"), -2);
    assert.equal(C.evaluate("ceil(1.2)"), 2);
    assert.equal(C.evaluate("cos(0)"), 1);
    assert.equal(C.evaluate("tan(0)"), 0);
    assert.equal(C.evaluate("SQRT(4)+Pi"), 2 + Math.PI);
});

test("invalid input is null, never throws", () => {
    for (const s of ["", "2+", "foo(2)", "alert(1)", "2**", "(1", "1)", "constructor"]) assert.equal(C.evaluate(s), null, s);
});

test("Object.prototype names are not functions or constants", () => {
    for (const s of ["toString", "__proto__", "valueOf(1)", "hasOwnProperty(1)", "constructor(1)", "toString()", "__proto__(2)"])
        assert.equal(C.evaluate(s), null, s);
});

test("malformed syntax is null", () => {
    for (const s of ["pi(2)", "2 3", "1,,5", ".", ",", "1e5", "2e", "sqrt", "sqrt 4", "sqrt()", "()", "2pi", "1+*2", "+3", "1.2.3", "3 4 +", "2,", "a", "2$3", "1;2", "`1`"])
        assert.equal(C.evaluate(s), null, s);
});

test("non-finite results are null", () => {
    for (const s of ["1/0", "0/0", "7%0", "sqrt(-1)", "ln(0)", "ln(-1)", "log(0)", "9^999", "1/(1/0)"])
        assert.equal(C.evaluate(s), null, s);
});

test("numeric literals that overflow to Infinity are null, not Infinity", () => {
    const big = "1" + "0".repeat(400);
    for (const s of [big, "-" + big, "(" + big + ")", "2^-" + big, "1/" + big, big + "-" + big])
        assert.equal(C.evaluate(s), null, s.slice(0, 12));
});

test("deep nesting is bounded, never throws", () => {
    assert.equal(C.evaluate("(".repeat(10000) + "1" + ")".repeat(10000)), null);
    assert.equal(C.evaluate("-".repeat(10000) + "1"), null);
    assert.equal(C.evaluate("2^".repeat(10000) + "1"), null);
    assert.equal(C.evaluate("(".repeat(10000)), null);
    assert.equal(C.evaluate("(".repeat(20) + "1" + ")".repeat(20)), 1);
});

test("never reaches for eval", () => {
    const code = readFileSync(new URL("../lib/calc.js", import.meta.url), "utf8").replace(/\/\/.*$/gm, "");
    assert.ok(!/\beval\b|\bFunction\b/.test(code));
});

test("format()", () => {
    assert.equal(C.format(3), "3");
    assert.equal(C.format(0.1 + 0.2), "0,3");
    assert.equal(C.format(1 / 3), "0,3333333333");
});

test("format(): sign, zero, magnitudes", () => {
    assert.equal(C.format(-3.5), "-3,5");
    assert.equal(C.format(-0), "0");
    assert.equal(C.format(0), "0");
    assert.equal(C.format(-1 / 3), "-0,3333333333");
    assert.equal(C.format(2 / 3), "0,6666666667");
    assert.equal(C.format(1234567.891), "1234567,891");
    assert.equal(C.format(12345678901), "12345678900");
    assert.equal(C.format(1e15), "1000000000000000");
    assert.equal(C.format(1e21), "1e21");
    assert.equal(C.format(1.5e-7), "1,5e-7");
    assert.equal(C.format(1e-7), "1e-7");
    assert.equal(C.format(0.000001), "0,000001");
    assert.equal(C.format(Math.sin(Math.PI)), "1,224646799e-16");
});
