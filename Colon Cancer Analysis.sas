/* Import dataset */
NOTE: Data not included in repository
proc import datafile="/home/USERID/cc_deid.xlsx"
out=cc_data
dbms=xlsx
replace;
getnames=yes;
run;
/* Data preparation: recoding variables */
data cc_data;
set cc_data;
/* Convert race into categories */
if race = 1 then race_cat = 1;
else if race = 2 then race_cat = 2;
else if race in (3, 4, 5, 6, 7, 8, 98, 99) then race_cat = 99;
else race_cat = .;
run;
/* Rescale median income to units of 10,000 */
data cc_data;
set cc_data;
medincome_10k = medincome / 10000;
run;
/* Calculate quartiles for ADI % */
proc univariate data=cc_data noprint;
var ADI_percent;
output out=ADI_quartiles
pctlpre=Q_
pctlpts= 25 50 75;
run;
/* Assign each ADI quartile */
data cc_data;
if _n_ = 1 then set ADI_quartiles;
set cc_data;
if ADI_percent <= Q_25 then ADI_quartile = 1;
else if ADI_percent <= Q_50 then ADI_quartile = 2;
else if ADI_percent <= Q_75 then ADI_quartile =3;
else ADI_quartile = 4;
run;
/* Create binary variable for highest deprivation quartile */
data cc_data;
set cc_data;
if ADI_quartile = 4 then ADI_q = 1; 
else if 1 <= ADI_quartile and ADI_quartile <= 3 then ADI_q = 0;
run; 
/* Create binary variable based on enrollment year */
data cc_data;
set cc_data;
if enroll_year <= 2008 then enroll_median = 0;
else if enroll_year > 2008 then enroll_median = 1;
run;
/* Generate summary statistics of enroll year */
ods rtf file="~/Enroll_Year_Stats_cc.rtf" style=journal;
proc means data=cc_data median min max q1 q3;
var enroll_year;
where case_status = 9;
run;
ods rtf close;
/* Patient flow chart by study */
ods rtf file="~/PtFlow_cc.rtf" style=journal;
data cc_data_flow;
set cc_data;
consent = (bio_consent = 2);
submitted = (specimen_submitted = 2);
included = (case_status = 9);
run;
proc summary data=cc_data_flow nway;
class study;
var consent submitted included;
output out=flow_table
n = Randomized
sum = Consent Submitted Included;
run;
proc print data=flow_table noobs;
run;
ods rtf close;
/* Descriptive statistics by biospecimen consent */
ods rtf file="~/Descriptive_Statistics_cc.rtf" style=journal;
/* Descriptive statistics for continuous variables */
proc means data=cc_data(where=(case_status=9)) 
n mean std min q1 median q3 max;
class bio_consent;
ways 0 1;
var age ADI_percent medincome;
run;
/* Two sample t-tests comparing biospecimen consent groups */
proc ttest data=cc_data;
where case_status = 9;
class bio_consent;
var age ADI_percent medincome;
run;
/* Frequency tables and chi-square tests for categorical variables */
proc freq data=cc_data(where=(case_status=9));
tables bio_consent*(gender race_cat study enroll_year) / chisq;
run;
ods rtf close;
/* Descriptive statistics by biospecimen submission */
ods rtf file="~/Descriptive_Stats_submit_cc.rtf" style=journal;
/* Descriptive statistics for continuous variables */
proc means data=cc_data(where=(case_status=9)) 
n mean std min q1 median q3 max;
class specimen_submitted;
ways 0 1;
var age ADI_percent medincome;
run;
/* Two sample t-tests comparing biospecimen submission groups */
proc ttest data=cc_data;
where case_status = 9;
class specimen_submitted;
var age ADI_percent medincome;
run;
/* Frequency tables and chi-square tests for categorical variables */
proc freq data=cc_data(where=(case_status=9));
tables specimen_submitted*(gender race_cat study enroll_year) / chisq;
run;
ods rtf close;
/* Compute Pearson correlation between ADI % and median income */
ods rtf file="~/Pearson_Corr_cc.rtf" style=journal;
proc corr data=cc_data pearson;
where case_status = 9;
var ADI_percent medincome;
title "Pearson Correlation Between ADI % and Median Income";
run;
ods rtf close;
/* Perform two sample t-tests comparing median income by ADI quartile group */
ods rtf file="~/TTest_MedIncome_ADIcat_cc.rtf" style=journal;
proc ttest data=cc_data;
where case_status = 9;
class ADI_q;
var medincome;
title “T-Test of Median Income by ADI Quartile”;
run;
ods rtf close;
/* Univariate logistic regression of biospecimen consent on key predictors */
ods rtf file="~/Logistic_Consent_UniL_cc.rtf" style=journal;
/* Race (category) */
proc logistic data=cc_data;
where case_status = 9;
class race_cat (ref='1') / param=ref;
model bio_consent(event='2') = race_cat;
run;
/* Gender */
proc logistic data=cc_data;
where case_status = 9;
class gender (ref='1') / param=ref;
model bio_consent(event='2') = gender;
run;
/* Age (continuous) */
proc logistic data=cc_data;
where case_status = 9;
model bio_consent(event='2') = age;
run;
/* ADI quartile (binary) */
proc logistic data=cc_data;
where case_status = 9;
class ADI_q (ref='0') / param=ref;
model bio_consent(event='2') = ADI_q;
run;
/* Median enrollment year (binary) */
proc logistic data=cc_data;
where case_status = 9;
model bio_consent(event='2') = enroll_median;
run;
/* Median income (continuous, scaled per $10000) */
proc logistic data=cc_data;
where case_status = 9;
model bio_consent(event='2') = medincome_10k;
units medincome_10k = 1;
run;
ods rtf close;
/* Univariate logistic regression of biospecimen submission on key predictors */
ods rtf file="~/Logistic_Submit_UniL_cc.rtf" style=journal;
/* Race (category) */
proc logistic data=cc_data;
where case_status = 9;
class race_cat (ref='1') / param=ref;
model specimen_submitted(event='2') = race_cat;
run;
/* Gender */
proc logistic data=cc_data;
where case_status = 9;
class gender (ref='1') / param=ref;
model specimen_submitted(event='2') = gender;
run;
/* Age (continuous) */
proc logistic data=cc_data;
where case_status = 9;
model specimen_submitted(event='2') = age;
run;
/* ADI quartile (binary) */
proc logistic data=cc_data;
where case_status = 9;
class ADI_q (ref='0') / param=ref;
model specimen_submitted(event='2') = ADI_q;
run;
/* Median enrollment year (binary) */
proc logistic data=cc_data;
where case_status = 9;
model specimen_submitted(event='2') = enroll_median;
run;
/* Median income (continuous, scaled per $10000) */
proc logistic data=cc_data;
where case_status = 9;
model specimen_submitted(event='2') = medincome_10k;
units medincome = 1;
run;
ods rtf close;
/* Multivariable logistic regression of biospecimen consent (ADI quartiles) 
-	Outcome: biospecimen consent (event ‘2’)
-	Predictors: race, gender, age, adi_q, enroll_median
-	Only include participants with case_status = 9
-	Reference groups specified for categorical variables
-	Odds ratios with Wald 95% confidence intervals */
ods rtf file="~/MultiL_ADIq_Consent_cc.rtf" style=journal;
proc logistic data=cc_data;
   where case_status = 9;
   class 
      race_cat (ref='1')
      gender   (ref='1')
      ADI_q    (ref='0')
      / param=ref;
   model bio_consent(event='2') =  
         race_cat 
         gender 
         age 
         ADI_q 
         enroll_median
/ clodds=wald;
run;
ods rtf close;
/* Multivariable logistic regression of biospecimen submission (ADI quartiles)
-	Same as before, just for submission */
ods rtf file="~/MultiL_ADIq_Submit_cc.rtf" style=journal;
proc logistic data=cc_data;
   where case_status = 9;
   class 
      race_cat (ref='1')
      gender   (ref='1')
      ADI_q    (ref='0')
      / param=ref;
   model specimen_submitted(event='2') =  
         race_cat 
         gender 
         age 
         ADI_q 
         enroll_median
/ clodds=wald;
run;
ods rtf close;
/* Multivariable logistic regression of biospecimen consent (median income)
-	Outcome: biospecimen consent (event ‘2’)
-	Predictors: race, gender, age, medincome, enroll_median
-	Only include participants with case_status = 9
-	Reference groups specified for categorical variables
-	Odds ratios with Wald 95% confidence intervals */
ods rtf file="~/MultiL_MedIncome_Consent_cc.rtf" style=journal;
proc logistic data=cc_data;
   where case_status = 9;
   class 
      race_cat (ref='1')
      gender   (ref='1')
      / param=ref;
   model bio_consent(event='2') =  
         race_cat 
         gender 
         age 
         medincome_10k 
         enroll_median
/ clodds=wald;
units medincome_10k = 1;
run;
ods rtf close;
/* Multivariable logistic regression of biospecimen submission (median income)
-	Same as before, just for submission */
ods rtf file="~/MultiL_MedIncome_Submit_cc.rtf" style=journal;
proc logistic data=cc_data;
   where case_status = 9;
   class 
      race_cat (ref='1')
      gender   (ref='1')
      / param=ref;
   model specimen_submitted(event='2') =  
         race_cat 
         gender 
         age 
         medincome_10k 
         enroll_median
/ clodds=wald; 
units medincome_10k = 1;
run;
ods rtf close;
