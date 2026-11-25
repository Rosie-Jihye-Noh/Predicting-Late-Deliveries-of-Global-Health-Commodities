# BUAN6356 Group D Presentation Outline (Revised)

**Predicting Late Deliveries of Global Health Commodities (USAID GHSC-PSM)**
10-minute talk + 3–5 minutes of Q&A · We present first · Revised Nov 25, 2026 · Numbers and sources re-checked

> ⚠️ **Note: numbers may change.** If we drop `order_type` from the logistic regression (recommended, see [Appendix A-2](#a-2-columns-and-variable-selection-dimension-reduction-data)), some LR numbers in this outline may shift slightly (in the decimals). We'll re-check the final numbers once that change is made.

The same outline as a Word file: [Presentation_Outline_EN.docx](Presentation_Outline_EN.docx)

---

## How to read this outline

- **[Data]** Checked by our own calculations on the final dataset (27,950 order lines)
- **[Source]** Backed by an outside source (see [Sources](#sources) at the end)
- **[Hypothesis]** Our best guess, not confirmed. In the talk, always frame it as "one possible reason"

As the professor asked, the methods (data cleaning, box plots, the split, the tree plot, the coefficient table, the accuracy tables) go to the **appendix**. The talk itself focuses on: why this topic → what we found → what it means → why we think we got these results.

## The story in one line

> Late medicine can interrupt treatment → when an order goes out, there are usually about four months left → can we use what's known that day to spot the risky orders? → what drives the risk, and why → what this means in practice, and where it falls short

## Timing and presenters (suggested)

| Presenter | Slides | Time | Covers |
|---|---|---|---|
| 1 | 1–3 | 0:00–2:55 | Why it matters, our question, Finding 1 |
| 2 | 4–8 | 2:55–6:35 | Findings 2–6 |
| 3 | 9–12 | 6:35–10:00 | What the early warning means, next step, practical use, limits and close |

---

# Part A. Why this topic

## 1. Why late deliveries matter
*(0:00–0:45 · Presenter 1)*

| | |
|---|---|
| **Suggested title** | Late medicine can mean interrupted treatment |
| **Visual** | Two big numbers (570,000; 61%) + one line on the Pasquet study. New graphic. Cite sources |
| **Transition** | So how often do deliveries miss, and can we see it coming? |

- **[Source]** About 570,000 people died of AIDS-related illness in 2025 (estimate range 430,000–780,000). About 61% of them, roughly 350,000 (240,000 in eastern and southern Africa + 110,000 in western and central Africa), were in sub-Saharan Africa (UNAIDS 2026).
- **[Source]** In one study in Abidjan, Côte d'Ivoire, patients whose HIV treatment stopped because of a stockout were 2.83 times as likely to drop out of care or die (95% CI 1.25–6.44; Pasquet et al. 2010). Make clear this is one study in one city.
- Message: a late delivery isn't just a logistics problem. It can reach a patient's treatment.

## 2. Our question, what's new, and an audience poll
*(0:45–1:50 · Presenter 1)*

| | |
|---|---|
| **Suggested title** | 1 in 9 order lines missed the delivery window. Can we spot them on order day? |
| **Visual** | Timeline graphic (order entered → day the PO goes out [prediction point] → 121 days → promised date) + 4-option poll. New graphic |
| **Transition** | Let's see what the data said. |

- About the data: public delivery records from GHSC-PSM, the USAID program that bought and shipped health supplies such as HIV drugs, malaria drugs and lab reagents to partner countries (data.usaid.gov, Internet Archive copy from June 11, 2024).
- **[Data]** Of 27,950 order lines placed between October 2017 and August 2023, **about 1 in 9 (11.4%, 3,173 lines)** didn't arrive within the promised window.
  - "On time" means anywhere from 2 weeks early to 1 week late. Most misses were late (2,910); a few came too early (263).
- **[Data]** On the day the order goes to the supplier, there are **usually about four months left (median 121 days)** before the promised date.
- Our question: **on that day, can we already tell which orders will miss?**
- **What's new** **[Source]**
  - Earlier studies used information that only exists **after the goods ship**, like shipped quantity and number of shipments (Gali et al. 2025) or freight cost, weight and insurance (Daneshgar et al. 2024). They didn't say **when** the prediction would be made, and they counted anything even one day past the expected date as late.
  - We use **only what's known on the day the order goes out**, and we judge delivery by the **program's official on-time rule**.
- **Audience poll (4 options):** "On order day, which is the strongest warning sign?"
  - (a) USAID approval took a long time  (b) it ships by sea  (c) there's little buffer time  (d) which country it's going to
  - Reveal on slide 3: (c) and (d) are the top two in both models. (a) and (b) are the twists (slides 8 and 4).

## 3. Finding 1: Buffer time is the strongest signal
*(1:50–2:55 · Presenter 1)*

| | |
|---|---|
| **Suggested title** | Buffer time is the strongest early signal |
| **Visual** | Bar chart of the miss rate by buffer range (table on this slide) + small table of each model's top two. Can also show the first split from `08_tree_plot.png` |
| **Transition** | But how much buffer is enough depends on how the goods travel. |

- Buffer time = the number of days between the supplier's promised ready date and the promised delivery date.
- **[Data]** With less than 71 days of buffer, **about 15%** of lines missed the window. With 71 days or more, **about 7%** did (15.2% vs 7.4% in the training data).
- **Why 71 days?**
  - **[Data]** We didn't pick it. **The decision tree found it.** The tree tries every possible cut and picks the one that best separates risky orders from safe ones. Its first cut was "buffer 70.5 days" (days are whole numbers, so under 71 vs 71 or more).
  - **[Data]** The miss rate **drops steadily** as the buffer grows, and the biggest drop is around 70 days (table below, full data).

    | Buffer time | 0 or less | 1–30 days | 31–70 days | 71–120 days | 121–180 days | Over 180 |
    |---|---|---|---|---|---|---|
    | Missed the window | 16.5% | 15.2% | 13.1% | 8.7% | 6.6% | 6.4% |
    | Order lines | 4,073 | 5,214 | 5,288 | 6,469 | 3,597 | 3,309 |

  - **[Data]** 71 isn't a magic number. Move the cut to 30 or 120 days and the low-buffer side still misses about twice as often (30 days: 15.7% vs 9.2%; 120 days: 13.0% vs 6.5%). The median buffer is 67 days, so 71 also splits the lines roughly in half (52% vs 48%).
- **[Data]** **In both models, the top two signals were buffer time and country.** Number three is well behind.

  | Model | 1st | 2nd | 3rd |
  |---|---|---|---|
  | Decision tree (variable importance) | Buffer time 12.6 | Country 11.3 | Product 9.0 |
  | Logistic regression (how much worse the model gets without it) | Country 278 | Buffer time 159 | Days left at PO 125 |

  *Note: country's score covers 13 countries as one group (12 terms), while buffer time is a single term. Term by term, buffer time was the strongest (z = 12.6).*
- **Why?** **[Data]** (based on the 77.5% of lines with a recorded actual ready date)
  - Suppliers ran more than a week late about as often whether the buffer was short or long (41% vs 36%).
  - But out of 100 lines where the supplier ran late, **about 24** missed the window with a short buffer, versus **about 13** with a long one.
  - Bottom line: delays happen to everyone. **With enough buffer, the delay doesn't reach the delivery date.**

---

# Part B. What we found, and why

## 4. Finding 2: Slower routes
*(2:55–3:50 · Presenter 2)*

| | |
|---|---|
| **Suggested title** | Same buffer, slower route: sea misses more |
| **Visual** | Grouped bar chart, sea vs air by buffer range + transit-time table. New graphic |
| **Transition** | Route is one part. Who is responsible along the way is another. |

- **[Data]** Overall, sea and air look the same: 10.8% vs 10.9% (the twist for poll option b).
  - Why: when promised dates were set, sea orders got **more time**. Median buffer: sea 132 days vs air 66. Share with 71+ days of buffer: sea 90% vs air 47%.
  - Analogy: give a hard class more study time and your grade may match the easy class. That doesn't make the two classes equally hard.
- **[Data]** **Compare lines with the same buffer**, and sea misses more.

  | Buffer | Sea | Air |
  |---|---|---|
  | Under 71 days | 26.8% | 14.6% |
  | 71 days or more | 9.0% | 6.7% |

- **Why sea is harder to predict**
  - **[Data]** It takes longer, and the trip time varies a lot (FCA lines, where the supplier hands goods to the program's carrier; time from pickup to delivery):

    | | Fastest 10% | Median | Slowest 10% | Took 30+ days longer than usual |
    |---|---|---|---|---|
    | Air | 5 days | 13 days | 40 days | 9% |
    | Sea | 45 days | 76 days | 135 days | 22% |

  - **[Source]** There are more steps along the way that can slip.
    - Ship schedules: worldwide, container ship schedule reliability fell from 78.0% in 2019 to 35.8% in 2021 (Sea-Intelligence; global figures, not our shipments).
    - Port congestion: the share of container ships sitting in port rose from 31.7% in 2019 to 35.7% in 2022, and congestion on the main routes spilled over to sub-Saharan Africa, causing late arrivals and container shortages. Sub-Saharan African ports were among the lowest-ranked in port performance (UNCTAD 2022).
    - Time in port: cargo stays about 20 days in sub-Saharan African ports versus about 4 days in large East Asian and European ports (Raballand 2012; general background only).

## 5. Finding 3: Where responsibility changes hands
*(3:50–4:30 · Presenter 2)*

| | |
|---|---|
| **Suggested title** | Every hand-off adds risk |
| **Visual** | Flow graphic: supplier → program → receiving country, showing who is responsible under FCA, DAP and DDP + bar chart of DDP vs FCA at the same buffer. New graphic |
| **Transition** | Where the order goes matters even more. |

- **Terms** **[Source]** (based on the International Chamber of Commerce's Incoterms 2020)

  | Term | Supplier is responsible for | After that |
  |---|---|---|
  | FCA | Handing the goods to the buyer's carrier | Transport and import clearance are on the buyer (the program) |
  | DAP | Transport to the destination | Import clearance and duties are on the buyer |
  | DDP | Transport to the destination + import clearance and duties | Nothing left; one party covers the whole trip |

- **Supplier → program** **[Data]**
  - Overall, the rates look alike: FCA 11.7%, DDP 11.8%, DAP 11.6%.
  - Why they look alike: for DDP lines, the gap between the supplier's ready date and the delivery date is 0 days at the median, so the buffer looks small on paper (median buffer DDP 7 days vs FCA 100). The supplier's promise seems to already include the trip.
  - **Compare lines with the same buffer**, and the supplier-delivers-all-the-way option misses less: under 71 days, DDP 12.2% vs FCA 19.8%; 71 days or more, 4.6% vs 8.0%.
  - In the logistic regression, with other factors the same, the odds versus FCA were 0.38 for DDP and 0.46 for DAP.
- **Program → receiving country** **[Data]**
  - When the receiving country handles import clearance (DAP), 12.5% missed; when the program handles it (DDP), 10.4%. With other factors the same, the odds were 1.48 times higher.
- Message: **the more points where responsibility changes hands, the more often orders missed.**
- **[Hypothesis]** Every hand-off means re-syncing paperwork, schedules and contacts. With a tight buffer, there's no time to sort that out. We didn't test whether this is the cause.

## 6. Finding 4: Where it's going
*(4:30–5:25 · Presenter 2)*

| | |
|---|---|
| **Suggested title** | Tanzania's delays start before the goods even leave |
| **Visual** | Miss rate by country (22.2% vs 2.6%) + bar chart of pickup wait (28 / 61 / 12 days). New graphic. Cite TMDA |
| **Transition** | And what we ship matters, too. |

- **[Data]** In Tanzania, **22.2%** of lines missed the window (290 of 1,309); in Ethiopia, **2.6%** (28 of 1,095). With other factors the same, the odds were 2.49 for Tanzania and 0.18 for Ethiopia (versus the "Other" country group).
- **[Data]** **It's not about the shipping mode.**
  - Most Tanzania lines also went by air (57%; Ethiopia 85%).
  - Air vs air: 20.1% vs 2.8%. Sea vs sea: 16.5% vs 1.3%.
  - Swap their mode mixes and the rates barely move: Tanzania 22.2% → 19.8%, Ethiopia 2.6% → 2.0%.
- **[Data]** The gap is in **how long goods waited to be picked up after they were ready**. After pickup, the trip times were similar.

  | Same product (lab reagents), air, FCA | Wait until pickup (median) |
  |---|---|
  | All countries | 28 days |
  | Tanzania | 61 days |
  | Ethiopia | 12 days |

- **[Source]** Tanzania Medicines and Medical Devices Authority (TMDA) official timelines (current rules, which may differ from 2017–2023; all are maximums):

  | Step | Official timeline |
  |---|---|
  | New registration of an imported medicine | Reviewed within 180 days of a complete application (plus up to 80 days to answer queries) |
  | Priority products (e.g., WHO-listed) | Within 90 days |
  | Import permit processing | Within 7 days |
  | When to apply for an import permit | At least 6 weeks before loading |
  | Prerequisite | The importer must register its premises first |

- **[Hypothesis]** If a permit runs late, goods may sit and wait instead of shipping, which would fit the long pickup waits. But **we couldn't confirm this is the cause.** Repeat orders of registered products don't need new registration, and other countries have similar regulators. The dataset's "reason codes" have no published meanings, so we couldn't use them.
- **[Data]** Tanzania's miss rate swung a lot from year to year (36% in 2017 → 9% in 2021 → 6% in 2022 → 25% in 2023). It may not be a fixed trait.
- **[Data]** Ethiopia had only 28 misses, too few to draw firm conclusions.

## 7. Finding 5: What's being shipped
*(5:25–6:05 · Presenter 2)*

| | |
|---|---|
| **Suggested title** | HIV drugs were among the most reliable shipments |
| **Visual** | Bar chart of the miss rate for the six products in the table on this slide. New graphic |
| **Transition** | What about paperwork? |

- **[Data]** The HIV drugs from our intro were actually **among the less likely to miss**.

  | Product | Missed the window | Supplier 1+ week late | Median buffer |
  |---|---|---|---|
  | Essential medicines | 7.4% | 48% | 113 days |
  | HIV drugs | 7.6% | 28% | 85 days |
  | Malaria drugs | 7.7% | 27% | 128 days |
  | Lab reagents | 12.9% | 44% | 17 days |
  | Medical supplies | 15.7% | 51% | 88 days |
  | Condoms | 16.4% | 22% | 110 days |

- **Why?**
  - **[Data]** HIV drug suppliers ran late less often (28% vs 44–51% for lab and medical supplies), and the buffer was longer (85 days vs 17 for lab reagents).
  - **[Data]** Shipping from a warehouse wasn't the reason (HIV drugs ordered directly 7.5% vs shipped from a warehouse 7.7%).
  - **[Source]** More than 200 HIV medicines have WHO quality approval, and large buyers like PEPFAR pool their purchases (Waning et al. 2010).
  - **[Source]** Lab reagents often need cold storage and have a short shelf life, so they take careful coordination from order to arrival (ASLM/PFSCM; written about genomic testing reagents).
  - **[Hypothesis]** So HIV drugs are easier for suppliers to have ready on time, while lab reagents are easier to delay. We didn't test this directly.

*Note: essential medicines had frequent supplier delays (48%) but only 7.4% missed. The long buffer (113 days) likely absorbed them, which fits Finding 1 **[Hypothesis]**.*

## 8. Finding 6: Paperwork wasn't the main cause
*(6:05–6:35 · Presenter 2)*

| | |
|---|---|
| **Suggested title** | Approval time wasn't the problem; slow order processing was a warning sign |
| **Visual** | Table or bar chart of the four processing-time ranges (miss rate and supplier delays). New graphic |
| **Transition** | So can all this actually help a planner? |

- **[Data]** USAID approval time had no link to missing the window (p = 0.60, the twist for poll option a). But it's usually just 1 day, so it barely varies.
- **[Data]** The time from approval to sending the order to the supplier did matter: every extra 30 days raised the odds by 8%.

  | Processing time | Missed the window | Supplier 1+ week late | No pre-arranged contract |
  |---|---|---|---|
  | 0–14 days | 9.6% | 28% | 18% |
  | 15–30 days | 9.1% | 35% | 32% |
  | 31–60 days | 12.3% | 45% | 37% |
  | Over 60 days | 14.7% | 48% | 34% |

- **[Hypothesis]** Orders that take a long time to send out may be the ones **without a pre-arranged supplier, or that are harder to source**. Those orders are also more likely to have suppliers who run late.
  - Evidence **[Data]**: as processing time grows, the share of late suppliers rises from 28% to 48%. Orders under a framework contract took 26 days to process at the median; orders without one took 35.
  - Longer processing also eats into the time left, but the model already accounts for days left separately, so that alone doesn't explain it. We didn't confirm the cause.

---

# Part C. What it means

## 9. How useful is the early warning?
*(6:35–7:30 · Presenter 3)*

| | |
|---|---|
| **Suggested title** | Check 30 orders, find half of the problems |
| **Visual** | Icon graphic of 100 orders (10 problems, 30 flagged, 5 problems among them) + table comparing the two models. Tree training-vs-test chart is `09_accuracy_chart.png` (appendix) |
| **Transition** | Why only half? |

**[Data]** We trained on 2017–2021 orders and tested on 4,604 lines from 2022–23 that the models had never seen.

1. Picture **100 orders** on your desk. About **10** will miss the window, but you don't know which ones.
2. The model hands you **about 30** that look risky. **About 5** of the problem orders are on that list.
3. Pick 30 at random and you'd find **only about 3**.

| Model | Share flagged | Share of misses caught | Flagged lines that really missed |
|---|---|---|---|
| Decision tree | 29.7% (1,369 lines) | 46.8% (223 of 476) | About 1 in 6 (16.3%) |
| Logistic regression (cutoff 11.55%) | 31.7% (1,458 lines) | 48.5% (231 of 476) | About 1 in 6 (15.8%) |

- Message: it's not a machine that gets every answer right. It's a **"check these first" list**.

## 10. Why only half, and what's next
*(7:30–8:20 · Presenter 3)*

| | |
|---|---|
| **Suggested title** | The other half went wrong after the order went out |
| **Visual** | Two highlighted numbers (54%, 70%) + checkpoint graphic (day the PO goes out → day the goods are ready, about 60 days still left). New graphic |
| **Transition** | So what would a planner do with this list? |

- **[Data]** Looking at the 253 misses the model didn't catch:
  - **54%** had plenty of buffer on order day. On paper, they looked safe (vs 28% of the misses the model caught).
  - **70%** had the supplier finish more than a week late after the order went out (out of the 206 with a recorded ready date). Nobody can see that on order day.
- **Next step: update the risk score as each step is completed**
  - **[Data]** Using the days left when the goods were actually ready gives an AUC of 0.657, higher than buffer time on order day alone (0.596). (Same lines; a single-variable comparison, not tested as a full model.)
  - **[Data]** Even at that point, there are still about 60 days (median) before the promised date, so there's still time to act. The later you look, the sharper the signal, but the less time you have.
  - **[Source]** Gali et al. (2025) also point to near-real-time prediction and a shift from reacting to anticipating as the way forward.
  - What it would take: data that records **what was known on each day**, not just the final dates. In our data, 63% of lines had their promised date changed along the way.

## 11. What it means for planners
*(8:20–9:10 · Presenter 3)*

| | |
|---|---|
| **Suggested title** | What a planner could do with the list |
| **Visual** | Checklist of five items. Add a small note: "effects not tested" |
| **Transition** | Before we close, a few limits. |

These are **suggestions; we haven't tested whether they work.**

1. Checking about 30% of orders finds about half of the problem orders.
2. If the buffer is shorter than a typical trip (from goods ready to delivery, about 49 days by air and 118 by sea; FCA lines), the plan is tight from day one.
3. For tight-buffer orders, confirm the supplier's ready date first.
4. When choosing shipping terms, keep in mind that at the same buffer, orders where the supplier delivers all the way missed less often.
5. Give high-risk countries like Tanzania an early heads-up (22.2% vs 11.4% overall).

## 12. Limits and close
*(9:10–10:00 · Presenter 3)*

| | |
|---|---|
| **Suggested title** | Where to look first, while there's still time |
| **Visual** | Three limits + small AUC table + closing line |
| **Transition** | (After the close) Thank you. We're happy to take questions. |

- These are **associations, not causes**.
- We **assumed these were already known on order day**: shipping mode, funding source, the supplier's and the destination's shipping terms, lines per order, and the supplier's promised ready date (assumed not to change afterward).
  - Even in the model without buffer time, country stayed in the top three for importance.
- **Performance dropped on the newer period.**
  - AUC = if you pick one line that missed and one that didn't, the chance the model gives the missed one a higher risk score (0.5 = coin flip, 1.0 = perfect).

    | Model | Years it learned from (2017–21) | New years (2022–23) |
    |---|---|---|
    | Decision tree | 0.79 | 0.65 |
    | Logistic regression | 0.72 | 0.63 |

  - Analogy: study only past exams and you'll ace those, but score lower on a new one. Two likely reasons: the models picked up some patterns that were just chance, and things changed over time. **[Data]** The buffer gap shrank from 2x in training (15.2% vs 7.4%) to 1.6x in the test period (12.8% vs 8.1%). → The models would need regular retraining.
- **Closing line**

> On the day an order goes out, every order on a planner's desk looks about the same. But using only what's known that day, about four months ahead, we could find half of the problem orders in a third of the list. We could also say why: tight buffers, slower routes and hand-offs, and a few harder destinations and products. This doesn't replace a planner's judgment. It shows them where to look first, while there's still time to act.

---

# Team guide (for script writers and slide makers)

## 1. Shared terms (so all three presenters say the same thing)

| Say this | Meaning | Avoid |
|---|---|---|
| order line | One product line within an order. Our unit of analysis | shipment (not our unit) |
| Not On Time / missed the delivery window | Outside 2 weeks early to 1 week late (includes too early) | late (only for the late-only check) |
| order day / the day the PO goes out | The day the purchase order goes to the supplier = prediction point | order date (confused with entry date) |
| promised date | Agreed delivery date | due date |
| buffer time | Days from the supplier's promised ready date to the promised date | slack (when speaking) |
| hand-off | A point where shipping responsibility changes hands (FCA, DAP, DDP) | - |
| odds ... when other factors are the same | Always add this condition for LR results | "2.5 times more likely" (odds aren't probabilities) |
| caught half of the misses / 1 in 6 flagged was a real miss | Plain-English recall and precision | accuracy on its own |

## 2. Slide-making guide

- Write each slide title as **one English sentence that states the takeaway** (see each slide's "Suggested title").
- Don't put anything marked **[Hypothesis]** on a slide as if it were fact. Say it out loud as "one possible reason."
- Slides that use outside sources (UNAIDS, Pasquet, Sea-Intelligence, UNCTAD, TMDA, etc.) get a small source line at the bottom.
- Existing figures (`share_for_team/output` folder):
  - `08_tree_plot.png` (tree), `08_cp_plot.png` (choosing tree size), `07_odds_ratios.png` (odds ratios), `09_accuracy_chart.png` (tree training vs test), `06_boxplots_before.png` / `06_boxplots_after.png` (box plots)
  - Jeremiah's LR accuracy files (`10_logistic_accuracy.csv`, `10_logistic_confusion_matrices.csv`) aren't on GitHub yet. They should be rerun and uploaded after the `order_type` change.
- For new figures, use the numbers in this outline's tables as they are (see each slide's "Visual").

---

# Appendix (for Q&A and to cover the grading items)

- Appendix A: Data cleaning and variable selection (below). Row cleaning, column cleaning and dimension reduction, box plots and pre-processing, on one or two slides
- Variable summary table (21 predictors: 11 numeric, 10 categorical)
- Time-based split (training 2017–2021: 23,346 lines / test 2022–23: 4,604 lines)
- Decision tree plot and interpretation (including why we used equal priors)
- Logistic regression coefficient table and significance (16 of 19 significant)
- Accuracy and confusion matrices (training and test), cutoff 50% vs 11.55% (at 50%, only 1 of 476 caught)
- Robustness checks: late-only outcome, model without buffer time
- Source list

## Appendix A. Data cleaning and variable selection (incl. Week 12 dimension reduction)

For Q&A questions like "How did you clean the data?" and "How did you choose your variables?"

### A-1. Rows: 39,681 → 27,950 [Data]

| Step | Removed | Remaining |
|---|---|---|
| Original data | - | 39,681 |
| No on-time result | 10 | 39,671 |
| Flagged for exclusion by the program | 25 | 39,646 |
| Replenishment orders (going to warehouses, not countries) | 1,678 | 37,968 |
| PO date after the actual delivery (date error) | 2,962 | 35,006 |
| Entered before October 2017 (start-up period; program restructured at the start of FY2018) | 6,450 | 28,556 |
| Clear errors (7 rules, e.g., dates in 2099) | 98 | 28,458 |
| Missing numeric predictor | 508 | 27,950 |

### A-2. Columns and variable selection (dimension reduction) [Data]

- **Why it mattered**: turning 10 categorical variables into dummy variables gives **42 columns** in the logistic regression. Too many unneeded variables can bury the real patterns in noise.
- **1) Domain knowledge**
  - 104 original columns → drop 28 duplicate date parts → 76 base variables → **21 predictors** (11 numeric, 10 categorical).
  - We left out information that only exists after the order goes out (actual dates, shipped quantity, etc.) and ID columns. 55 of the 76 weren't used, 27 of them because they're post-order information.
  - For error-prone data, we removed rows (A-1). The supplier's promised ready date, whose meaning wasn't fully documented, was checked with a model without buffer time.
- **2) Combining categories**: categories with fewer than 500 lines became "Other," and blanks became "Unknown."
- **3) Keep only one of two strongly related variables**
  - `entry_to_po` = `planned_lead` − `days_left_at_po` (exactly) → `planned_lead` left out of the LR.
  - log line value ≈ log quantity + log unit price (r = 0.99) → line value left out of the LR.
  - Among the remaining numeric LR variables, the highest correlation is |r| = 0.67.
  - **Recommended change:** **all** 2,952 distribution orders (shipped from a warehouse) have the supplier term "Unknown" (only 8 other lines do). The two are basically the same column, so dropping `order_type` from the LR keeps the test AUC at 0.627 and turns the distribution-order effect into one number, odds 0.585 (p = 0.007). Right now we get 0.10 and 5.53 pointing in opposite directions, which is hard to interpret.
- **4) Checking with the decision tree**
  - Seven variables the tree never used: ordered quantity, line value, USAID approval time, order type, TLP, funding source, destination shipping terms.
  - USAID approval time and TLP weren't significant in the LR either. The two methods agree, which supports Finding 6.
  - Extra check: rerunning the LR with only the variables the tree used gave a test AUC of 0.642 (vs 0.627) and caught 52.7% of misses (vs 48.5%), with similar key odds. But picking a model by its test score would mean peeking at the test data, so **we keep the main model** and show this only as a check.
- **5) Feature extraction: we looked at PCA but didn't use it**
  - Running PCA on the 11 numeric variables (after scaling) gives a last component with exactly zero variance. That confirms the exact relationship above (`entry_to_po`).
  - Capturing about 90% of the information takes 7–8 components (7 = 88.6%, 8 = 93.5%), so it barely reduces anything.
  - Each component mixes several variables, so we'd lose readable results like "30 more days of buffer lowers the odds by 16%." That doesn't fit an analysis where interpretation matters.

### A-3. Box plots and pre-processing [Data]

- We checked the numeric variables for outliers with box plots (`06_boxplots_before.png` / `06_boxplots_after.png`).
- We removed only the 98 clear errors, using 7 rules, and kept plausible extreme values (no trimming or capping).
- The four size variables (quantity, unit price, line value, lines per order) were heavily skewed, so the LR used log10(x + 1) versions of them.
- **For Q&A: why didn't you scale the data?** PCA and k-means rely on variance and distance, so units must match. Decision trees and logistic regression give the same results either way. We checked: after scaling, the tree's predictions were 100% identical, and the LR's predicted probabilities and z-values didn't change. To compare variables we used z-values and likelihood-ratio tests, which don't depend on units, and we explained effects in meaningful units like "per 30 days" and "per 10x."

---

# Sources

1. UNAIDS (2026). Global HIV & AIDS statistics fact sheet. https://www.unaids.org/en/resources/fact-sheet
2. Pasquet A, et al. (2010). Impact of drug stock-outs on death and retention to care among HIV-infected patients on cART in Abidjan, Côte d'Ivoire. PLoS ONE 5(10): e13414. https://dx.doi.org/10.1371/journal.pone.0013414
3. Gali, Molavi & Alavi (2025). Predicting healthcare supply chain delays with ML. Journal of International Technology and Information Management 34(1). (Checked against the PDF.)
4. Daneshgar et al. (2024). Organizational Resources Management Researches 14(3). (Checked against the PDF and its English translation.)
5. Sea-Intelligence (2022). Global Liner Performance report 2021-FY. https://sea-intelligence.com/122
6. UNCTAD (2022). Review of Maritime Transport 2022: Facts and figures on Africa. https://unctad.org/press-material/unctads-review-maritime-transport-2022-facts-and-figures-africa
7. Raballand G. (2012). Why does cargo spend weeks in African ports? World Bank blog. https://blogs.worldbank.org/en/africacan/why-does-cargo-spend-weeks-in-african-ports
8. ICC (2025). Using Incoterms to manage tariff risks (who handles export/import clearance and duties under FCA, DAP, DDP). https://iccwbo.org/wp-content/uploads/sites/3/2025/04/2025.04_Using_Incoterms_to-Manage_Tariff_Risks.pdf
9. International Trade Administration. Know your Incoterms. https://www.trade.gov/know-your-incoterms
10. TMDA. Procedures for market authorization. https://www.tmda.go.tz/pages/procedures-for-market-authorization
11. TMDA. Import and export control. https://www.tmda.go.tz/pages/import-and-export-control
12. Waning B, et al. (2010). Global strategies to reduce the price of antiretroviral medicines. Globalization and Health 6:9. https://pmc.ncbi.nlm.nih.gov/articles/PMC2883977
13. ASLM/PFSCM. Strengthening Africa's genomic surveillance: why supply chains must lead the conversation. https://pfscm.org/strengthening-africas-genomic-surveillance-why-supply-chains-must-lead-the-conversation/
