.pragma library

// Launcher calculator: a hand-written recursive-descent parser, no eval/Function.
// Grammar (lowest to highest precedence):
//   sum   = prod (("+" | "-") prod)*
//   prod  = unary (("*" | "/" | "%") unary)*
//   unary = "-" unary | power
//   power = atom ["^" unary]            (right-associative: 2^3^2 = 2^(3^2); -2^2 = -4)
//   atom  = number | const | func "(" sum ")" | "(" sum ")"
// Not supported (-> null): exponent literals (1e5), implicit multiplication (2pi),
// unary plus, function argument lists. Any non-finite intermediate (1/0, sqrt(-1)) -> null.

var MAX_DEPTH = 64;

// Looked up only via hasOwnProperty, so "constructor"/"toString"/"__proto__" are not names.
var FUNCS = {
    sqrt: Math.sqrt, sin: Math.sin, cos: Math.cos, tan: Math.tan, ln: Math.log,
    log: Math.log10, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil
};
var CONSTS = { pi: Math.PI, e: Math.E };

function has(obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key);
}

// "1,5" -> number token (comma is a decimal separator); identifiers are lowercased.
function tokenize(src) {
    var re = /\s*(?:(\d+(?:[.,]\d+)?|[.,]\d+)|([a-zA-Z_][a-zA-Z0-9_]*)|([-+*\/^%()]))/y;
    var out = [];
    var pos = 0;
    while (pos < src.length) {
        re.lastIndex = pos;
        var m = re.exec(src);
        if (m === null) {
            if (/^\s*$/.test(src.slice(pos)))
                break;
            return null;
        }
        pos = re.lastIndex;
        if (m[1] !== undefined) {
            var v = parseFloat(m[1].replace(",", "."));
            if (!isFinite(v))
                return null;
            out.push({ t: "num", v: v });
        } else if (m[2] !== undefined)
            out.push({ t: "id", v: m[2].toLowerCase() });
        else
            out.push({ t: "op", v: m[3] });
    }
    return out;
}

// Internal failures are thrown as FAIL and turned into null by evaluate().
var FAIL = { fail: true };

function parse(tokens) {
    var i = 0;
    var depth = 0;

    function fin(x) {
        if (!isFinite(x))
            throw FAIL;
        return x;
    }
    function peekOp(v) {
        return i < tokens.length && tokens[i].t === "op" && tokens[i].v === v;
    }
    function enter() {
        if (++depth > MAX_DEPTH)
            throw FAIL;
    }

    function sum() {
        var x = prod();
        while (peekOp("+") || peekOp("-")) {
            var op = tokens[i++].v;
            var y = prod();
            x = fin(op === "+" ? x + y : x - y);
        }
        return x;
    }
    function prod() {
        var x = unary();
        while (peekOp("*") || peekOp("/") || peekOp("%")) {
            var op = tokens[i++].v;
            var y = unary();
            x = fin(op === "*" ? x * y : op === "/" ? x / y : x % y);
        }
        return x;
    }
    function unary() {
        if (peekOp("-")) {
            i++;
            enter();
            var x = -unary();
            depth--;
            return x;
        }
        return power();
    }
    function power() {
        var x = atom();
        if (peekOp("^")) {
            i++;
            enter();
            x = fin(Math.pow(x, unary()));
            depth--;
        }
        return x;
    }
    function atom() {
        if (i >= tokens.length)
            throw FAIL;
        var tok = tokens[i++];
        if (tok.t === "num")
            return tok.v;
        if (tok.t === "op" && tok.v === "(") {
            enter();
            var x = sum();
            depth--;
            if (!peekOp(")"))
                throw FAIL;
            i++;
            return x;
        }
        if (tok.t === "id") {
            if (has(CONSTS, tok.v))
                return CONSTS[tok.v];
            if (has(FUNCS, tok.v) && peekOp("(")) {
                i++;
                enter();
                var arg = sum();
                depth--;
                if (!peekOp(")"))
                    throw FAIL;
                i++;
                return fin(FUNCS[tok.v](arg));
            }
        }
        throw FAIL;
    }

    var result = sum();
    if (i !== tokens.length)
        throw FAIL;
    return result;
}

// -> number | null. Never throws.
function evaluate(expr) {
    try {
        var tokens = tokenize(String(expr));
        if (tokens === null || tokens.length === 0)
            return null;
        return parse(tokens);
    } catch (err) {
        return null;
    }
}

// Max 10 significant digits, no trailing zeros, "," as the decimal separator.
// Very large/small values keep JS exponent form without the "+": 1e21 -> "1e21", 1.5e-7 -> "1,5e-7".
function format(n) {
    return String(Number(n.toPrecision(10))).replace("e+", "e").replace(".", ",");
}
