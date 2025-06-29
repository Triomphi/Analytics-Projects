## Predicting Patient 10 Year Risk of Coronary Heart Disease (CHD)

The primary objective of this project is to develop a predictive model to assess the 10-year risk of coronary heart disease (CHD) in individuals based on a combination of demographic, behavioral, and medical factors. The dataset comprises various patient attributes, including demographic details (age, sex), behavioral habits (smoking status, daily cigarette consumption), and medical history/current conditions (blood pressure, cholesterol, BMI, glucose levels, and prevalence of chronic conditions such as hypertension and diabetes).

Using logistic regression, the analysis aims to:

1. __Identify Key Risk Factors:__ Quantify the impact of different features (e.g., age, smoking, systolic blood pressure) on the likelihood of developing CHD.
2. __Predict Risk:__ Accurately classify individuals as high-risk or low-risk for CHD over a 10-year horizon.
3. __Provide Insights for Preventive Healthcare:__ Offer actionable insights that can assist healthcare providers and policymakers in targeting interventions and managing CHD risk in populations.

This project involves cleaning and exploring the dataset, selecting relevant features, fitting a logistic regression model, and evaluating its performance using appropriate metrics such as accuracy, precision, recall, and AUC-ROC. By the end of the analysis, the model will serve as a tool to aid in early identification of individuals at risk for CHD, potentially reducing the burden of heart disease through timely prevention and management.

### About the Dataset

The dataset is publicly available on [Kaggle](https://www.kaggle.com/datasets/christofel04/cardiovascular-study-dataset-predict-heart-disea/data?select=train.csv) and it is from an ongoing cardiovascular study on residents of the town of Framingham, Massachusetts.  The data contains 3390 records and the following features

1. **Sex:** male or female("M" or "F")
2. **Age:** Age of the patient;(Continuous - Although the recorded ages have been truncated to whole numbers, the concept of age is continuous)
3. **is_smoking:** whether or not the patient is a current smoker ("YES" or "NO")
4. **Cigs Per Day:** the number of cigarettes that the person smoked on average in one day.(can be considered continuous as one can have any number of cigarettes, even half a cigarette.)
5. **BP Meds:** whether or not the patient was on blood pressure medication (Nominal)
6. **Prevalent Stroke:** whether or not the patient had previously had a stroke (Nominal)
7. **Prevalent Hyp:** whether or not the patient was hypertensive (Nominal)
8. **Diabetes:** whether or not the patient had diabetes (Nominal)
9. **Tot Chol:** total cholesterol level (Continuous)
10. **Sys BP:** systolic blood pressure (Continuous)
11. **Dia BP:** diastolic blood pressure (Continuous)
12. **BMI:** Body Mass Index (Continuous)
13. **Heart Rate:** heart rate (Continuous - In medical research, variables such as heart rate though in fact discrete, yet are considered continuous because of large number of possible values.)
14. **Glucose:** glucose level (Continuous)
15. **10 year risk of coronary heart disease CHD** (binary: “1”, means “Yes”, “0” means “No”)
