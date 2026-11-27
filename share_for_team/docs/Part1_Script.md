# Part 1 Script (Slides 1–3) — Final draft

## Slide 1 (0:00–0:45)

Good afternoon, everyone.

In 2025, about 570,000 people died of AIDS-related illness. About six in ten of them lived in sub-Saharan Africa. That's also where almost nine in ten of the order lines in our data went.

People with HIV take medicine every day to keep the virus under control, so clinics need a steady supply. A study in Abidjan, Côte d'Ivoire, looked at patients whose treatment stopped because the clinic ran out of drugs. They were almost three times as likely to drop out of care or die as patients whose treatment didn't stop.

So if drugs arrive late and a clinic runs out, patients are the ones who pay for it.

## Slide 2 (0:45–2:05, poll included)

We used public delivery data from USAID's GHSC-PSM program: almost 28,000 order lines from late 2017 to 2023. An order line is one product on one order. If a country orders HIV drugs and test kits together, that's two lines. About one in nine lines missed the delivery window, which runs from two weeks early to one week late.

When an order goes to the supplier, there are usually about four months left before the promised date. We call that day "order day." Our question: on order day, can we already tell which lines will miss?

Two recent studies on USAID data like ours mixed order-day information with things you only learn after the goods ship, like freight cost or the quantity shipped. So their models can't run on order day. We wanted to flag risky orders that early, so we used only what's known on order day.

Quick poll. On order day, what's the strongest warning sign?
A, USAID approval took a long time.
B, it's going by sea.
C, there's very little buffer time.
D, which country it's going to.

*[Hands up for each option. About 10 seconds.]*

## Slide 3 (2:05–3:15)

*[React to the vote, e.g., "Looks like a lot of you went with A or B."]*

The answer is C, and D is a close second.

Buffer time is the gap between the date the supplier says the goods will be ready and the date they're due to arrive. With fewer than about 71 days of buffer, around 15 in 100 lines missed. With more, about 7 in 100, so roughly half. The 71 days came from the decision tree's first split, not from us.

In both our models, the decision tree and a logistic regression, the top two signals were buffer time and the destination country.

Why does buffer matter this much? Suppliers were more than a week late about as often either way: 41 versus 36 out of 100. But when the supplier was late, 24 in 100 short-buffer lines missed, compared with 13 in 100 long-buffer lines. A long buffer gives the shipment time to catch up.

We'll come back to A and B later. How much buffer you need also depends on how the goods travel, and *[name]* will take it from here.
