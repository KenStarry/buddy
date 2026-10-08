# Budgy

A modern budget tracker. Local-first, Flutter, following the house spec at
`~/.claude/flutter_architecture_spec.md` — read that first; this file records
only what is **specific to Budgy** or where Budgy deliberately diverges.

Functionally it follows Cashew's lead (budgets with per-category limits and
past-period history, goals, multi-currency wallets, subscriptions, credit &
debt, upcoming/overdue, a composable home screen). Visually it owes Cashew
nothing.

## Run it

```bash
flutter pub get
dart run build_runner build          # after touching any @riverpod provider
flutter test                         # money + ledger maths
flutter run
```

First launch seeds a furnished three-month demo ledger
(`BudgyConstants.seedDemoData`). Settings → *Start fresh* clears it; *Load the
demo month* re-seeds.

## Layout

```
lib/
├── core/            theme, components, surfaces, routing, Hive, shared domain
├── features/        accounts budgets categories goals home onboarding plans
│                    reports settings shell transactions
└── modules/ledger/  the derived-numbers engine (LedgerMath + providers)
```

`modules/ledger` is the one cross-cutting service: pure static maths over
lists in `domain/ledger_math.dart`, exposed as `@riverpod` providers. **Every**
derived figure in the app comes from there, which is what stops the home
screen, a budget card and the reports page disagreeing about the same month.

## Decisions worth knowing before you change something

**Money is `int` minor units, everywhere.** Doubles never hold money. Amounts
are stored unsigned and `TransactionType` supplies the sign — see
`TransactionModel.amountMinor`. Each row snapshots its own `currencyCode`
rather than reading it off the wallet, so renaming a wallet's currency cannot
rewrite history.

**Two axes on a transaction, not one.** `TransactionType` is direction
(expense/income/transfer); `TransactionNature` is lifecycle (standard,
subscription, repeating, upcoming, debt, credit). Cashew folds both into one
dropdown and then has to answer "is a borrowed amount income?" in the UI. Here
a debt you took on is `income` × `debt`.

**Unsettled rows are plans, not facts.** They never touch a balance or a
budget's spend. They do count against the home screen's safe-to-spend figure —
rent due Friday is not money you can spend on Thursday.

**Expenses are not painted red.** Nine rows in ten are expenses; colouring
them all red makes the ledger read as a list of errors and spends the alarm
colour on the normal case. Direction is the sign and the glyph. Red is held
back for over-budget and destructive actions.

**No borders. Anywhere.** Cards are lifted by shadow (`BudgyShadows`, which is
brightness-aware) and by fill — light mode is white cards on warm cream, dark
mode steps the surfaces far enough apart that a card separates before its
shadow does any work. `Border.all` survives only on *marks*: a selection ring,
a checkbox, a separator between overlapping swatches. Adding one to a surface
is a bug.

The edge highlights on glass surfaces are **not** an exception. They are
speculars — a gradient-faded line that traces the real silhouette (scoops
included) and fades out a third of the way down, modelling the light the glow
beneath is already casting. A specular never closes around a shape; that is
what an outline does, and what flattens a surface into a diagram.

**Budgy is a dark app.** Not "an app with a dark mode" — the composition is
designed on near-black (`BudgyPalette`, *Midnight*) and light mode is the
accommodation, which is why `HiveService.themeMode` defaults to dark rather
than to the system setting. A budget screen is mostly large numerals, and
white numerals on near-black have ~18:1 contrast with no competing surface, so
the figure is the only bright object in the frame.

Two consequences worth not undoing:

- **White is the accent — and it is rationed.** On a 4%-luminance page a white
  pill is the loudest thing available, so `primary` is achromatic in both modes
  and the scheme's `accent` is a *data* colour (progress, focus, selection,
  charts). But loudest only works if it is rare: white is for a screen's
  **single primary action** (`BudgyFilledButton`) and the nav's active disc.
  A *row* of equal actions is not that — the home CTAs are three peers, and
  three white slabs spend the whole budget at once. They ride the surface
  ladder instead.
- **Surfaces are an elevation ladder, and separate by fill.** A drop shadow on
  near-black subtracts light that isn't there, so `surface100→400` carries what
  elevation normally would: page, card on page, thing on card, top of stack. A
  widget picks its step by asking *what am I resting on*, not *am I an input or
  a chip*.

  ⚠️ On near-black there is no **down**. A recessed input cannot be painted
  darker than a page already at 2% luminance, so raised and recessed things
  step up the same ladder; what separates them is the **edge**. A raised
  surface catches a specular along its top (`GlassCard`, `ScoopButton`), a
  recessed one does not. Reaching for a darker fill to say "inset" is the one
  move this ramp cannot make — and it is why `ScoopButton` derives a pane
  gradient and an edge highlight from whatever fill it is handed: without them
  a surface-filled button flattens straight into the page it sits on.

**Display weights are 600, not 800.** Heavy numerals were right on cream, where
a figure had to fight a white card. On near-black the same weight reads as
shouting, and at 48pt a w800 Sora figure fills its own counters until it stops
looking like money and starts looking like a logo.

**The pocket is home's signature, and only home's.** `ScoopedSurface`
(`core/presentation/surfaces/scallop.dart`) is Budgy's one piece of
non-rectangular geometry: a rounded rect whose top edge is scooped by shallow
concave curves. A scoop is a *negative* shape — it says something is tucked in
behind this edge — which is what lets the accounts sit behind the balance
panel and read as one assembly rather than as two rectangles, and what lets
each action button's glyph nest in a mouth its own edge opens.

⚠️ Scoop **width and depth are independent**, and the curve is a pair of
cubics rather than an arc. A circular notch ties depth to width, so any scoop
wide enough to look like a pocket mouth is also deep enough to look like a bite
taken out of the panel. Secondary screens get a plain masthead instead: a
signature repeated everywhere is wallpaper.

**Glass needs something to refract.** The ghost accounts and the balance panel
are frosted (`BackdropFilter` + a translucent white gradient + an edge
specular). A frosted panel over a flat near-black page blurs near-black and
produces near-black — a real `saveLayer` for an invisible effect. So
`AmbientGlow` (`surfaces/glow.dart`) lays wide, faint blooms *under* the stack
first, and the glass has colour moving through it.

⚠️ When a panel lights itself, the glow goes in `ScoopedSurface.underlay`, not
in a `Stack` behind it. Behind, it is clipped by nothing: it bleeds past the
rounded corners and, wherever the surface turns out narrower than its parent,
straight across the page as a raw rectangle of light.

⚠️ A glow that ends anywhere visible needs `AmbientGlow.fadeBottom`. A bloom
is a radial gradient still well above zero alpha when it reaches the edge of
its box, so the box **clips** it — and a clipped gradient is a hard horizontal
line across the page. A taller box only moves the line; fading the layer out
before its own edge is what makes the light die into the page instead of
stopping against it. The home header fills its own bounds and dissolves over
the bottom ~40%, with page padding below the action row for the fade to land
in.

**Chrome on a lit surface is glass, never `surface300`.** An opaque dark
circle on the header reads as a hole punched through it — the one place where
the glow visibly stops. The top bar's buttons are translucent white so the
light carries through. The one exception is the brand mark, which stays a
filled accent chip: a logo is the one place a flat block of brand colour is
doing its job rather than competing with a figure.

**One card material, one component.** `GlassCard` is the surface every
nameable object wears — a wallet, a budget, a goal. Three near-identical
implementations of it existed before it did, which is exactly how a design
language rots: each copy drifts a few percent on the gradient, a point on the
radius, a different falloff on the edge, and within a release the cards no
longer look related. Its recipe in order: near-black base, two blooms of the
object's hue, a white pane gradient, grain, an edge specular. `GlassGlyph` is
the matching tile — glass with a **coloured glyph**, never a solid chip of the
hue, which would be the brightest thing on the card and would win the eye from
the figure.

⚠️ **Both** blooms are the object's own hue, the second thrown only ~20°.
Using the brand accent for the second one puts the same cast on every card in a
list and undoes the thing the colour slot exists for. Throwing it far (35°+)
sends a tangerine card's second bloom to yellow, which at low luminance over
near-black is olive — the card reads dirty rather than lit.

**Ambient light is bright — `asLight()`, always, for data-derived hues.** A
mid-tone colour laid over near-black at low alpha does not read as coloured
light; it reads as dirty paint. Tangerine arrives brown, amber arrives olive,
and the screen looks stained rather than lit. ⚠️ Saturation has to be cut
*hard* (to about a third), not trimmed: at 85% a tangerine category still lit
the entry screen sepia. Real light is near-white at its core and only carries a
cast. `AmbientGlow` blooms whose colour
comes from data (a category slot, a wallet's hue) must be lifted to a light
source's lightness first; the low alpha then does the work of keeping it
subtle. Blooms inside a `GlassCard` are the exception — there the hue is
*material*, not light, and runs at full strength.

**Selection is a neutral fill step; the hue lives in the glyph.** `GlassPill`
brightens when picked and fills its glyph disc to full strength — it does not
tint its body. Category colour at pill alpha over near-black is the same mud as
above, so a chosen pill ended up looking soiled rather than selected.
**Brightness says *picked*, colour says *which*.** For the same reason there is
no selection ring: on glass a ring cannot be told apart from the edge specular
the surface already has.

**The entry screen is built outward from the figure.** The amount is ranged
**left** at 88pt and sits on the page, not inside a panel. Three attempts at
this screen failed the same way: the controls were fine and the screen was
bland, because every surface on it — direction cells, a glass slip, five
coloured orbs, the keys, the save bar — sat within a few percent of each other
in a narrow band of mid-grey, while the one thing that should dominate was
small, dim and *boxed*, which shrinks it further. Boxing a number is the
fastest way to make it stop being the point.

So: no panel around the figure; direction is set in **type** (the live word
white, the other two at 34% — same information, none of the ink three filled
cells cost); and the remaining terms are **one quiet bar of zones** rather than
five coloured orbs, which were the loudest thing on the screen after nothing
and are the least important part of an entry. Each zone still opens its own
anchored panel (`PillPopover`), and lights only when it holds a real choice
rather than a standing default — so "not today" is visible without reading.

Ranged left matters: centred, a figure reads as *a result*; ranged left at this
size it reads as something being typed, which is what it is. The optional label
sits on the same axis for the same reason.

**Sheets are a step above the page, and lit.** `BudgySheet` used to fill with
`surface100` — exactly the colour of the screen behind it — so its only edge
was the scrim, and on near-black a dimmed black against black is barely an edge.
It is raised a rung with a specular along its top, like every other surface that
arrives over something.

**One switch, one option row, app-wide.** `BudgySwitch` / `BudgyToggleTile`
replaced six `SwitchListTile.adaptive`, which is two different controls — a
Material one on Android, a Cupertino one on iOS — and neither is this app. On a
near-black page the Cupertino track in particular renders a bright grey that
reads as *on* when it is off. `OptionRow` is the house "pick one of these" row,
shared between the entry screen's anchored panels and the extras sheet, so a
goal chosen in a sheet and a wallet chosen in a popover look like the same act.

⚠️ Inside `BudgyToggleTile` the switch is wrapped in `IgnorePointer`: the whole
row is the target, and a nested tap target would swallow the press on the one
part of the row people actually aim at.

⚠️ The extras sheet carries an explicit **"Not toward a goal"** row. Without it
the only way to undo a goal is to tap the chosen one again — a toggle hidden
inside what looks like a single-choice list.

**The commit is a capsule that is not there until there is something to
commit.** Everything else on the entry screen is a circle, a word or one soft
bar; a full-width rectangle landing under a circular dial broke that outright,
and while *disabled* it carried real weight meaning nothing — a dead slab
anchoring the bottom of a screen you had not given an amount to yet.

So it is sized to its own words, centred, and absent until `canSave`. ⚠️ The
slot keeps its height either way: the dial must not jump when the first digit
lands. It arrives by scaling in, which turns "you can save now" into something
seen rather than noticed. White fill, because white is the single-primary-action
colour everywhere in the app; the **glow** takes the direction's hue, so the one
chromatic halo on the page belongs to the same light as the room.

**One date picker, `showBudgyDatePicker`.** Material's own is a white dialog
with its own type ramp, radii and primary colour; dropped into a near-black app
it does not read as a themed component, it reads as a different product briefly
taking over the screen. Theming it is not an option either — the parts that
look wrong (the header block, the input-mode toggle, the edit field) are the
parts `DatePickerThemeData` cannot reach. All three call sites (entry, goal
target, budget anchor) go through the house one.

**Tap commits; there is no OK button.** Picking a day *is* the choice. A
Cancel/OK pair would add a tap to the common case to guard against a mistake
that costs one tap to undo. Month paging and the year grid change what is
*shown* without committing, so there is still no way to pick by accident. Today
is marked in the accent rather than with a ring — a ring on an unselected cell
is one mark away from looking selected, which on a calendar is the single
ambiguity worth spending a colour to avoid.

**Glass only where you can see through it.** The popover panel and the date
card are **solid** — a raised fill with the light along the top edge — not
frosted. Both previously ran a `BackdropFilter` beneath a fill at ~96% opacity,
behind a scrim, over near-black: a `saveLayer` blurring something that was then
almost entirely painted over. Reach for `BackdropFilter` when there is
genuinely something behind worth refracting (the header's ghost accounts over
`AmbientGlow`); everywhere else it is cost with no picture.

**The pad is a dial, and a calculator.** Circular glass keys sized to a thumb
rather than twelve full-width slabs filling the bottom of a screen whose entire
point is one enormous number. A disc is the oldest "press here" there is, so the
affordance costs less ink and the contrast budget goes to the figure. Press is a
radial bloom from the centre plus a scale — a fill swap reads as a state change,
a bloom reads as *lighting up*.

A fourth column carries `÷ × − +`. Multiplication and division are not padding:
"three coffees at 250" and "split the 1,200 bill four ways" are the two sums
people do in their head before opening the app, and getting them wrong is how a
ledger quietly stops matching reality.

**The figure is an input field, caret and all.** `AmountField` renders the
formatted amount itself and draws a caret at an index, rather than wrapping a
`TextField` — which formats nothing, wants the system keyboard, and brings a
selection model far beyond "where does the next digit land". Tapping a digit's
left or right half places the caret either side of it, so an amount can be
corrected in the middle instead of backspaced to death.

⚠️ `caret` indexes the **raw** operand (`1250`), never the formatted display
(`1,250`). Group separators are display-only and deliberately not caret
positions or tap targets: a caret that could sit either side of a comma has two
positions meaning the same edit, and the keypad would have to understand commas
it never produced. A caret at raw index 1 therefore renders `1,|250`.

⚠️ The caret is positioned inside a **full line-box against cap height**, not
by baseline. The figure's Row aligns on the alphabetic baseline and a bare
container reports none, so the caret fell back to the top of the line and
floated ~15pt above the digits. Digits have no descenders, so cap height is
what a caret should centre on.

**The pad emits keys; the text owns the rules.** With a caret in play every
edit is an insertion *somewhere*, so the decimal, leading-zero and length rules
became rules about the string rather than about the key — they live in
`applyAmountKey`, which is pure and under test
(`test/money/amount_entry_test.dart`). ⚠️ The fraction cap must only bite when
inserting *after* the point: refusing a digit typed at the front of `19.99`
would block editing the whole part of any amount that already has two decimals.

⚠️ **There is no `=`, by design.** The figure always shows *what would be saved
right now* — with an operation pending it is the running result, not the operand
being typed — so `1,250 + 340` reads 1,590 the moment the last digit lands. That
removes a key, removes any state where the display and the saved value disagree,
and removes the commonest calculator mistake: pressing save before pressing
equals. A small line above the figure shows what is pending, because otherwise
the figure silently changes meaning the moment an operator is pressed.

⚠️ Two traps this cost me. `active: op == activeOp` makes **every digit key
active** when nothing is pending, because both sides are `null` — guard with
`op != null &&`. And a `BoxDecoration` with `gradient` set ignores `color`, so a
state that skips the gradient must set `color` itself or it renders as nothing
at all.

Division by zero returns the left operand unchanged: the divisor is read live
while being typed, so anyone reaching for "÷ 40" passes through "÷ 0", and a
figure that flashes `Infinity` is both alarming and a crash once it reaches
`toMinor`.

`MoneySize.entry` (62pt) exists for that figure, which is the largest in the
app because it is the only thing the screen is for. It kicks 3.5% on each
keypress: the same acknowledgement the haptic gives the thumb, for the eye.

**The screen is lit by its direction, and only by that.** `outflow` for a
spend, `inflow` for an income, `transfer` for a move — three fixed colours,
cross-faded on change. The keypad's press bloom takes the same tint, so a key
lights in the colour of what is being logged.

⚠️ It is **not** keyed to the chosen category, which is what it did first. That
looked right only by accident: arriving from the home screen, Spend and Income
happen to default to categories of different hues. Toggling direction in place
cleared the category, the tint fell through to a single fallback, and the room
stopped changing at all — the one thing the glow exists to show. Direction is
also the better source on its own terms: it is the entry's primary fact, it can
never be unset, and money leaving versus arriving is exactly the distinction
worth lighting a room over. The category's own colour still appears, in its
zone on the terms bar.

⚠️ Switching direction **re-seeds** the category for the new set rather than
just clearing it. The sets are disjoint, so a category chosen for an expense is
meaningless once the entry is income — but `_hydrate` only ever runs once, so
nothing was putting a new one back, and the form was left with no category at
all.

⚠️ Its bloom is anchored **above the top edge** and made wide, so only the
falloff is on screen. Centred inside the page a bloom resolves as a visible
disc — a spotlight parked behind the figure — and the eye reads its rim rather
than the light. Pushed off the top it becomes a wash pouring down the page,
which is what the home header does and what makes the two screens feel lit by
the same source.

⚠️ The dial is **pinned below the figure**, not inside a scroll view. It used
to scroll, and scrolled away under the save button — on the screen whose entire
job is pressing those keys. The page also sets `resizeToAvoidBottomInset:
false`: the only field that raises a keyboard is the optional label near the
top, and resizing would compress a column that has no slack to give.

⚠️ **`withValues(alpha:)` sets the channel, it does not scale it.**
`MoneyText`'s satellite style read `ink.withValues(alpha: 0.7)`, so any caller
passing a translucent ink — a placeholder amount at 22%, a muted row — got a
currency symbol at 70% against a figure at 22%: the label louder than the
number it labelled. Multiply by `ink.a` when stepping a colour *down* from
whatever was handed in.

**Disabled controls are glass, not a surface step.** `surface300` on a dark
page paints a slab *lighter* than the page around it, so a button that cannot
be pressed looked heavier than one that can. The same inversion was live in
`SegmentedPillTabs`, whose thumb was `surface200` on a `surface300` track —
the selected segment darker than the thing it sat in. Both are leftovers from
the cream palette, where a white thumb genuinely did lift off a sand track.

**Progress is a travelling wave.** `WavyMeter` is the house progress language:
a sine stroked with round caps, a gap, a flat remaining track, a stop dot.
(Material 3 Expressive's wavy indicator is the same idea; Flutter does not ship
one as of 3.47, and Budgy needs a pace marker on top of it anyway.) A flat bar
encodes one number and says nothing else; the wave encodes the same number and
adds a non-numeric channel — it *moves*, so a budget mid-period reads as live
rather than as a report. The motion is slow and the amplitude small by design:
this is texture, not animation.

⚠️ Two behaviours that are not decoration. The wave **flattens when short**
(below ~2.5 wavelengths there are too few crests for the eye to find a period,
and a budget at 8% renders as a worm). And the **pace marker is the entire
budget/goal distinction** — a budget is a quantity racing a clock, so 60% spent
is fine on day 25 and alarming on day 5; a goal is simply accumulating. Same
component, presence of the notch carries the meaning. This replaced the old
ring on goal cards, which made the point in a *different component* and left a
card showing the same fraction twice.

⚠️ `animated`, never `animate` — a bool member named `animate` shadows
`flutter_animate`'s `Widget.animate()` extension, and the error points at the
constructor with no mention of the field.

**A wallet is a card, but not its own paint chart.** `WalletCard` is a
`GlassCard` at a wider-than-physical aspect (1.92, deliberately **not** ISO 7810's
1.586: at full width that ratio makes a 220pt slab, and a column of them reads
boxy next to the header's accounts). Every other card cue survives the change.

An earlier pass filled each card edge to edge with a saturated field keyed to
its colour slot. Five of those in a list is a paint chart: every card shouts so
none leads, and the balance — the only thing anyone opens the screen for —
competes with its own background.

**The nav is icon-only.** A permanent 9pt label under four conventional icons
is telling people something they worked out on first launch; dropping it buys a
shorter bar, a bigger glyph, and room for the selection to be a travelling
*disc* rather than a stadium. The labels survive as semantics.

**Two type families, by role.** Sora for display and every number (flagged
`1`, tabular figures so rolling balances don't shudder); Manrope for body and
UI. Both ship as variable fonts, so `AppTheme` sets `fontVariations` alongside
`fontWeight` — without the explicit axis some devices silently render the
default instance.

**The category palette is inherited, not re-proven.** The eight slots in
`BudgyPalette.categoryDay/Night` were checked for colour-vision separation as
an *ordered set* — but against the **old** cream/emerald surfaces. Midnight
moved the ground under them (within ~2% luminance, so the result should hold),
and `scripts/validate_palette.js`, which the previous note pointed at, **does
not exist in this repo**. Treat the ramp as carried over: re-validate before
changing a hue, and write the validator while you are there.

The **relief rule** holds regardless and is honoured by construction: a
category never appears as a bare swatch — `CategoryGlyph` always pairs the
colour with an icon, and every chart ships direct labels. Categories carry a
`colorIndex`, never a free-form hex. Identity is never colour alone.

**The currency trails when the figure *is* the composition.**
`MoneyText.symbolTrailing` is for the balance panel and the wallet cards — a
leading `KSh` there is the first thing read on a line whose whole job is the
digits. In a list it stays leading, because a trailing unit ragged-rights the
column.

**Chart forms are chosen by the data's job.** Ranked bars + one part-to-whole
strip for spend by category (explicitly *not* a pie — any two arcs can be
compared, which puts a donut on the all-pairs list where the palette is only
safe for three slots). Diverging columns for in-vs-out. A single-hue sequential
heatmap for rhythm, scaled to the 90th percentile so one rent payment doesn't
flatten every ordinary day. A line for net worth.

**`MoneyText` uses `roll`, meters use `animated` — never `animate`.** A bool
member called `animate` shadows `flutter_animate`'s `Widget.animate()`
extension on that widget, and the resulting error points at the constructor
with no mention of the field.

**Hive stores JSON strings, not generated adapters.** The models already have
defensive `fromMap`s, so a schema change is a non-event and the stored form
stays inspectable. Reads are fail-soft per row — one bad row is skipped and
logged, never thrown, and never deleted.

**`JourneyStepper` for multi-step flows** (budget and goal creation). The
transaction form deliberately is *not* one: logging a coffee has to take about
four seconds, and a wizard for that is how people stop tracking.

## Tests

`test/money` and `test/ledger` cover the parts that must not be wrong:
formatting and parsing, currency conversion across decimal-count boundaries,
budget window maths (the 31st-anchor clamp, negative period indices,
contiguity), transfers being net-zero, and unsettled rows not counting.
