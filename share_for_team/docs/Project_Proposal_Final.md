# Group D – Project Proposal

> Before submitting: attach the CSV file.

---

## (1) Upload your team's csv data

**USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv**
Source: USAID Global Health Supply Chain Program – Procurement and Supply Management (GHSC-PSM), published on data.usaid.gov as "USAID GHSC-PSM Health Commodity Delivery Dataset" (dataset ID tikn-bfy4). The original download is no longer available, so we retrieved the CSV from an Internet Archive (Wayback Machine) snapshot captured on June 11, 2024:
https://web.archive.org/web/20240611172315/https://data.usaid.gov/api/views/tikn-bfy4/rows.csv?accessType=DOWNLOAD

- 39,681 order lines × 104 columns
- 18,198 orders, 4,592 products, 96 recipient countries
- Orders entered from January 2016 to September 2023
- Each row is one order line. It records what was ordered, when each approval and purchase-order step happened, how the order was shipped, and when it was delivered compared with the promised date.

---

## (2) Indicate your focal dependent variable to analyze

**Focal dependent variable: whether an order line was Not On Time (1) or On Time (0)**

- **On Time (0):** delivered between 14 days early and 7 days late versus the agreed delivery date. This is the program's official on-time rule (GHSC-PSM, FY2018 Annual Report). The dataset's `On Time (OTD)` column follows this rule in 97.9% of rows when we check it against the dates.
- **Not On Time (1):** delivered outside that window, either more than 7 days late or more than 14 days early.
- **Robustness check:** we will also run the models with a late-only outcome (1 = more than 7 days late).
- **Prediction point:** we predict when the purchase order is released to the supplier, a median of 98 days after order entry. We use only information available by then.
- **Analytic sample: 27,950 order lines, of which 11.4% are Not On Time.**
  - We use orders entered from October 2017 onward. The program restructured its global supply chain team and processes at the start of FY2018, and on-time delivery then improved steadily (GHSC-PSM, FY2018 Annual Report). Earlier orders (6,450 lines) were Not On Time 56.7% of the time and reflect that earlier period.
  - We also leave out:
    - lines the program excluded from its own on-time counts;
    - replenishment orders to regional warehouses;
    - lines whose purchase-order date is recorded after delivery;
    - 606 lines with impossible or missing values.

---

## (3) Describe why your analytics are important

These order lines carry HIV, malaria, family planning, and maternal and child health products to low- and middle-income countries. GHSC-PSM buys and delivers these products for U.S. health programs such as PEPFAR, the U.S. President's Emergency Plan for AIDS Relief (GHSC-PSM, FY2018 Annual Report). When a delivery misses its window, a clinic can run out of medicine.

The harm to patients is documented. In an HIV cohort in Côte d'Ivoire, patients who had to stop treatment because of drug stock-outs were more likely to drop out of care or die (adjusted HR 2.83; Pasquet et al., 2010). Procurement delays are also cited as one of the causes of medicine stockouts in Africa (Gallien et al., 2017).

**From a business perspective,** the program tracks on-time delivery against a quarterly target of 80% and has built a "Not-On-Time Delivery" tool for root-cause analysis (GHSC-PSM, FY2018 Annual Report). Gallien et al. (2017) describe the Global Fund as working in a reactive "fire-fighting" environment when countries face an existing or imminent stockout. Our analytics aim to move this from reacting to acting early. When a purchase order is released, a manager still has a median of 121 days, about four months, before the promised date. A risk score at that moment shows which order lines need attention, so the manager can:

- follow up with the supplier;
- switch the transport mode;
- use regional warehouse stock;
- warn the recipient country early.

---

## (4) Conduct a literature review to emphasize the novel contribution of your project

| # | Paper | Key findings | Novel contribution of this project (vs. this paper) |
|---|---|---|---|
| 1 | Gali, Molavi, & Alavi (2025), *Journal of International Technology and Information Management*, 34(1), Article 3 | Merges GHSC-PSM shipment data with the World Bank Logistics Performance Index (LPI). Models trained on the merged data outperform models trained on shipment data alone, and XGBoost reaches the highest accuracy (86%). However, recall for the delayed class is only 0.52–0.60, so 40–48% of late shipments are missed. | **Prediction timing:** the paper does not state when the prediction is made, and it uses shipment-stage variables such as shipped quantity and number of shipments. We fix the prediction point at purchase-order release and use only information available then. **Outcome:** the paper describes its on-time outcome in two different ways. We apply the program's official rule and check it against the data. **Evaluation:** we report recall for Not On Time lines, not just accuracy. **Models:** we use interpretable Decision Tree and Logistic Regression models. |
| 2 | Daneshgar, Rajabzadeh Ghatari, & Afshar Kazemi (2024), *Organizational Resources Management Researches*, 14(3), 45–72 (in Persian) | Uses the SCMS dataset from an earlier USAID program (about 10,300 shipments, 2006–2015). Reports 95% accuracy for an SVM tuned with Bayesian optimization, and 93% for a decision tree. Destination country, shipment mode, supplier, and manufacturing site are the most influential features. | **Data:** we use the more recent GHSC-PSM data (orders entered 2017–2023). **Outcome:** the paper labels a shipment late if it arrives after the "scheduled" delivery date. We use the program's official −14/+7 day window around the agreed date. **Evaluation:** the paper describes oversampling (SMOTE) of the training data. However, its test set grew from 1,519 to 2,625 shipments and went from 12.6% to about 50% late, which suggests synthetic records entered the test set. Its own confusion matrix also gives 93.1% accuracy, not 95%. We keep the test data at its real share of late lines, apply any resampling only to training data, and train on earlier orders and test on later ones. |
| 3 | Gallien, Rashkova, Atun, & Yadav (2017), *Production and Operations Management*, 26(6), 997–1014 | Builds a discrete-event simulation from Global Fund disbursement and procurement data (2002–2013). Finds significant built-in stockout risks in most African countries, driven by unpredictable fund disbursements and the frequency of grant performance monitoring. Product category and region are among the main factors affecting procurement lead times. | That study estimates national stockout risk from funding and procurement processes, using simulation. We work at the level of individual order lines and use the program's own records to flag, early, the deliveries likely to miss their window. These are the procurement delays that feed into stockouts. |

**Overall novel contribution (one sentence):**
Whereas prior studies of healthcare delivery delays do not state when the prediction is made, use variables known only after shipment, use on-time definitions that differ from the program's official standard, and report accuracy that overstates their ability to catch late shipments, this project predicts whether a GHSC-PSM order line will miss the program's official on-time window at the moment the purchase order is released. It uses only information available at that point and interpretable Decision Tree and Logistic Regression models, tests on later orders kept at their real share of late lines, and gives managers an early warning while there is still time to act.

---

## References

- Daneshgar, F., Rajabzadeh Ghatari, A., & Afshar Kazemi, M. A. (2024). A framework for predicting the delivery status of healthcare commodities and data-driven healthcare supply chain management based on support vector machine and Bayesian optimization: A case study of the U.S. Agency for International Development's global healthcare supply chain. *Organizational Resources Management Researches, 14*(3), 45–72. [In Persian; English title from the translation we used. Tables checked against the original.]
- Gali, J. S., Molavi, N., & Alavi, S. (2025). Predicting global healthcare supply chain delays: A machine learning approach leveraging country-level logistics metrics. *Journal of International Technology and Information Management, 34*(1), Article 3. https://doi.org/10.58729/1941-6679.1634
- Gallien, J., Rashkova, I., Atun, R., & Yadav, P. (2017). National drug stockout risks and the Global Fund disbursement process for procurement. *Production and Operations Management, 26*(6), 997–1014. https://doi.org/10.1111/poms.12662
- GHSC-PSM. *Fiscal Year 2018 Annual Report (October 1, 2017 – September 30, 2018).* USAID Global Health Supply Chain Program – Procurement and Supply Management. https://www.ghsupplychain.org/sites/default/files/2019-07/GHSC-PSM_Qtrly_Report_FY18_Q4_FINAL.pdf
- Pasquet, A., Messou, E., Gabillard, D., Minga, A., Depoulosky, A., et al. (2010). Impact of drug stock-outs on death and retention to care among HIV-infected patients on combination antiretroviral therapy in Abidjan, Côte d'Ivoire. *PLoS ONE, 5*(10), e13414. https://doi.org/10.1371/journal.pone.0013414
