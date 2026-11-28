# Part 3 Script (Slides 9–12) — Draft

## Slide 9 (6:35–7:30)

Thanks. So can this actually help a planner? Imagine you've got 100 order lines to review and about 10 of them will miss the delivery window. You have time to check only about 30. Where do you start?

We tested both models on about 4,600 lines from 2022 and 2023, after training on earlier orders. Both models flagged about a third of the lines and caught nearly half the misses. Think of it as finding about five of those ten problem lines. If you checked 30 at random, you'd expect to find about three.

Only about one in six flags turned out to be a real miss. That's why I'd use the score to decide what to check first. So what happened to the misses we didn't catch?

## Slide 10 (7:30–8:20)

We looked at the misses the decision tree didn't flag. Just over half had at least 71 days of buffer when the order went out. On paper, they had time. Among the ones with a recorded ready date, seven in ten had suppliers finish more than a week late.

That suggests a second checkpoint, when the goods are actually ready. In a quick check, the time left at that point ranked risk better than buffer time on order day alone. And even then, there were typically about 60 days left before the promised date. We'd need date histories to test a model that updates as orders move along.

## Slide 11 (8:20–9:10)

Say the model flags a sea order with 80 days between the supplier's promised ready date and the delivery date. For sea orders where the supplier hands the goods to the program's carrier, the typical time from ready to delivered was about 118 days. I'd call the supplier to confirm the ready date and check whether the carrier's schedule still fits.

I'd also check who handles customs. Each hand-off gives the planner a specific person to follow up with. We haven't tested whether these steps prevent delays, but they give a planner something concrete to do with the flag.

## Slide 12 (9:10–10:00)

There are two limits to keep in mind. We assumed fields like shipping mode and the supplier's promised ready date were available when the order went out. And both models were worse at ranking risk on later orders. For logistic regression, the chance of ranking a missed line above an on-time one fell from about 72% in training to 63% on the test set.

The patterns we found can help a planner decide where to look. We'd still need to test whether following up changes delivery outcomes. With about four months before the promised date on a typical order day, that early shortlist gives a planner time to ask questions.

Thank you. We're happy to take questions.

---

*Notes for slide prep and Q&A (not spoken):*

- Slide 9 uses the refreshed logistic regression. At the 11.55% cutoff it flagged 1,456 of 4,604 test lines (31.6%), caught 230 of 476 misses (48.3%), and had 15.8% precision. The decision tree flagged 1,369 lines (29.7%), caught 223 of 476 misses (46.8%), and had 16.3% precision.
- Slide 10's missed-case figures are for the decision tree. It missed 253 positive lines, and 206 of those had a recorded actual ready date. The checkpoint comparison used one variable at each point (AUC 0.657 vs. 0.596). A full model that updates over time remains to be tested.
- Keep the lecture cutoff in the appendix. At 50%, logistic regression had 88.3% training accuracy and 89.4% test accuracy, and caught 1 of 476 test misses. Always predicting on time was 89.7% accurate on test.
