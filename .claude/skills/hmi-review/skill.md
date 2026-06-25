---
name: HMI Review
description: Audit a UI module against the industrial-HMI canon (ISA-101, High Performance HMI Handbook, Tufte). Use when a screen should look and behave like an enterprise SCADA / industrial monitoring tool rather than a consumer app. Triggers on requests like "review the dashboard", "this UI feels off", "make it look more industrial", "audit the HMI".
---

## HMI Review — Industrial Monitoring First

The product (EventPlatform) is a real-time event processing platform consumed by **plant operators**, not consumers. The UI must look, feel, and behave like enterprise SCADA / industrial monitoring tooling (think AVEVA System Platform, Inductive Automation Ignition, Honeywell Experion, ABB 800xA, Grafana in industrial profile).

**The single most important rule:** consumer-app design choices that optimize for engagement, brand expression, or aesthetic delight are *wrong* here. Operator ergonomics, glanceability, and signal-to-noise win every time.

---

## The Canon (read before auditing)

### ISA-101 / High Performance HMI Handbook (Bill Hollifield)

1. **Color is reserved for state and alarms** — not for decoration, branding, or hierarchy. A "normal" screen is mostly grayscale.
2. **Alarms own the colors** — red = critical, amber = warning, blue/cyan = info, green only when it carries operational meaning (running / closed / ok). Never red-on-red or 5 reds competing.
3. **Background is muted neutral** — light gray (`#E5E5E5` family) or dark slate (`#1B1F23` family). Never pure white, never pure black, never colored gradients.
4. **Information at a glance** — operator must read the state of the plant in under 3 seconds. Anything that requires hovering, scrolling, or counting fails this.
5. **Process-first layouts** — the visual flow of the screen mirrors the physical/logical flow of the process. Pipeline left-to-right or top-to-bottom matches the data path.
6. **Density appropriate to role** — overview screens are dense; detail screens isolate one subject. Never the inverse.
7. **No surprise motion** — animation only when it conveys *new* information (state change, alarm fire). No looping spinners, no decorative transitions, no parallax.

### Tufte — Data-Ink Ratio

- Maximize ink that conveys data. Eliminate gridlines, borders, drop shadows, container chrome that don't help reading.
- Sparklines and small multiples beat large isolated charts when the operator needs to compare many series.
- Never use 3D, never use exploded pies, never use dual y-axes unless absolutely necessary.

### Refactoring UI (Adam Wathan / Steve Schoger) — adapted for industrial

These principles still apply, but with industrial discipline:
- **Hierarchy via size, weight, position — not color.** Color stays for state.
- **Spacing is the cheapest improvement.** When in doubt, add space.
- **Tabular numbers** (`font-variant-numeric: tabular-nums`) for any column of values — operators scan columns vertically.
- **Monospace for IDs / codes / metrics.** Sans for prose. Never the inverse.

---

## What to Look For (audit checklist)

When auditing a module, walk through each category. Flag deviations explicitly.

### 1. Color discipline
- [ ] Background is muted neutral (not pure white, not pure black).
- [ ] Color appears **only** on: state indicators, alarms, the one accent for primary action, and active navigation. No decorative gradients, no brand-color blocks of chrome.
- [ ] Semaphore color is consistent everywhere: critical=red, warn=amber, ok=green-with-meaning, info=cyan/blue, unknown=neutral.
- [ ] No green used as "primary button color" — primary actions use the neutral accent, green is reserved for "running/ok" state.
- [ ] Contrast meets WCAG AA on every text-on-color combination. Operator may be in glare or bad lighting.
- [ ] Tested against deuteranopia (red-green colorblind) — state must be readable via shape/icon, not color alone.

### 2. Typography
- [ ] Body text 13–14px (sans). Operators sit at desks; no oversize hero text.
- [ ] Metric values monospaced with tabular numbers.
- [ ] Variable IDs / asset IDs / measure IDs in monospace.
- [ ] Maximum 2 type families (one sans, one mono). No display fonts, no script.
- [ ] Weight hierarchy: 400 body, 500 emphasis, 600 metric values, 700 reserved.
- [ ] All-caps reserved for short labels (≤2 words) with letter-spacing.

### 3. Information density & glanceability
- [ ] Overview screens (dashboards) pack 7–12 facts in one viewport without scrolling.
- [ ] Each fact answers: *what is it, what is its state, what is the value, how old is the value*.
- [ ] No "empty" panels — if a card shows only a number, it must also show timestamp/units/trend.
- [ ] Timestamps for any live data ("updated 4s ago"). Stale data is dangerous.
- [ ] Units explicit on every measurement (°C, bar, RPM, msg/min). No naked numbers.

### 4. State and alarms
- [ ] Every component that can be UP/DOWN/DEGRADED shows that state via a discrete semaphore indicator (dot, band, or tag) — not via color of the whole card.
- [ ] Open alarms / OPEN circuit breakers / DOWN services pull the eye with stronger contrast and shape, not just hue.
- [ ] Acknowledged vs unacknowledged alarms are visually distinct.
- [ ] "Healthy" state is *quiet* — minimal visual weight. Only abnormal state demands attention.

### 5. Charts
- [ ] No 3D, no gradients, no pie charts. Line/bar/sparkline only.
- [ ] Axis labels with units. No truncated axes that mislead.
- [ ] At most 4 series in one chart; beyond that use small multiples.
- [ ] Default to recent window (5–15 min) with clear time axis. Operator-time, not calendar-time.
- [ ] Gauges only for bounded measurements with a clear normal band shown.
- [ ] Animations on update are instant or under 200ms. No 1-second sweeps.

### 6. Tables & feeds
- [ ] Row height tight (32–36px) — operators scan a lot of rows.
- [ ] Numeric columns right-aligned with tabular numbers.
- [ ] Timestamp column always present, always relative-time-first ("4s ago"), absolute on hover.
- [ ] New rows in a feed appear at top with a brief (≤500ms) highlight, then settle.
- [ ] Loading states are skeletons that match final row shape, not centered spinners.

### 7. Motion & feedback
- [ ] No motion unless it carries information.
- [ ] State transitions ≤200ms.
- [ ] Spinners only for true async work; never as a "loading…" decoration on always-mounted panels.
- [ ] Hover states subtle (background tint shift, never lift/scale/glow).
- [ ] Focus states clear and visible for keyboard operators — many industrial UIs are operated without a mouse.

### 8. Navigation & wayfinding
- [ ] Persistent sidebar with module list — operator never wonders "where am I".
- [ ] Current module clearly indicated (left band, weight, or background tint — not just text color).
- [ ] Breadcrumbs or context bar when drilling into a single asset / variable / rule.
- [ ] No hamburgers on desktop. No nested dropdown nav.

### 9. Affordances & operator ergonomics
- [ ] Clickable elements are obviously clickable (cursor pointer, hover state, button shape).
- [ ] Destructive actions require confirmation and are visually demoted (not primary red button).
- [ ] Forms have inline validation, no surprise modal errors after submit.
- [ ] Keyboard shortcuts for the 3–5 most common operator actions (search, navigate, ack alarm).
- [ ] All-day comfort: dark mode is the default for control-room contexts; light mode is optional.

### 10. Localization & accessibility
- [ ] All copy via i18n (no hardcoded strings).
- [ ] Numbers and dates respect locale.
- [ ] Screen-reader text on every icon-only button.
- [ ] Color is never the only carrier of meaning (icon + color, or shape + color).

---

## Anti-patterns (flag immediately)

| Consumer-app pattern (avoid) | Industrial-grade pattern (favor) |
|---|---|
| Branded gradient background | Muted neutral background |
| Green primary button "Sign up" | Subdued accent primary; green reserved for "running" |
| Drop shadow on every card | Single hairline border or background tint shift |
| Big hero number with subtitle "We processed…" | Compact metric with unit, timestamp, severity dot |
| Rotating spinner on the page | Skeleton matching final layout, or inline progress |
| 2-line motivational microcopy | One terse imperative label |
| Animated illustrations | Static schematic where it conveys topology |
| Pie / donut with 6+ slices | Bar chart sorted descending |
| Round badges with brand color | Square tag with semaphore color, monospace value |
| Sentence-case "Loading your data…" | UPPERCASE "LOADING" or nothing |
| Dual y-axis "to be fancy" | Two stacked sparklines with shared time axis |
| Full-bleed images / photos | Schematic or none |
| Custom illustration for empty state | "No alarms" in muted text with timestamp |
| Dark theme = inverted palette | Dark theme = paper-white text on slate, accents unchanged |

---

## Workflow

1. **Inventory** — list the components/screens in scope. For each, capture:
   - File path and approximate role.
   - The category(ies) from the checklist it must satisfy.
2. **Read sources** — open each component file. Note inline color literals, hardcoded sizes, motion durations, copy, layout primitives.
3. **Map against canon** — for each component, walk the 10-category checklist. Mark each item PASS / WARN / FAIL with one short reason.
4. **Group findings by severity**:
   - **Critical**: violates safety/glanceability (alarms not distinguishable, stale data with no timestamp, color-only state, contrast below WCAG AA).
   - **Major**: degrades operator efficiency (wrong density, missing units, chartjunk).
   - **Minor**: polish (spacing, weight, copy).
5. **Propose concrete edits** — file:line references with the specific change. Group by component to make application straightforward.
6. **Show before/after sketch** — for each major finding, describe the current pattern in one line and the industrial replacement in one line.

## Output Format

Produce a prioritized report:

```
# HMI Review — <module name>

## Critical
- [<component> · <file>:<line>] <problem>. → <concrete fix>.

## Major
- [<component> · <file>:<line>] <problem>. → <concrete fix>.

## Minor
- [<component> · <file>:<line>] <problem>. → <concrete fix>.

## Strengths (don't regress these)
- <thing that already aligns with the canon>

## Suggested order of work
1. <smallest change with biggest visual impact>
2. ...
```

Keep findings concrete and file-anchored. Never write "improve visual hierarchy" — write "[ServiceHealthCard · ServiceHealthCard.tsx:43] heading is fontSize 18 with no weight emphasis; bump to 600 and add a 4px semaphore band on the left so state reads before text".

## Constraints

- Read components in full before pronouncing; do not audit from filenames alone.
- Cite tokens that exist (`var(--sev-critical)`, `var(--font-mono)`) before inventing new ones.
- Respect what already works — flag in "Strengths" so subsequent edits don't regress.
- Never propose a marketing-style polish. If a finding sounds like a SaaS landing page improvement, it does not belong in this report.
- Do not propose adding decorative imagery, illustrations, mascots, or hero sections.
- When in doubt, choose the more boring option. Industrial UIs age into their style, not out of it.
