# Wyspa — measurement reference (extracted from DESIGN.md + prototypes)

Source files (read in full, state as of 2026-10-10 ~19:50; WyspaLive modified and JasnyMotyw added mid-extraction, both re-read):
- `config/quickshell/docs/DESIGN.md` (DESIGN) incl. §3a light theme and §3b glass levels
- `config/quickshell/docs/prototypes/WyspaLive.dc.html` (Live) — rest, osd(volume), media, toast(notif), control, launcher, line, ears, material, glass levels, sheen
- `config/quickshell/docs/prototypes/JasnyMotyw.dc.html` (Jasny) — light theme: control, launcher, lock, token table, switching note
- `config/quickshell/docs/prototypes/WyspaRuch.dc.html` (Ruch) — choreography, curves, size table
- `config/quickshell/docs/prototypes/Kotwica.dc.html` (Kotwica) — anchor variants (illustration only)
- `config/quickshell/docs/prototypes/NotifLive.dc.html` (Notif) — rest+badge, toast(+N), center
- `config/quickshell/docs/prototypes/PowerLive.dc.html` (Power) — power, powerDone, dim
- `config/quickshell/docs/prototypes/LockLive.dc.html` (Lock) — lock card, wallpaper, unlock

Conventions:
- All px values are CSS px on a 1440×900 canvas (Jasny: 1440×1240 page with mock screens 880×550, 760×400). Screen centre x = 720.
- "ui" = UI font (prototype Geist; DESIGN W5 default JetBrainsMono Nerd Font). "mono" = mono font (prototype Geist Mono; W5 default JetBrainsMono Nerd Font).
- Where a text node sets no font-size, the browser default 16 px applies (root sets none; `button{font:inherit}`): marked "16 (inherited default)".
- Default weight 400. `tabular` = `font-variant-numeric: tabular-nums`.
- Curve S = `cubic-bezier(0.32, 0.72, 0, 1)` (shape). Curve E = `cubic-bezier(0.2, 0, 0, 1)` (content enter). `ease` = CSS `ease` = `cubic-bezier(0.25, 0.1, 0.25, 1)`.
- Padding order is CSS (top right bottom left). `gap` = spacing between flex/grid children.
- Colour values in state sections are given as `token (dark value)`; light values are in §1 and in each state's "Light" note.
- `white@a` = `rgba(255,255,255,a)`; `ink@a` = `rgba(30,27,42,a)` (= `#1E1B2A` light fg with alpha).
- [C#n] = entry in §6 Contradictions / ambiguities.
- Demo-only items (fake desktop, fake windows, captions, demo state-switcher nav, sample data) are excluded except where noted.

---

## 1. Global tokens

### 1.1 Theme-independent colour tokens (dark | light)

"Light" values come from DESIGN §3a and Jasny. "unspecified" = no light value anywhere.

| Proposed token | Dark | Light | Where used (shell UI) | Source / notes |
|---|---|---|---|---|
| `colors.islandBg` | per glass level (§1.2); DESIGN §3 default `rgba(16,14,26,0.62)` | per glass level (§1.2); subtelne `rgba(230,226,236,0.8)` | island fill, ears | [C#1] default level |
| `colors.islandBgSolid` | DESIGN: same bg alpha ~0.78; Live `material: solid`: `#0B0B10` | unspecified | fallback, `glass: false` | [C#2] |
| `colors.islandRing` | `white@0.07`, inset 1px | `white@0.55`, inset 1px | island edge | DESIGN §3/§3a, Live, Jasny |
| `colors.islandShadow` | `0 18 60 rgba(10,6,20,0.5)` | `0 18 50 rgba(40,30,70,0.2)` | island drop shadow (offset-y, blur, colour) | DESIGN §3a, Jasny |
| `colors.line` | `rgba(236,234,242,0.75)` | unspecified | island fill in `line` state | Live |
| `colors.lockBg` | `rgba(16,14,26,0.6)` + `blur(30px) saturate(1.4)` | = light islandBg per level + level backdrop | lock card | Lock, Jasny [C#3] |
| `colors.lockRing` | `white@0.08`, inset 1px | `white@0.55`, inset 1px | lock card edge | Lock, Jasny [C#3] |
| `colors.lockShadow` | `0 24 80 rgba(10,6,20,0.45)` | `0 24 70 rgba(40,30,70,0.25)` | lock card shadow | Lock, Jasny [C#3] |
| `colors.lockGlass` | `rgba(16,14,26,0.55)` + `blur(24px)` | unspecified | lock mini player, lock corner buttons | Lock |
| `colors.lockGlassRing` | `white@0.08`, inset 1px | unspecified | same | Lock |
| `colors.tile` (DESIGN `surface`) | per level (§1.2); subtelne `#17161F` | per level; subtelne `#EFECF3` | control tiles, slider card, toggles off, mini player card, launcher search field; light lock password field | DESIGN, Live `{{tile}}`, Jasny `{{ltile}}` |
| `colors.card` | `#1F1E2A` | `#F3F1F6` (DESIGN §3a "card / zaznaczenie") | notification card | DESIGN, Notif; per-level card for center unspecified [C#16] |
| `colors.sel` | per level; subtelne `#1E1D28` | per level; subtelne `#F3F1F6` (Jasny `lcard`) | launcher selected row; toast icon box + progress track (Live) | Live `{{sel}}`, Jasny; DESIGN §3a merges card+sel [C#4] |
| `colors.chip` | per level; subtelne `#2C2A39` | per level; subtelne `#DDD9E5` | kbd chips (`esc`, `↵`), active launcher mode chip; dark also OSD + control slider tracks | DESIGN §3a, Live `{{chip}}`, Jasny `{{lchip}}` [C#5] |
| `colors.track` | `#2C2A39` (DESIGN); Live now uses `chip` per level | `#CFCADA` (fixed, all levels) | slider / OSD track | DESIGN §3a, Jasny [C#5] |
| `colors.sliderFill` | `fg` `#ECEAF2` (control); OSD fill = accent | `fg` `#1E1B2A` (control) | control slider fill | DESIGN §3a, Live, Jasny |
| `colors.hover` | `#26243A` | unspecified | power circle hover (intended, dead in prototype [C#21]) | DESIGN §3, Power |
| `colors.powerBtn` | `#1C1B26` | unspecified | power circle at rest | Power [C#6] |
| `colors.powerBtnHeld` | `#2C2A39` | unspecified | power circle while holding | Power |
| `colors.stack1` | `#191823` | unspecified | 1st stack layer under collapsed group | Notif [C#6] |
| `colors.stack2` | `#15141D` | unspecified | 2nd stack layer | Notif [C#6] |
| `colors.divider` | `#1F1E29` | `#D6D2DF` | launcher footer top border 1px | Live, Jasny [C#6: dark is one hex off `#1F1E2A`] |
| `colors.dotInactive` | `#57536A` | unspecified | inactive workspace dots | DESIGN §6, all rests |
| `colors.scrollThumb` | `#2C2A39` (hard-coded, not `chip`) | unspecified | center list scrollbar thumb (track transparent) | Notif |
| `colors.fg` | `#ECEAF2` | `#1E1B2A` | primary text, toggle-off icons | DESIGN |
| `colors.fgMuted` | `#A29DB3` | `#5C5770` | secondary text, hints, slider icons/values, inactive chips, `Wyczyść`; light lock date + bottom row | DESIGN |
| `colors.fgDim` | `#8B8699` | unspecified | group count, card time, card dismiss X, power key hint | DESIGN §3 |
| `colors.fgSoft` | `#D9D5E3` | unspecified | power button labels | Power [C#6] |
| `colors.fgLock` | `#CFC8E0` | (Jasny uses `fgMuted` `#5C5770`) | dark lock date + bottom row | Lock [C#6] |
| `colors.accent` | `#B9A7F5`; options `#F1D6AE`, `#8FD3C1`, `#F2A7B8` | `#5E48B8`; Jasny options `#8A5A1E`, `#2F7A68`, `#A23D5C` | active dot, eq, OSD fill, toast bar, accent circles, launcher caret/match/prefix, `+N`, center toggle label, DND on, power ring, powerDone dot, lock avatar | DESIGN §3/§3a, Jasny props [C#7] |
| `colors.onAccent` | DESIGN `#121118` (prototypes also `#0B0B10`) | `#FFFFFF` | glyphs on accent (circles, avatar, `+N`, DND on, app-colour letter boxes) | DESIGN §3a, Jasny [C#8] |
| `colors.inverseBg` / `colors.inverseFg` | `#ECEAF2` / `#0B0B10` (play/pause); lock submit `#ECEAF2` / `#121118` | `#1E1B2A` / `#EFECF3` | play/pause, lock submit (→) | Live, Lock, Jasny [C#8] |
| `colors.danger` | `#F2A7B8` | `#B4405E` | Wyłącz icon + ring, lock error ring + text | DESIGN §3a |
| `colors.accentSoft` | accent@0.18 (hard-coded `rgba(185,167,245,0.18)`) | unspecified | rest notification badge bg | Notif [C#9] |
| `colors.accentHalo` | accent@0.2 (hard-coded) | unspecified | powerDone dot halo (spread 4) | Power [C#9] |
| `colors.focusRing` | accent@0.9 (hard-coded `rgba(185,167,245,0.9)`), 1.5px | unspecified | `:focus-visible` (Notif offset 2; Power offset 4, radius 18) | [C#9] |
| `colors.focusRingLock` | accent@0.8 (hard-coded), 1.5px, offset 3 | unspecified | lock field `:focus-within` | Lock [C#9] |
| `colors.dndOffBg` | `white@0.06` | unspecified | DND switch off | Notif |
| `colors.lockField` | `white@0.07` | `tile` (per level) | lock password field bg | Lock, Jasny |
| `colors.lockFieldRing` | `white@0.12`, inset 1px | `ink@0.08`, inset 1px | lock field ring (normal) | Lock, Jasny |
| `colors.lockFieldError` | inset 1.5px `danger` | presumably `danger` light; not drawn | lock field ring (error) | Lock |
| `colors.scrimDim` | `rgba(8,6,14,0.45)` | unspecified | full-screen dim under power menu | DESIGN, Power |
| `colors.sheen*` | see §2a | see §2a | gloss overlay | DESIGN §3b, Live, Jasny |
| Lock wallpaper filter | blur 22, saturate 1.2, brightness 0.78, scale 1.08 | blur 18, brightness 0.92 (saturate and scale unspecified) | lock background | DESIGN §3a/§6, Lock, Jasny [C#10] |

Demo-only colours (do NOT tokenise):
- Dark wallpaper drawing: `#2A2440` base, `#F1D6AE` sun (r 38 at 1060/250), hills `#3B2F55`, `#4C3660`, `#5E3E64`, `#6B4566`. Light mock wallpaper: `#CFC6DE`, `#F6E7CF` sun, `#B9ADD2`, `#A595C4`, `#9584B6`, lock mock `#A99CC3`/`#C3B9D8`/`#8C7AB0`.
- Fake windows: dark `rgba(18,16,28,0.88)` + ring `white@0.06` r14 (bars now `{{chip}}`); light `rgba(246,244,249,0.9)` + ring `ink@0.06` r12.
- Art placeholders: dark `#4C3660`, light `#B9ADD2` (real cover art).
- Launcher icon placeholders: dark `#8A5A2B/#FFE9CF`, `#2E4B7A/#DCE8FF`, `#6B5A3E/#F7EBD6`; light `#C98B4F/#2A1A0A`, `#7FA0D6/#0E1A2E`, `#C9B48E/#2A220F` (real app icons).
- Sample notification app colours: niri `#B9A7F5`, Wiadomości `#8FD3C1`, pacman `#F1D6AE`, Kalendarz `#F2A7B8` [C#33].
- Captions `#E4DEF0`, demo nav `rgba(11,11,16,0.7)` + blur 16 + ring `white@0.08`; documentation pages `#121118`, `#1A1922`, `#0F0E14`, link colours `#C9BBF7`/`#E2D9FF` (dark), `#5E48B8`/`#45348F` (Jasny page).

### 1.2 Glass levels (`Theme.glassLevel`: `subtelne` | `mocne` | `ciekłe`; default `ciekłe` "do potwierdzenia")

Values from Live `GL` (dark) and Jasny (light); DESIGN §3b where stated.

| Level | Theme | `islandBg` | Backdrop | `tile` | `sel` (Jasny `lcard`) | `chip` | sheen opacity |
|---|---|---|---|---|---|---|---|
| solid (`material: solid`) | dark | `#0B0B10` (DESIGN: bg@0.78) | none | `#17161F` | `#1E1D28` | `#2C2A39` | 0 |
| subtelne | dark | `rgba(16,14,26,0.62)` | blur 24, saturate 1.5 | `#17161F` | `#1E1D28` | `#2C2A39` | 0 |
| subtelne | light | `rgba(230,226,236,0.8)` | blur 24, saturate 1.3 | `#EFECF3` | `#F3F1F6` | `#DDD9E5` | 0 |
| mocne | dark | `rgba(16,14,26,0.40)` | blur 36, saturate 1.8 | `white@0.06` | `white@0.10` | `white@0.12` | 0.5 |
| mocne | light | `rgba(232,228,238,0.58)` | blur 36, saturate **1.6** | `white@0.42` | `white@0.52` | `ink@0.08` | 0.5 |
| ciekłe | dark | `rgba(22,18,36,0.28)` | blur 44, saturate 2, brightness 1.05 | `white@0.07` | `white@0.12` | `white@0.14` | 1 |
| ciekłe | light | `rgba(234,230,240,0.44)` | blur 44, saturate **1.8**, brightness **1.04** | `white@0.40` | `white@0.50` | `ink@0.08` | 1 |

Notes:
- DESIGN §3b gives one Blur column for both themes (mocne sat 1.8; ciekłe sat 2.0, brightness 1.05); Jasny's light values differ (bold) [C#11].
- DESIGN §3b gives `tile` per level; `sel` and `chip` per level exist only in prototypes.
- Light ciekłe `sel` 0.50 < mocne 0.52 while `tile` also drops 0.42 → 0.40 — non-monotonic, possibly intended (less opaque = more glass) [C#12].
- Live solid fallback reuses the subtelne dark hexes for tile/sel/chip.
- W1: blur strength is global in niri (`blur { passes offset }`); per-level blur radius / saturate / brightness may not be expressible per surface [C#13].
- Sheen opacity transitions `300ms ease` when the level changes (Live).
- Not level-dependent in any prototype (hard-coded subtelne-style values): `card` `#1F1E2A`, `powerBtn` `#1C1B26`, `stack1/2`, `dndOffBg`, `lockField`, `scrollThumb` [C#16].
- DESIGN §3b legibility rule: on bright wallpaper consider a light text-shadow or auto-raising bg alpha when wallpaper brightness under the island > 0.7 — no numbers for the raise or shadow (unspecified).

### 1.3 Material (other)

| Token | Value | Source |
|---|---|---|
| `material.glass` | bool, default `true` (Live prop `material: glass/solid`; DESIGN `glass: false` fallback) | DESIGN W1, Live |
| Ears backdrop | Live: same as island (level backdrop); Notif/Power/Lock: `blur(24px)` only; Jasny: no backdrop filter, fill only | [C#14] |

### 1.4 Typography

| Token | Value | Source |
|---|---|---|
| `fonts.ui` | prototype Geist 400/500/600; W5 default `JetBrainsMono Nerd Font` | DESIGN §3, W5 [C#15] |
| `fonts.mono` | prototype Geist Mono 400/500; W5 default `JetBrainsMono Nerd Font` | DESIGN §3, W5 [C#15] |

Sizes in use (px): 10, 11, 12, 13, 14, 15, 16, 44, 88. Letter-spacing: `-0.03em` (control clock 44), `-0.045em` (lock clock 88), `0.08em` (center group header, uppercase), `0.12em` (lock password input; placeholder 0). Typography is identical in light theme.

### 1.5 Sizes (island states)

| Token | W×H | bottom radius | Source |
|---|---|---|---|
| `sizes.line` | 56×5 | 3 | DESIGN, Live |
| `sizes.rest` | 200×36 | 18 | all |
| `sizes.restBadge` | 252×36 | 18 | DESIGN, Notif |
| `sizes.osd` | 300×44 | 22 | DESIGN, Live |
| `sizes.media` | 380×56 | 28 | DESIGN, Live |
| `sizes.toast` | 420×76 | 30 | DESIGN, Live, Notif |
| `sizes.control` | 520×440 | 30 | DESIGN, Live, Jasny |
| `sizes.launcher` | 680×356 | 30 | DESIGN, Live, Jasny |
| `sizes.power` | 540×180 | 30 | DESIGN, Power |
| `sizes.powerDone` | 340×56 | 28 | DESIGN, Power |
| `sizes.center` | 440 × dynamic (empty 170, max 620) | 30 | DESIGN, Notif |
| `sizes.lock` | 460×360, top 210, all corners 36 | 36 | DESIGN, Lock, Jasny [C#24] |
| `sizes.ear` | 16 | — | DESIGN, all |
| `sizes.exclusiveZone` | 36 (0 in `line`) | — | DESIGN §4 |
| `sizes.lineHoverZone` | 400×28, top centre | — | DESIGN, Live |
| `sizes.niriGap` | 8 (windows start at y = 44) | — | DESIGN §4, Kotwica |

Radius rule (DESIGN, Ruch): `min(height/2, 30)`; matches all states except `line` (3, not 2.5) and `lock` (36). Shapes and sizes are identical in light theme (DESIGN §3a, Jasny).

### 1.6 Radii (components)

| Token | Value | Used by |
|---|---|---|
| `radii.tile` | 20 | control tiles, slider card, mini player card, launcher result row |
| `radii.card` | 16 | notification card, stack layers |
| `radii.field` | 24 (h 48) | launcher search pill |
| `radii.lockField` | 26 (h 52) | lock password pill |
| `radii.chip` | 14 (h 28) | launcher mode chips |
| `radii.kbd` | 8 | `esc`, `↵` |
| `radii.iconLg` | 14 (44 box) | toast icon box |
| `radii.iconMd` | 12 (40 box) | launcher result icon, control mini-player art |
| `radii.iconSm` | 11 (36 box) | notification card icon |
| `radii.art` | 10 (36 box) | media art, lock mini-player art |
| round | size/2 | all circular buttons |

### 1.7 Motion

| Token | Value | Source |
|---|---|---|
| `motion.morphMs` | 460 | DESIGN, all |
| `motion.morphCurve` | `[0.32,0.72, 0,1, 1,1]` (Curve S) | DESIGN, all |
| `motion.springCurve` | `cubic-bezier(0.34, 1.3, 0.5, 1)` (option "sprężysty") | Live, Ruch only [C#17] |
| `motion.slowFactor` | ×3 debug ("zwolniony ×3"), multiplies durations and timers | Live only |
| `motion.lockMorphMs` | 640 (Curve S) | DESIGN, Lock |
| `motion.wallpaperMs` | 700 (Curve S) | DESIGN, Lock |
| `motion.themeFadeMs` | 600 colour crossfade (`ColorAnimation`), no shape morph; easing unspecified | DESIGN §3a, Jasny |
| `motion.sheenFadeMs` | 300 `ease` (sheen opacity on level change) | Live |
| `motion.exitOpacityMs` | 120 `ease` | DESIGN, all |
| `motion.exitScaleMs` | 160 `ease` | DESIGN, all |
| `motion.exitBlurMs` | 120 `ease` (DESIGN: no duration) | prototypes |
| `motion.enterOpacityMs` / delay | 220 Curve E / 160 | DESIGN, all |
| `motion.enterScaleMs` / delay | 320 Curve E / 120 | DESIGN, all |
| `motion.enterBlurMs` / delay | 220 `ease` / 160 [C#17] | prototypes |
| `motion.contentScaleFrom` | 0.94 | DESIGN, all |
| `motion.contentBlur` | 6 px | DESIGN, all |
| `motion.reducedFadeMs` | 120 crossfade, no scale/blur | DESIGN §5, Ruch [C#28] |
| `motion.earOpacityMs` | 160 `ease` (Live); 200 `ease` (Lock) | [C#14] |
| `motion.bgColorMs` | 200 `ease` (island background, e.g. → line colour) | Live |
| `motion.osdBarMs` | 260 Curve E | DESIGN, Live |
| `motion.osdTimeoutMs` | 1600 | DESIGN, Live |
| `motion.toastTimeoutMs` | 3600 | DESIGN, Live, Notif |
| `motion.toastBarMs` / delay | 3400 linear / 60 | Live |
| `motion.lineLeaveDelayMs` | 250 | Live |
| `motion.holdMs` | 900 (prop range 300–2500, step 100) | DESIGN, Power |
| `motion.holdCancelMs` | 220 `ease` | DESIGN, Power |
| `motion.powerDoneMs` | 1800 (auto → rest) | Power only [C#25] |
| `motion.dimMs` | 400 `ease` | Power |
| `motion.stackPadMs` | 300 `ease` | Notif |
| `motion.buttonBgMs` | 200 `ease` (power circle bg, DND chip bg, lock field ring) | Power, Notif, Lock |
| `motion.eqMs` | 900 `ease-in-out` infinite | Live |
| `motion.shakeMs` | 380, `cubic-bezier(0.36, 0.07, 0.19, 0.97)` | DESIGN, Lock |
| `motion.burstSpacingMs` | 600 (demo "Seria ×3" at 0/600/1200) | Notif (demo) |

---

## 2. Island container

### 2.1 Placement
- Anchor: top centre of the active monitor, `top = 0` (attached, "wtopiona"); centred (`left 50%; translateX(-50%)`).
- Floating variant ("pływająca", Live prop): `top = 12`, all four corners `r` — rejected (Kotwica variant 1).
- Lock: `top = 210`, all corners 36 [C#24].

### 2.2 Shape
- Rectangle `w × h`, top corners 0, bottom corners `r` (§1.5). `overflow: hidden` / `clip: true`.
- Each state's content layer has its **target width from the start**, centred, anchored at `top: 0`, height = state height. Never reflows during morph.

### 2.3 Ears (inverted corners)
HTML: two 16×16 elements at `top: 0`:
- Left ear: `left = 720 − w/2 − 16` (just left of island edge `L`). Fill = island bg (+ backdrop, see [C#14]). Mask `radial-gradient(circle at 0 100%, transparent 15.5px, #000 16px)` → radius-16 circle centred at `(L−16, 16)` cut out; opaque region hugs `(L, 0)`. The 15.5→16 px ramp is anti-aliasing.
- Right ear: `left = 720 + w/2` (= `R`), mask `circle at 100% 100%` → circle centred `(R+16, 16)`.
- Ear `left` follows the shape: `left 460ms Curve S` (all); Live adds `opacity 160ms ease`.
- Visible when attached and state ≠ `line`; opacity 0 in `line`, floating and lock.

Single QML path equivalent (`L = cx − w/2`, `R = cx + w/2`, `e = 16`, bottom radius `r`; SVG arc syntax, y down):
```
M (L−e, 0)
A e e 0 0 1 (L, e)         // concave fillet, centre (L−e, e)
L (L, h − r)
A r r 0 0 0 (L + r, h)     // convex bottom-left
L (R − r, h)
A r r 0 0 0 (R, h − r)     // convex bottom-right
L (R, e)
A e e 0 0 1 (R + e, 0)     // concave fillet, centre (R+e, e)
Z
```
Valid while `h − r ≥ e` (rest 18, osd 22, media 28, toast 46, larger OK). `line` (h 5) drops the ears. Check sweep flags against Qt `PathArc.direction`. [C#18 ring on ears]

### 2.4 Ring and shadow
- Ring: inset 1px `islandRing` (dark `white@0.07`, light `white@0.55`) on the rectangle only (incl. top edge); ears have neither ring nor shadow in HTML [C#18].
- Shadow: dark `0 18 60 rgba(10,6,20,0.5)`, light `0 18 50 rgba(40,30,70,0.2)`. DESIGN W2: QML `MultiEffect` under the shape.
- Live keeps shadow + ring (and sheen) in `line` state [C#19].

### 2.5 Material
- Glass: `islandBg` + backdrop per glass level (§1.2). DESIGN W1: `BackgroundEffect.blurRegion` = island shape incl. ears; blur strength niri-global [C#13].
- Solid: DESIGN bg alpha 0.78, no blur; Live `#0B0B10` [C#2].

### 2.6 Line state
- 56×5, bottom radius 3 (`0 0 3 3`), `top 0`, fill `rgba(236,234,242,0.75)` regardless of material, backdrop unchanged, ears opacity 0, shadow/ring/sheen unchanged in Live [C#19].
- No content: every layer in its "off" appearance.
- Background colour transition `200ms ease`; size via 460 ms morph.
- Hover zone (only while hiding): invisible rect at `top 0`, 400×28, centred (`left 520` on 1440). Height 28 when hiding, else 0.
- Hover logic (Live): `mouseenter` on zone **or** island → cancel leave timer, `hover = true` → effective `rest`. `mouseleave` from either → 250 ms timer → `hover = false` → back to `line`. Effective `line` iff hiding && mode `rest` && !hover. Non-rest modes show normally while hiding.
- Window top: hiding 8; attached 44; floating 56.
- Exclusive zone 0 in `line`, 36 otherwise.

### 2.7 Shape transition
`width/height/border-radius/top 460ms Curve S, background 200ms ease` (Live). Notif/Power omit `top`/`background`. Lock: `top/width/height/border-radius 640ms Curve S`. Interrupts start from the current value.

### 2.8 Content transition (per state layer)

| | opacity | scale | blur | pointer events |
|---|---|---|---|---|
| on (enter) | 0→1, 220 ms Curve E, delay 160 | 0.94→1, 320 ms Curve E, delay 120 | 6→0 px, 220 ms `ease`, delay 160 | on |
| off (exit) | →0, 120 ms `ease` | →0.94, 160 ms `ease` | →6 px, 120 ms `ease` | none |

Transform origin = layer centre. Ruch timeline: shape 0–460; old out 0–120; new scale 120–440; new opacity+blur 160–380.
Reduced motion: crossfade 120 ms only (DESIGN §5, Ruch rule 5); shape behaviour unspecified [C#28]. Lock has its own timings (§3.10).

### 2.9 Scrim / click-outside
- Invisible full-screen click catcher under the island (`opacity 0`), click → `rest`.
- Active: Live — every mode ≠ `rest` (incl. osd/toast/media); Notif — only `center`; Power — only `power`; DESIGN W3 — modal states [C#23].
- Visible dim only for power: `rgba(8,6,14,0.45)`, opacity 0↔1, 400 ms `ease`.

### 2.10 State priority
DESIGN: launcher › panel/power/center › toast › osd › media. Ruch: launcher › panel › powiadomienie › OSD › media [C#20]. No prototype implements priority (each `go()` replaces the mode).

---

## 2a. Gloss overlay ("połysk", sheen)

A non-interactive layer filling the island shape, painted **above** all content layers (last child of the island; `pointer-events: none`), clipped by the island (Live: by `overflow: hidden`; Jasny: `border-radius: inherit`). Its opacity is the level's sheen value (§1.2: 0 / 0.5 / 1), transition `opacity 300ms ease` (Live). Solid material → 0.

| Component | Dark (Live) | Light (Jasny) | DESIGN §3b |
|---|---|---|---|
| Vertical gradient (top→bottom, 180°) | `white@0.12` 0% → `white@0.02` 45% → `white@0` 100% | `white@0.38` 0% → `white@0.06` 45% → `white@0` 100% | white 12%→0 (light 38%→0); no 45% stop given |
| Bottom edge highlight | inset `0 -1px 0` `white@0.22` | inset `0 -1px 0` `white@0.75` | 22% (light 75%) |
| Outline | inset `0 0 0 1px` `white@0.10` | inset `0 0 0 1px` `white@0.35` | 10% (light 35%) |
| Inner glow | inset `0 0 30px` `white@0.06` | **absent** | 30 px white 6% (no light value) [C#26] |

Notes:
- The overlay's 1px outline stacks on top of the island ring (dark: 0.07 + 0.10).
- Because it sits above content, the gradient also lightens text/tiles near the top edge (as prototyped).
- Ears receive no sheen in any prototype; sheen applies to the island rectangle only [C#18].
- Jasny applies the overlay to the lock card too; dark Lock has no overlay [C#3].
- Live keeps it in `line` state (opacity unchanged) [C#19].
- QML mapping: a `Shape`/`Rectangle` child above content with a `Gradient` (3 stops at 0, 0.45, 1) plus inner strokes; the inset edge/outline/glow have no direct QML primitive — options: 1px inner path strokes for edge + outline, `MultiEffect` inner shadow or a blurred inner stroke for the 30 px glow (implementation choice, unspecified by design).

---

## 2b. Theme switching

- Two token sets (dark, light) in `Theme.qml` plus a `mode` property (DESIGN §3a).
- Modes: manual / by time of day (sunrise–sunset) / by wallpaper brightness (DESIGN §3a, Jasny). Thresholds, location source for sunrise/sunset, and wallpaper-brightness thresholds/hysteresis: unspecified.
- Change = colour crossfade 600 ms (`ColorAnimation`), **no shape morph** (sizes, radii, motion unchanged). Easing unspecified.
- Quick toggle (Jasny only): hold "Ciepłe światło" in the panel, or a shortcut. W8 removes the Ciepłe światło toggle from scope [C#27]. Hold duration for this toggle: unspecified.
- Light theme is DESIGN-marked "(w planie)".
- What changes: only colour tokens (DESIGN §3a; Jasny caption "zmieniają się wyłącznie tokeny kolorów"). Exception: lock wallpaper filter (blur 22 → 18, brightness 0.78 → 0.92).
- Interaction with glass level: light has its own per-level bg/backdrop/tile/sel/chip (§1.2) and its own sheen strengths (§2a).

---

## 3. States

### 3.1 `rest` — 200×36 (252×36 with badge), r 18

Trigger: always / fallback. Click → `control` (Live, DESIGN); Notif opens `center` from the whole rest [C#22].
```
row 200(or 252)×36, centred, gap 14, align centre
├─ workspace dots: row gap 4, align centre
│   ├─ inactive: 5×5, radius 3, dotInactive (#57536A)
│   └─ active:   14×5, radius 3, accent
│   (Live demo: inactive, ACTIVE, inactive, inactive; others: inactive, ACTIVE, inactive)
├─ clock "18:49": mono 13 / 500, tabular, fg
├─ [MPRIS playing] eq: row gap 2, align bottom, height 12
│   └─ 3 × bar 2×12, accent, origin bottom; scaleY 0.35→1→0.35, 900 ms ease-in-out infinite, delays 0 / −300 / −600
└─ [count > 0] badge: row gap 5, h 22, padding 0 8, radius 11, bg accentSoft, colour accent, mono 11
    ├─ icon 12, stroke 2: bell (not DND) or moon (DND)
    └─ count (total notifications)
```
- Rest layer width animates `width 460ms Curve S` with the island when the badge appears (Notif).
- Width with eq **and** badge: unspecified [C#30].
- Icons: bell `M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9` (Lucide `bell` without clapper); moon `M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z` (Lucide `moon`-like).
- Light: not prototyped; use token mapping (dotInactive light unspecified).

### 3.2 `osd` — 300×44, r 22

Trigger: volume/brightness change; → rest 1600 ms after the **last** change (timer restarts).
```
row 300×44, padding 0 16, gap 12, align centre
├─ icon 18, stroke 1.6, fg
│   volume: M11 5 6 9H2v6h4l5 4V5z + M15.5 8.5a5 5 0 0 1 0 7  (Lucide `volume-1`)
│   brightness: not drawn in OSD (control uses Lucide `sun`, §3.7)
├─ bar: flex 1, h 6, radius 3, bg chip (Live `{{chip}}`; was #2C2A39), clip
│   └─ fill h 6, radius 3, accent, width = value%, transition width 260 ms Curve E
└─ value: mono 12, width 28, right, tabular, fg
```
- Mute appearance, values >100: unspecified (demo wraps 100 → 10).
- W10: no backlight → brightness OSD hidden.

### 3.3 `media` — 380×56, r 28

Trigger: hover / ⊞M (DESIGN); no hover logic prototyped [C#34].
```
row 380×56, padding 0 10, gap 12, align centre
├─ art 36×36, radius 10, no shrink
├─ text column flex 1, min-width 0, gap 1
│   ├─ title: ui 13 / 500, fg ("[Tytuł utworu]")
│   └─ artist: ui 12, fgMuted ("[Wykonawca]")
├─ eq: row gap 2, align bottom, h 14, margin-right 4
│   └─ 4 × bar 2×14 accent, origin bottom, 900 ms ease-in-out infinite, delays 0 / −200 / −500 / −700
├─ prev 32×32, icon 15 stroke 1.6: m19 4-10 8 10 8V4z + M5 5v14 (Lucide `skip-back`), aria "Poprzedni"
├─ play/pause 36×36, radius 18, bg inverseBg (#ECEAF2), icon inverseFg (#0B0B10) 14, stroke 2.2, round cap: M9 5v14M15 5v14 (pause as 2 lines), aria "Pauza"
└─ next 32×32, icon 15 stroke 1.6: m5 4 10 8-10 8V4z + M19 5v14 (Lucide `skip-forward`), aria "Następny"
```
Play icon (paused), media timeout: unspecified.

### 3.4 `toast` — 420×76, r 30

Two prototype variants [C#29]. Shared: row, align centre, gap 14; click → `center` (aria "Otwórz centrum powiadomień"); → `rest` 3600 ms after the latest push (only if still `toast`).

**Variant A — Live**
```
row, padding 0 18 0 16, gap 14
├─ icon box 44×44, radius 14, bg sel (Live `{{sel}}`; was #1E1D28)
│   └─ icon 20, stroke accent 1.6: M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2 + circle (12,12) r3 (Lucide `focus`)
├─ text column flex 1, min-width 0, gap 2
│   ├─ title "Zrzut ekranu": ui 14 / 500, fg
│   └─ "Obraz jest w schowku · niri": ui 12, fgMuted   (body · app)
├─ time "teraz": mono 11, fgMuted
└─ progress (absolute): left 30, right 30, bottom 0, h 2, bg sel, no radius
    └─ fill h 2 accent: on show 100% (no transition); +60 ms → 0% over 3400 ms linear
```
**Variant B — Notif**
```
row, padding 0 16, gap 14
├─ icon box 44×44, radius 14, bg app colour, letter onAccent (#121118), ui 16 (inherited default) / 600
├─ text column flex 1, min-width 0, gap 2
│   ├─ title: ui 14 / 500, single line, ellipsis
│   └─ "{app} · {body}": ui 12, fgMuted, single line, ellipsis
└─ [count > 1] "+{count−1}": h 24, padding 0 9, radius 12, bg accent, colour onAccent (#121118), mono 11 / 500
```
- Shows newest (`list[0]`); empty fallback bg `#2C2A39`.
- DND or mode `center`: no toast; list and counter still grow.

### 3.5 `center` — 440 × dynamic (max 620; empty 170), r 30

Trigger: click toast, click badge/rest (Notif), ⊞N. Close: scrim click, Esc (DESIGN). Opening clears the toast timer.
```
column 440×centerH, padding 14, gap 10
├─ header: row h 36, padding 0 4, gap 10, align centre
│   ├─ "Powiadomienia": ui 15 / 600, fg
│   ├─ count: mono 12, fgMuted
│   ├─ spacer
│   ├─ DND switch (role switch): row h 30, padding 0 10, radius 15, gap 8, ui 12
│   │   off: bg dndOffBg (white@0.06), fg; on: bg accent, colour onAccent (#121118); bg transition 200 ms ease
│   │   icon moon 13, stroke 1.8; label "Nie przeszkadzać"
│   └─ "Wyczyść": h 30, padding 0 10, radius 15, ui 12, fgMuted, no bg → clear all + reset expanded
├─ [empty] flex 1, column centred, gap 6, fgMuted, ui 13
│   ├─ icon 22, stroke 1.5: M20 6 9 17l-5-5 (Lucide `check`)
│   └─ "Wszystko przeczytane"
└─ list: flex 1, min-height 0, overflow-y auto, column gap 12; scrollbar thin, thumb #2C2A39, track transparent
    └─ group: column gap 6
        ├─ header: row h 22, padding 0 4, gap 8, align centre
        │   ├─ app: ui 11 / 600, letter-spacing 0.08em, UPPERCASE, fgMuted
        │   ├─ n: mono 11, fgDim
        │   ├─ spacer
        │   ├─ [n > 1] toggle: ui 11, accent, h 22, padding 0 6, "Pokaż {n}" / "Zwiń" (aria-expanded)
        │   └─ clear: 22×22, radius 11, fgMuted, X 12 stroke 2: M6 6l12 12M18 6 6 18 (Lucide `x`), aria "Wyczyść grupę {app}"
        └─ stack: relative, column gap 6, padding-bottom stackPad, transition padding 300 ms ease
            ├─ [collapsed && n > 2] layer 2: absolute left 16, right 16, top 14, h 64, radius 16, stack2 (#15141D)
            ├─ [collapsed && n > 1] layer 1: absolute left 8, right 8, top 7, h 64, radius 16, stack1 (#191823)
            └─ card(s), above layers: h 64, padding 0 8 0 12, radius 16, bg card (#1F1E2A), row gap 12
                ├─ icon 36×36, radius 11, bg app colour, letter ui 14 / 600, onAccent (#121118)
                ├─ text column flex 1, min-width 0, gap 2: title ui 13 / 500 ellipsis; body ui 12 fgMuted ellipsis
                ├─ time "18:49": mono 11, fgDim
                └─ dismiss 28×28, radius 14, fgDim, X 12 stroke 2, aria "Odrzuć"
```
- `stackPad` = 14 (collapsed, n > 2), 7 (collapsed, n == 2), else 0.
- Collapsed shows newest card only; expanded shows all newest-first. No per-card animation; only padding (300 ms) and island height (460 ms).
- Height: `count == 0` → 170; else `min(620, 14 + 36 + 10 + listH + 16)`, `listH = Σ(28 + shown·64 + (shown−1)·6 + stackPad) + 12·(groups−1)` (28 = 22 header + 6 gap) [C#31]. Above 620: scroll.
- Card hover, light theme, per-level card/stack colours: unspecified [C#16].

### 3.6 `launcher` — 680×356, r 30

Trigger: ⊞Spacja; close Esc. W8 scope: apps, `=` calc (JS), `>` command, `@` windows, VPN and clipboard menus; `/` files out of scope [C#32].
```
column 680×356, padding 10
├─ field (label): row h 48, padding 0 16, radius 24, bg tile, gap 10, align centre
│   ├─ icon 18, stroke fgMuted 1.6: circle (11,11) r7 + m20 20-3.5-3.5 (Lucide `search`)
│   ├─ query: ui 16, flex 1; caret 1.5×18 accent, margin-left 2
│   └─ kbd "esc": mono 11, fgMuted, bg chip, padding 3 8, radius 8
├─ mode chips: row gap 6, padding 10 4 8, ui 12
│   ├─ active "Wszystko": h 28, padding 0 12, radius 14, bg chip, fg
│   └─ inactive: h 28, padding 0 12, radius 14, no bg, fgMuted; prefix mono accent
│       "= kalkulator", "> polecenie", "/ pliki", "@ okna"  (Live: space char; Jasny: flex gap 4)
├─ result rows (3 in prototype): row gap 14, padding 10 14, radius 20
│   ├─ icon 40×40, radius 12 (placeholder letter ui 16 / 600)
│   ├─ text column flex 1, gap 2: name ui 15 / 500 fg, matched part accent ("F"actorio); description ui 12 fgMuted
│   │   ("Steam · ostatnio wczoraj", "Menedżer plików", "Archiwa")
│   └─ right: selected row bg sel + kbd "↵" mono 11, fg, bg chip, padding 4 8, radius 8; others "^2", "^3" mono 11 fgMuted
└─ footer: margin-top auto, row gap 16, padding 10 12 2, border-top 1px divider, ui 11, fgMuted
    "↑↓ wybierz" · "↵ otwórz" · "tab kategoria" · (margin-left auto) "prefiks zmienia tryb"  (key glyphs in fg)
```
- Light (Jasny): field `ltile`; icon/esc/inactive chips/descriptions/hints `#5C5770`; chips + kbd `lchip`; selected row `lcard`; divider `#D6D2DF`; footer keys `#1E1B2A`; Jasny omits "prefiks zmienia tryb" (mock simplification, unspecified).
- Derived: 10 + 48 + 46 + 3×60 = 284 px before the footer, footer ≈ 27 → ≈35 px slack. More results / `^1–9` → scroll vs cap unspecified [C#32].
- `esc` padding 3 8 vs `↵` 4 8 (minor).

### 3.7 `control` — 520×440, r 30

Trigger: ⊞A, click rest. Close: Esc, click outside.
```
column 520×440, padding 16, gap 10
├─ header: row align bottom, space-between, padding 2 6 4
│   ├─ clock "18:49": ui 44 / 600, letter-spacing −0.03em, line-height 1, tabular, fg
│   └─ date column, right-aligned, gap 2, ui 13: "sobota" fg; "10 października" fgMuted
├─ tiles: grid 2 equal cols, gap 10
│   └─ tile: row gap 10, padding 12, radius 20, bg tile
│       ├─ circle 38×38, radius 19, bg accent, icon onAccent (dark proto #0B0B10, light #FFFFFF) 17, stroke 1.8
│       │   Wi‑Fi: M2 8.8a15 15 0 0 1 20 0 + M5 12.5a11 11 0 0 1 14 0 + M8.5 16.1a6 6 0 0 1 7 0 (Lucide `wifi` w/o dot)
│       │   Bluetooth: m7 7 10 10-5 5V2l5 5L7 17 (Lucide `bluetooth`)
│       └─ text column gap 1: ui 14 / 500 ("Wi‑Fi", "Bluetooth"); ui 12 fgMuted ("Dom‑5G", "[słuchawki]")
├─ sliders card: column gap 16, padding 16 14, radius 20, bg tile
│   └─ row gap 12 (volume, brightness)
│       ├─ icon 17, stroke fgMuted 1.6: volume (Lucide `volume-1`); brightness circle r4 + M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4 (Lucide `sun`)
│       ├─ track flex 1, h 6, radius 3, clip; dark bg chip (Live), light #CFCADA; fill h 6 sliderFill (fg), no own radius, width = value% (volume: 260 ms Curve E)
│       └─ value: mono 12, width 28, right, fgMuted
├─ round toggles: grid 4 equal cols, gap 10, padding 2 0
│   └─ column centred, gap 6
│       ├─ circle 50×50, radius 25; on: bg accent, icon onAccent, stroke 1.8; off: bg tile, icon fg, stroke 1.6; icon 18
│       └─ label ui 11, fgMuted
│       "Skupienie" (on): moon · "Ciepłe światło": circle r4 + M12 2v2M12 20v2M2 12h2M20 12h2 · "Nagrywanie": circle r8 + filled circle r3 (Lucide `circle-dot`-like) · "Zasilanie": M12 2v10 + M18.4 6.6a9 9 0 1 1-12.8 0 (Lucide `power`)
└─ mini player: row gap 12, padding 10, radius 20, bg tile
    ├─ art 40×40, radius 12
    ├─ text column flex 1, gap 1: ui 13 / 500; ui 12 fgMuted
    └─ play/pause 38×38, radius 19, inverseBg / inverseFg (dark #ECEAF2/#0B0B10, light #1E1B2A/#EFECF3), icon 14 stroke 2.2
```
- Light (Jasny): all `tile` → `ltile`; text `#1E1B2A`/`#5C5770`; track `#CFCADA`, fill `#1E1B2A`; ring `white@0.55`; shadow `0 18 50 rgba(40,30,70,0.2)`; sheen overlay (light, §2a).
- Derived sum: 16 + 50 + 10 + 62 + 10 + 82 + 10 + ~74 + 10 + 60 + 16 ≈ 400 of 440.
- W8: only Skupienie (DND) and Zasilanie remain; 4-col grid with 2 items unspecified [C#27]. Zasilanie action (open `power`?) unspecified. Jasny: holding "Ciepłe światło" toggles theme [C#27].
- W10: missing NM/BT/backlight → tiles / brightness slider hidden; resulting layout and height unspecified.

### 3.8 `power` — 540×180, r 30

Trigger: ⊞⇧E. Close: Esc, click outside. Dim `rgba(8,6,14,0.45)` fades in 400 ms ease.
```
column 540×180, padding 16 18 18, gap 14
├─ header: row baseline, space-between, padding 0 4
│   ├─ "Zasilanie": ui 14 / 600, fg
│   └─ hint ui 12 fgMuted: "Esc zamyka · strzałki + Enter"; while holding "trzymaj…"
└─ grid 5 equal cols, gap 8
    └─ button: column centred, gap 8, padding 4 0
        ├─ circle 60×60, radius 30, bg powerBtn #1C1B26 (holding powerBtnHeld #2C2A39; bg 200 ms ease); hover intended #26243A [C#21]
        │   fg #ECEAF2 (Wyłącz: danger #F2A7B8)
        │   ├─ ring SVG 60×60 viewBox 0 0 60 60, rotated −90° (start 12 o'clock, clockwise)
        │   │   circle (30,30) r 28, no fill, stroke 2.5, round cap, accent (Wyłącz: danger)
        │   │   dasharray 175.9 (≈ 2π·28 = 175.93); offset 175.9 empty → 0 full
        │   │   hold: → 0 over holdMs linear; early release: → 175.9 over 220 ms ease
        │   └─ icon 20, stroke 1.6
        ├─ label: ui 12, fgSoft #D9D5E3
        └─ key: mono 10, fgDim
```
| id | label | key text | hold | done label | icon |
|---|---|---|---|---|---|
| lock | Zablokuj | L | no | Blokowanie… | `rect x5 y11 w14 h10 rx2` + `M8 11V8a4 4 0 0 1 8 0v3` (Lucide `lock`) |
| sleep | Uśpij | S | no | Usypianie… | moon |
| logout | Wyloguj | przytrzymaj O | yes | Wylogowywanie… | `M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4` + `m16 17 5-5-5-5M21 12H9` (Lucide `log-out`) |
| reboot | Restart | przytrzymaj R | yes | Ponowne uruchamianie… | `M3 12a9 9 0 1 0 3-6.7L3 8` + `M3 3v5h5` (Lucide `rotate-ccw`) |
| off | Wyłącz | przytrzymaj P | yes | Wyłączanie… | `M12 2v10` + `M18.4 6.6a9 9 0 1 1-12.8 0` (Lucide `power`), danger |

- aria: risky "{label} — przytrzymaj, aby potwierdzić"; others "{label}". Focus-visible: accent@0.9, 1.5px, offset 4, radius 18.
- Derived height ≈ 16 + ~15 + 14 + ~112 + 18 ≈ 175–178 of 180.
- Keyboard: arrows + hold Enter (DESIGN); not prototyped; letter hotkeys and their hold behaviour unspecified [C#25].
- Light theme / glass level: not prototyped (`powerBtn` etc. unspecified) [C#16].

### 3.9 `powerDone` — 340×56, r 28
```
row 340×56, padding 0 20, gap 12, align centre
├─ dot 10×10, radius 5, accent, halo box-shadow 0 0 0 4px accentHalo
├─ label (role status): ui 14 / 500, flex 1 — done label
└─ "prototyp": mono 11, fgMuted — demo marker (drop or replace; unspecified)
```
Prototype → `rest` after 1800 ms; DESIGN: "po akcji" only [C#25].

### 3.10 `lock` — 460×360 card, top 210, all radii 36

Separate surface (`WlSessionLock`); the "slide" is simulated by animating the card from the `rest` position/size.

**Card container**
| prop | locked | unlocked (rest) | transition |
|---|---|---|---|
| top | 210 | 0 | 640 ms Curve S |
| size | 460×360 | 200×36 | 640 ms Curve S |
| radius | 36 all | 0 0 18 18 | 640 ms Curve S |
| bg / backdrop | dark `rgba(16,14,26,0.6)`, blur 30 sat 1.4; light = level `islandBg` + backdrop | same | — |
| shadow + ring | dark `0 24 80 rgba(10,6,20,0.45)` + `white@0.08`; light `0 24 70 rgba(40,30,70,0.25)` + `white@0.55` | same | — |
| sheen | dark none; light overlay (§2a) | | [C#3] |
Ears fixed at rest positions (704 / 820), opacity 0 when locked; `opacity 200ms ease`, delay 0 lock / 420 unlock.

**Content**
```
column 460×360, padding 30 28 24, align centre
├─ clock "18:49": ui 88 / 500, letter-spacing −0.045em, line-height 1, tabular, fg
├─ date "sobota, 10 października": margin-top 10, ui 15, dark fgLock #CFC8E0 / light fgMuted #5C5770
├─ password wrapper (shake target): margin-top 30
│   └─ field 340×52, padding 0 8, radius 26, row gap 12, align centre
│       bg dark white@0.07 / light tile; ring dark inset 1px white@0.12 / light inset 1px ink@0.08
│       error: inset 1.5px danger; box-shadow transition 200 ms ease; focus-within outline 1.5px accent@0.8 offset 3
│       ├─ avatar 36×36, radius 18, bg accent, "M" ui 16 (inherited default) / 600, onAccent (dark #121118, light #FFFFFF)
│       ├─ input (password): flex 1, h 40, ui 15, letter-spacing 0.12em, fg; placeholder "Hasło" fgMuted, letter-spacing 0
│       └─ submit 36×36, radius 18, inverseBg / inverseFg (dark #ECEAF2/#121118, light #1E1B2A/#EFECF3), icon 16 stroke 2: M5 12h14M13 6l6 6-6 6 (Lucide `arrow-right`), aria "Odblokuj"
├─ status (role status): margin-top 12, ui 13, height 18
│   normal fgMuted ("Hasło w prototypie: niri" is demo; real idle text unspecified)
│   error danger: "Niepoprawne hasło — spróbuj ponownie"
└─ bottom row: margin-top auto, row gap 18, ui 12, dark fgLock / light fgMuted; items row gap 6, icon 14 stroke 1.6
    ├─ battery: rect x2 y7 w17 h10 rx2.5 + M22 11v2 (Lucide `battery`) "78%"
    ├─ Wi‑Fi (3 arcs) "Dom‑5G"
    └─ bell "2 powiadomienia"  (count only)
    (Jasny light mock omits the icons and the status line — simplification, unspecified)
```

**Mini player (screen bottom)**: centred, bottom 32; 380×56, padding 0 10, gap 12, radius 28, `lockGlass` + `lockGlassRing`. Art 36×36 r10; text column flex 1 gap 1 (ui 13/500; ui 12 fgMuted); pause 36×36 r18 `#ECEAF2`/`#0B0B10` icon 14 stroke 2.2; next 32×32 icon 15 stroke 1.6. No prev, no eq. Light: unspecified.

**Corner buttons**: right 32, bottom 32, row gap 10; each 48×48, radius 24, `lockGlass` + ring, icon 18 stroke 1.6 fg: "Uśpij" (moon), "Wyłącz" (power). No hold, no danger colour [C#35]. Light: unspecified.

Mini player + corner buttons: opacity 0↔1, 300 ms ease, delay 520 lock / 0 unlock; interactive only while locked.

**Wallpaper**: dark locked `blur(22px) saturate(1.2) brightness(0.78)` + `scale(1.08)`; unlocked identity; both 700 ms Curve S. Light: `blur(18px) brightness(0.92)` (Jasny mock: layer inset −30 px to hide blurred edges; saturate/scale unspecified) [C#10].

**Windows layer**: locked opacity 0, scale 0.97; unlock: opacity 420 ms ease, transform 520 ms Curve S, both delay 240 (delay 0 when locking).

**Lock content timings** [C#3]
- `enter(base)` = opacity 260 ms Curve E @ `base`; transform 380 ms Curve E @ `base − 40`; filter 260 ms ease @ `base`.
- `exit` = opacity 140 ms ease, transform 180 ms ease, filter 140 ms ease.
- Lock content: lock → `enter(260)` from scale 0.92 + blur 8; unlock → `exit` to 0 / 0.92 / blur 8.
- Rest content (dots + clock): lock → `exit` to opacity 0, scale 0.9; unlock → `enter(380)`.

**Shake**: wrapper `translateX` 0% 0 → 20% −10 → 40% +8 → 60% −6 → 80% +3 → 100% 0; 380 ms, `cubic-bezier(0.36, 0.07, 0.19, 0.97)` applied **per keyframe segment** (CSS semantics: 5 × 76 ms eased steps). `shakeA`/`shakeB` alternation only restarts the animation.

---

## 4. Script-block logic worth porting

### 4.1 Live
- `go(m)` first clears all timers.
  - `notif`: mode `notif`, bar 100% no transition; +60 ms bar 0% `width 3400ms linear`; +3600 ms → `rest`.
  - `volume`: if already volume, +10 (wrap 100 → 10, demo); mode `volume`; +1600 ms → `rest` (restarts every change).
  - other: set mode.
- `k` = 3 for "zwolniony ×3", else 1.
- Effective `line` iff hiding && mode `rest` && !hover; enter cancels the 250 ms leave timer, leave starts it.
- Ears opacity 1 iff attached && eff ≠ `line`.
- Glass: `G = GL[glassLevel] || GL['ciekłe']`. `bg = eff==='line' ? rgba(236,234,242,0.75) : glass ? G.bg : '#0B0B10'`; `tile/sel/chip = glass ? G.* : subtelne hexes`; `sheenOp = glass ? G.sheen : 0`; `bdf = glass ? G.bdf : none`.

### 4.2 Jasny
- Static; `glassLevel` picks `{lbg, lbdf, ltile, lcard, lchip, sheenOp}` (§1.2), accent default `#5E48B8`. Token table rows (dark → light): Tło wyspy (szkło) `#100E1A · 62%` → `#E6E2EC · 80%`; Kafle `#17161F` → `#EFECF3`; Karta / zaznaczenie `#1F1E2A` → `#F3F1F6`; Chip / kbd `#2C2A39` → `#DDD9E5`; Tekst `#ECEAF2` → `#1E1B2A`; Tekst drugorzędny `#A29DB3` → `#5C5770`; Ścieżka suwaka `#2C2A39` → `#CFCADA`; Akcent `#B9A7F5` → `#5E48B8`; Na akcencie `#121118` → `#FFFFFF`; Ostrzeżenie `#F2A7B8` → `#B4405E`.

### 4.3 Notif
- State: `mode` ∈ {rest, toast, center}, `list` newest-first, `dnd`, `expanded{app}`.
- `push()`: prepend. If `dnd` or mode `center` → list only. Else mode `toast`, clear old toast timer, new 3600 ms timer → `rest` only if still `toast`.
- Grouping: groups in order of first appearance in newest-first list (group with newest item on top); items newest-first.
- Per group: `multi = n>1`; collapsed shows `items[0]`; `stack1 = collapsed && n>1`; `stack2 = collapsed && n>2`; `stackPad` 14/7/0; label "Pokaż {n}" / "Zwiń".
- Dismiss by id; clear group by app; clear all resets `expanded`.
- `restW = count>0 ? 252 : 200`; `hasMore = count>1`, `more = count−1`.
- `toCenter` clears toast timer; scrim → `rest`; DND toggle has no side effects. Opening center does not clear the badge (unspecified intent).

### 4.4 Power
- `down` (mousedown): risky only; clear hold timer; `holding = id`; `holdMs` timer → `finish(done)`.
- `up` (mouseup **and** mouseleave): if risky and holding this id → clear timer, `holding = null` (ring rewinds 220 ms).
- `click`: non-risky → `finish` immediately.
- `finish`: clear hold, `holding = null`, mode `done`, label; +1800 ms → `rest`.
- `toPower` clears pending timers; `toRest` clears hold.
- Ring is a visual transition; the action fires from the JS timer (both `holdMs`).

### 4.5 Lock
- `submit()` (Enter / →): correct → unlocked, clear pw/err; wrong → `err = true`, clear pw, `shake++`.
- Typing clears `err`. Lock action → locked, clear pw/err.
- All visuals are functions of `locked` with fixed delays (no JS timers). PAM replaces the `'niri'` check.

### 4.6 Sequencing summary (ms)
| event | timeline |
|---|---|
| state change | shape 0–460; old out 0–120 (scale 0–160); new scale 120–440, opacity/blur 160–380 |
| theme change | colours 0–600, no geometry change |
| glass level change | sheen opacity 0–300 (bg/tile/etc. transition unspecified) |
| osd | close 1600 after last change; bar 260 |
| toast | bar starts +60, empty at +3460; close +3600 |
| power hold | ring full at holdMs (900); release rewind 220; done → rest +1800 |
| lock | shape 640; wallpaper 700; rest out 0–180; lock content scale 220–600, opacity/blur 260–520; extras 520–820 |
| unlock | shape 640; wallpaper 700; lock out 0–180; windows opacity 240–660, scale 240–760; rest scale 340–720, opacity 380–640; ears 420–620; extras out 0–300 |
| auth error | shake 380 (5×76); ring colour 200 |

---

## 5. Icons (summary; supplementary — section map: §1 tokens, §2/2a/2b container + gloss + theme switching, §3 states, §4 script logic, §6 contradictions)

All 24-grid, round caps; stroke 1.6 unless noted [C#36]. W6: ship Lucide SVGs, tint from Theme.

| Meaning | Prototype path | Nearest Lucide | Size / stroke where used |
|---|---|---|---|
| volume | `M11 5 6 9H2v6h4l5 4V5z` `M15.5 8.5a5 5 0 0 1 0 7` | `volume-1` | 18 OSD; 17 control |
| brightness | circle r4 + 8 rays | `sun` | 17 control |
| warm light | circle r4 + 4 rays | `sun-dim`-like | 18 |
| record | circle r8 + filled r3 | `circle-dot` | 18 |
| power | `M12 2v10` `M18.4 6.6a9 9 0 1 1-12.8 0` | `power` | 18 control/lock, 20 power |
| moon (DND/sleep) | `M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z` | `moon` | 12 / 2 badge; 13 / 1.8 DND chip; 18 / 1.8 toggle on; 18 lock; 20 power |
| bell | `M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9` | `bell` (no clapper) | 12 / 2 badge; 14 lock |
| wifi | 3 arcs (no dot) | `wifi` | 17 / 1.8 tile; 14 lock |
| bluetooth | `m7 7 10 10-5 5V2l5 5L7 17` | `bluetooth` | 17 / 1.8 |
| search | circle (11,11) r7 + `m20 20-3.5-3.5` | `search` | 18 |
| screenshot | 4 corner brackets + circle r3 | `focus` | 20 (stroke accent) |
| check | `M20 6 9 17l-5-5` | `check` | 22 / 1.5 |
| close | `M6 6l12 12M18 6 6 18` | `x` | 12 / 2 |
| skip back / fwd | `m19 4-10 8 10 8V4z` `M5 5v14` / mirrored | `skip-back` / `skip-forward` | 15 |
| pause | `M9 5v14M15 5v14` | `pause` (as lines) | 14 / 2.2 |
| arrow | `M5 12h14M13 6l6 6-6 6` | `arrow-right` | 16 / 2 |
| lock | rect 14×10 rx2 + shackle | `lock` | 20 |
| log out | see §3.8 | `log-out` | 20 |
| reboot | see §3.8 | `rotate-ccw` | 20 |
| battery | rect 17×10 rx2.5 + `M22 11v2` | `battery` | 14 |

---

## 6. Contradictions / ambiguities

Contradictions (prototype vs DESIGN, prototype vs prototype, DESIGN vs DESIGN):
1. **Default glass level vs §3 defaults.** DESIGN §3 lists `island.bg rgba(16,14,26,0.62)`, blur 24, sat 1.5 as defaults, but §3b and Live default `glassLevel` is `ciekłe` (`rgba(22,18,36,0.28)`, blur 44, sat 2, brightness 1.05, translucent tiles, full sheen) — "do potwierdzenia".
2. **Solid fallback.** DESIGN: same bg alpha ~0.78, no blur. Live `material: solid`: `#0B0B10`. DESIGN wins; light solid unspecified.
3. **Lock material.** Dark Lock: lock-specific bg 0.6 / blur 30 / sat 1.4, shadow `0 24 80 @0.45`, ring 0.08, no sheen, own content timings (260/380/260 enter, 140/180/140 exit, scale 0.92/0.9, blur 8). Jasny light lock: regular level bg/backdrop, ring 0.55, shadow `0 24 70 rgba(40,30,70,0.25)`, sheen on. DESIGN mentions none of it.
4. **Card vs selection.** DESIGN §3a "card / zaznaczenie" = `#1F1E2A` dark, but dark selection (launcher row, toast box) is `#1E1D28` (DESIGN §6 and Live `sel`). Light merges both into `#F3F1F6` / `lcard`.
5. **Track vs chip.** DESIGN: `track #2C2A39` = `chip` in dark, light `track #CFCADA` ≠ `chip #DDD9E5`. Live now draws dark slider/OSD tracks with `chip` (per glass level, e.g. `white@0.14`); Jasny draws light tracks with fixed `#CFCADA` at every level.
6. **Colours absent from DESIGN**: `#1C1B26`, `#191823`, `#15141D`, `#D9D5E3`, `#CFC8E0`, `#1F1E29` (likely typo of `#1F1E2A`), light `#D6D2DF`, `#EFECF3` as inverse fg, `white@0.06/0.07/0.12`, `ink@0.08`.
7. **Accent options.** DESIGN §3a gives only `#5E48B8` for light; Jasny offers `#8A5A1E`, `#2F7A68`, `#A23D5C` as light counterparts of the dark options — not in DESIGN.
8. **On-colour split (dark).** DESIGN `onAccent #121118`; dark prototypes also use `#0B0B10` on accent circles (control) and on `#ECEAF2` play buttons, `#121118` on lock submit. Light resolves to one `onAccent #FFFFFF` and a separate inverse pair `#1E1B2A/#EFECF3`. Proposal: `onAccent` + `inverseBg/inverseFg` tokens.
9. **Hard-coded accent alphas**: badge `rgba(185,167,245,0.18)`, halo 0.2, focus 0.9 / 0.8 do not follow the accent prop (and would be wrong for light accent `#5E48B8`).
10. **Light lock wallpaper.** DESIGN §3a/Jasny: blur 18, brightness 0.92; saturate (dark 1.2) and scale (dark 1.08) not restated — keep or drop unspecified.
11. **Light backdrop per level.** DESIGN §3b: mocne sat 1.8, ciekłe sat 2.0 / brightness 1.05 (one value for both themes). Jasny light: mocne sat 1.6, ciekłe sat 1.8 / brightness 1.04; subtelne light sat 1.3 — DESIGN §3a (1.3) contradicts DESIGN §3b (1.5, single column for both themes); Jasny follows §3a.
12. **Light ciekłe vs mocne tiles/sel.** `tile` 0.42 → 0.40 and `sel` 0.52 → 0.50 decrease from mocne to ciekłe while dark increases (0.06 → 0.07, 0.10 → 0.12). Possibly intentional; confirm.
13. **Per-level blur vs W1.** W1: blur strength is global in niri; §3b/Live specify blur 24/36/44 and saturate/brightness per level. Per-surface radius/saturate/brightness likely not achievable via `ext-background-effect`.
14. **Ear material/transition differs per prototype.** Live: level backdrop, `left 460 S` + `opacity 160 ease`. Notif/Power: `blur(24)` only, `left` only. Lock: fixed, `opacity 200 ease` @0/420. Jasny: no backdrop.
15. **Fonts.** Measured with Geist; W5 default JetBrainsMono Nerd Font for both; letter-spacing and fixed widths (rest 200, value 28) may not hold with a monospace UI font.
16. **Hard-coded colours outside the glass system.** `card #1F1E2A`, `powerBtn #1C1B26`, `stack1/2`, `dndOffBg`, `lockField`, `scrollThumb #2C2A39` stay opaque/solid in every glass level and have no light values; at `ciekłe` they will look like opaque blocks among translucent tiles (DESIGN §3b: "Kafle przy mocnym/ciekłym szkle są półprzezroczyste").
17. **Spring curve / enter blur curve.** `cubic-bezier(0.34,1.3,0.5,1)` option and "zwolniony ×3" exist only in Live/Ruch. Enter blur uses `ease`, not Curve E (DESIGN gives no curve).
18. **Ring/sheen on ears.** HTML ring, shadow and sheen exist only on the rectangle; a single QML path would stroke/gloss the ear curves too — choose.
19. **Line state appearance.** Live keeps shadow, ring and sheen at 56×5; intent unclear (likely drop).
20. **Priority wording.** DESIGN: launcher › panel/power/center › toast › osd › media; Ruch omits power/center. DESIGN wins.
21. **Power hover dead code.** `.pbtn:hover .pcirc{background:#26243A}` is overridden by the inline `background`; intended hover `#26243A` never shows.
22. **Rest click target.** Live/DESIGN: rest → control; Notif: whole rest → center. DESIGN implies badge → center, rest → control.
23. **Scrim scope.** Live: every non-rest state (incl. osd/toast/media); Notif: center; Power: power; DESIGN W3: modal states only.
24. **Lock position.** DESIGN "na środku"; prototype `top 210` on 900 px (centre = 270). Jasny mock uses top 20 inside a 400 px frame (illustrative). Rule for other resolutions unspecified.
25. **powerDone lifetime / keyboard.** Prototype auto-returns after 1800 ms; DESIGN "po akcji". "strzałki + przytrzymanie Enter" not prototyped; letter hotkeys' behaviour unspecified.
26. **Sheen inner glow in light.** DESIGN §3b: glow 30 px white 6% (no light value); Jasny light overlay has no glow. DESIGN gradient omits the 45% stop (`0.02` dark / `0.06` light) present in both prototypes.
27. **Theme quick toggle vs W8.** Jasny: hold "Ciepłe światło" in panel toggles theme; W8 removes Ciepłe światło. Control grid stays `repeat(4)` with 2 remaining toggles — layout unspecified.

Ambiguities / unspecified:
28. **Reduced motion and shape**: only "crossfade 120 ms" — whether the shape morph is instant or still 460 ms is unspecified.
29. **Two toast variants** (Live: `sel` box + accent icon, "body · app", "teraz", progress bar; Notif: app-colour letter, "app · body", `+N`, no bar) — build which / merge.
30. **Rest width with eq + badge** both visible (only 200 and 252 defined).
31. **Center height bottom term** 16 vs padding 14.
32. **Launcher capacity / scope.** 356 px fits 3 rows; `^1–9` implies more (scroll vs cap); chips include out-of-scope `/ pliki` and omit VPN/clipboard; non-app row anatomy unspecified.
33. **Notification app colours/icons** source (app icon, hash, palette) unspecified; `+N` = total − 1 vs DESIGN "seria"; whether opening center resets the badge.
34. **Media trigger "hover"**: what is hovered, media timeout, play icon, OSD brightness/mute icons unspecified.
35. **Lock corner "Wyłącz"**: no hold, no danger colour, unlike the power menu.
36. **Icon stroke widths**: DESIGN 1.6; prototypes also 1.5, 1.8, 2, 2.2 (Lucide default 2).
37. **Light values missing** for: `line`, `fgDim`, `hover`, `dotInactive`, `fgSoft`, `powerBtn*`, `stack*`, `dndOffBg`, `scrimDim`, `lockGlass*`, `accentSoft/Halo`, focus rings, `danger` error ring (presumed `#B4405E`); light rest/osd/media/toast/center/power/powerDone not prototyped.
38. **Theme switching details**: sunrise/sunset source, wallpaper-brightness thresholds and hysteresis, crossfade easing, and how glass-level changes animate (only sheen 300 ms is given); DESIGN §3b legibility boost (text-shadow / alpha raise when wallpaper brightness > 0.7) has no values.
39. **Letter size in icon boxes**: toast letter, launcher placeholders, lock avatar "M" inherit 16 px; only center cards set 14.

Count: 27 contradictions + 12 ambiguities = **39 entries**.

---

## 7. Resolutions (binding for implementation; proposed 2026-10-10, confirmed at the plan gate)

Numbers refer to §6. Where a resolution invents a value, it is a default token in `lib/theme.js` — overridable from config.

- R1 [C#1] Default `glassLevel` = `ciekłe`. §3 "defaults" are the `subtelne` row.
- R2 [C#2] Solid fallback (`glass: false`): `islandBg` = the level's dark/light base colour at alpha 0.78 (dark `rgba(16,14,26,0.78)`, light `rgba(230,226,236,0.78)`), tile/sel/chip = `subtelne` values, sheen 0.
- R3 [C#3] Lock card uses the island material of the current level and theme (bg, ring, sheen) + its own shadow token (`lockShadow` dark `0 24 80 rgba(10,6,20,0.45)`, light `0 24 70 rgba(40,30,70,0.25)`). Lock content timings as in §3.10.
- R4 [C#4] Separate tokens: `card` (notification card) and `sel` (selection). Dark `card` `#1F1E2A`, light `card` `#F3F1F6`; at `mocne`/`ciekłe` `card` = that level's `sel`.
- R5 [C#5] `track` = `chip` of the level in dark; light `track` `#CFCADA` fixed. Two tokens kept.
- R6 [C#6,16,37] Opaque one-offs map onto glass tokens: `powerBtn` = `tile`, `powerBtnHeld` = `chip`, `hover` = `sel`, `dndOffBg` = `chip`, `scrollThumb` = `chip`, `lockField` dark `white@0.07` / light = `tile`, `stack1` = `card` @ opacity 0.7, `stack2` = `card` @ opacity 0.45, `fgSoft` = `fg`, `fgLock` = `fgMuted` (light) / `#CFC8E0` (dark), `divider` dark `#1F1E2A` / light `#D6D2DF`. Invented light values: `fgDim` `#77728A`, `dotInactive` `#A9A4B8`, `line` `rgba(30,27,42,0.55)`, `scrimDim` `rgba(40,30,70,0.22)`, `lockGlass` = light `islandBg` of level.
- R7 [C#7] Accent options listed only as comments in `lib/theme.js` (dark: `#F1D6AE #8FD3C1 #F2A7B8`; light: `#8A5A1E #2F7A68 #A23D5C`).
- R8 [C#8] Tokens `onAccent` (dark `#121118`, light `#FFFFFF`) and `inverseBg`/`inverseFg` (dark `#ECEAF2`/`#121118`, light `#1E1B2A`/`#EFECF3`). `#0B0B10` is not used.
- R9 [C#9] Accent alphas computed from `accent`: `accentSoft` = accent @0.18, `accentHalo` = accent @0.2, `focusRing` = accent @0.9 (1.5 px). Never hard-coded.
- R10 [C#10] Light lock wallpaper keeps saturate 1.2 and scale 1.08; blur 18, brightness 0.92.
- R11 [C#11,13] Blur radius, saturation and brightness are compositor-side and static: niri `blur { passes 3; offset 5; }` (tuned visually for `ciekłe`), `layer-rule` for namespace `^wyspa$` with `background-effect { blur true; xray false; saturation 2.0; }`. Runtime glass-level switching changes bg/tile/sel/chip/card/sheen only. Brightness 1.05 is dropped.
- R12 [C#12] Light per-level values taken verbatim from Jasny.
- R13 [C#14,18] One fill path (body + ears, no seam). Ring and sheen are drawn on the body rectangle only; ears get fill + blur only. Ears fade with `motion.earFadeMs` 160.
- R14 [C#15] Fixed widths stay as tokens; letter-spacing tokens applied as given.
- R15 [C#17] No spring/slow options. Enter blur uses `ease`.
- R16 [C#19] `line` drops ring, sheen and shadow; fill = `line` colour.
- R17 [C#20] Priority: launcher 5 › control = power = center = powerDone 4 › toast 3 › osd 2 › media 1 › rest 0. A request with lower priority than the current non-rest state is ignored (a toast still increments the badge).
- R18 [C#21] Power circle hover = `hover` token.
- R19 [C#22] Rest: click on the badge → `center`; click elsewhere → `control`.
- R20 [C#23] Click-outside closes only modal states (launcher, control, power, center). Visible dim only under `power`.
- R21 [C#24] Lock card centred vertically and horizontally on each screen.
- R22 [C#25] `powerDone` auto-returns to `rest` after 1800 ms. Keyboard in power: ←/→ move focus, Enter press/hold acts like the pointer, letters L/S/O/R/P act like press on that button (hold still required for O/R/P).
- R23 [C#26] Gloss gradient has 3 stops (0, 0.45, 1) as prototyped; light has no inner glow.
- R24 [C#27] Panel toggles: DND, Motyw (dark↔light, manual), Zasilanie — 3 toggles, grid columns stay 4-wide spacing, centred.
- R25 [C#28] Reduced motion: shape snaps (duration 0), content crossfade 120 ms only.
- R26 [C#29] Toast = NotifLive variant (app letter/icon, "app · body", `+N`) plus the Live progress bar (2 px, 3400 ms linear, delay 60).
- R27 [C#30] Rest width = 252 whenever the badge is visible (eq does not change width).
- R28 [C#31] Center height formula as in §4.3 with bottom term 16.
- R29 [C#32] Launcher shows 3 rows and scrolls; `^1–9` activate the n-th row of the current result list; chips: `=` `>` `@` (no `/`); VPN and clipboard menus appear as rows in the default list (icon + title + "menu" subtitle).
- R30 [C#33] Notification icon: `image` or `appIcon` if present, else app-name initial on a colour picked by a stable hash of `appName` over the four accent options of the current theme. `+N` = notifications in the current series − 1 (series resets when the toast hides). Opening `center` marks all read (badge → 0).
- R31 [C#34] Media opens on hover over `rest` while a player is playing; leaves 250 ms after the pointer leaves. Media/OSD icons: Lucide `play`/`pause`/`skip-back`/`skip-forward`, `volume-x`/`volume-1`/`volume-2`, `sun`.
- R32 [C#35] Lock corner "Wyłącz" requires the same hold as in the power menu (danger ring); "Uśpij" acts immediately.
- R33 [C#36] Icon stroke = `sizes.iconStroke` 1.6 everywhere.
- R34 [C#38] Theme auto modes: `sun` needs `island.location {lat, lon}` in config (no location → stays manual); light between sunrise and sunset. `wallpaper`: mean luminance of the wallpaper, light if > 0.6, dark if < 0.5 (hysteresis). Legibility boost: if luminance of the wallpaper area under the island > 0.7 (dark theme only), `islandBg` alpha + 0.2. Crossfade easing `Easing.InOutQuad`.
- R35 [C#39] Letters in icon boxes: 16 px unless the section says 14.
