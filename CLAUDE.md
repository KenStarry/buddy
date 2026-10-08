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

- **White is the accent.** On a 4%-luminance page a white pill is already the
  loudest thing available, so `primary` is achromatic in both modes and the
  scheme's `accent` is a *data* colour — progress, focus, selection, charts.
  Painting a CTA with the accent makes it quieter, not louder.
- **Surfaces separate by fill, not elevation.** A drop shadow on near-black
  subtracts light that isn't there. Hence four surface steps where the old
  cream palette needed three, and hence `BudgyShadows` doing very little on
  this ground. The no-borders rule below is what makes that discipline
  necessary rather than optional.

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
