Group D – Project Proposal: Predicting Late Deliveries of Global Health Commodities (USAID GHSC-PSM)

(1) Dataset: USAID_GHSC-PSM_Health_Commodity_Delivery_Dataset.csv (attached; Wayback Machine snapshot of data.usaid.gov, June 11, 2024). It has 39,681 order lines to 96 countries (2016–2023). After cleaning, we analyze 27,950 lines entered from October 2017.

(2) Focal dependent variable: not_on_time (1 = delivered outside the program's official window of 14 days early to 7 days late versus the agreed date; 0 = otherwise). 11.4% of lines were not on time.

(3) Why it matters: Late deliveries of HIV, malaria and other health products can leave clinics without medicine. Stock-out-related treatment stops are linked to a higher risk of leaving care or death (Pasquet et al., 2010). From a business perspective, a risk score at purchase-order release, typically about four months (median 121 days) before the promised date, lets managers act early.

(4) Literature review

# | Paper | Key findings | Novel contribution of this project (vs. this paper)
1 | Gali et al. (2025), J. of Int'l Technology and Information Management, 34(1) | Adding country logistics scores (LPI) to GHSC-PSM data improves prediction; XGBoost reaches 86% accuracy, but recall for late shipments is only 0.52–0.60. | They use post-shipment variables and no stated prediction time. We predict at PO release using only information known then, apply the official on-time rule, and report recall for late orders.
2 | Daneshgar et al. (2024), Organizational Resources Management Researches, 14(3) | On older SCMS data (2006–2015), an SVM reaches a reported 95% accuracy; country, shipment mode, supplier and manufacturing site matter most. | Their test set appears to include synthetic late records. We use recent GHSC-PSM data and the official rule, and test on later orders at the real share of late orders.
3 | Gallien et al. (2017), Production and Operations Management, 26(6) | Unpredictable fund disbursements create significant stockout risk in most African countries. | That study estimates stockout risk at the national level. We give an order-level early warning for the procurement delays behind stockouts.

Overall novel contribution (one sentence):
Whereas prior studies do not state when predictions are made, use post-shipment information and overstate accuracy, this project predicts at purchase-order release whether each GHSC-PSM order line will miss the official on-time window, using interpretable models tested on later orders, so managers can act before stockouts occur.
