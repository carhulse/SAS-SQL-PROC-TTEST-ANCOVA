Data faos;
Set '/folders/myfolders/STAT466/Assignment 4/faos.sas7bdat';
Run;

Data baseline;
Set '/folders/myfolders/STAT466/Assignment 4/baseline.sas7bdat';
Run;


/*Question 1*/
*(a) Count the total number of patients with at least one row in the FAOS table. ;
PROC SQL;
title "1a: Total Number of Patients";
select count(distinct Patient_id) as N_patients From faos;
Quit;

*(b) Confirm that there are no patients in the FAOS table without an entry in the BASELINE table.;
Proc SQL;
Title "1b: Patients Without Baseline Entries";
Select Distinct PATIENT_ID From faos Where Not Exists (Select PATIENT_ID From baseline);
Quit;

*The output is blank, so all patients have entries in the baseline table; 

*(c) Produce the treatment group by month summary table.;
Proc SQL;
Title "1c: Summary Statistics";

Footnote "SQL is an excellent tool for identifying data errors.
Incorrect dates are perhaps the most common data errors";

Select TreatmentGroup  label = "Treatment Group",
month label = "Month",
count(FAOS) label = "N FAOS",
mean(FAOS) format = 8.1 label = "Mean FAOS",
Min(FAOS) format = 8.1 label = "Min FAOS",
Max(FAOS) format = 8.1 label = "Max FAOS"
From faos
Group By TreatmentGroup, month
Order By month, TreatmentGroup;
Quit;

*(d) List the Patient_ID, Triage_DT, Assessment_DT and Month for every
row in the FAOS table where an Assessment_DT is less than the Triage_DT for a given patient;
Proc SQL;
Title "1d: Patient Assessment Date less (earlier) than Triage Date";

Select Distinct A.Patient_ID, Assessment_DT, Triage_DT , Month From faos A, baseline B
Where A.Patient_ID=B.Patient_ID And Triage_DT >  Assessment_DT  
Order By A.Patient_ID;
Quit;

*(e) Count of the number of patients who have an inconsistency in the order of their Month
and Assessment_DT variables in the FAOS table;
Proc SQL;
Title "1e: Number of Patients with Inconsistencies in Month and Assessment Dates";

Select count(Distinct old.Patient_ID) As Patients
From faos old , faos new
Where old.Patient_ID = new.Patient_ID And old.month < new.month And old.Assessment_DT > new.Assessment_DT
;
Quit;

*(f) Now use the query you just created in part 1e as a subquery ...;
Proc SQL;
Title "1f: Patients with Date Inconsistencies";

Select  Patient_ID , Assessment_DT, month From faos
Where Patient_ID
In (Select old.Patient_ID  From faos old , faos new
Where old.Patient_ID = new.Patient_ID And old.month < new.month And old.Assessment_DT > new.Assessment_DT)
Order By Patient_ID, Assessment_DT;
Quit;

Run;


/*Question 2*/;

*(a);
Data new_faos0;
Set '/folders/myfolders/STAT466/Assignment 4/faos.sas7bdat';
Where Month <> 1 And Month <> 3 And Month <>6;
Drop Assessment_DT Month;
If Month = 0 Then FAO0 = FAOS;
Run;

Data new_faos6;
Set '/folders/myfolders/STAT466/Assignment 4/faos.sas7bdat';
Where Month <> 1 And Month <> 3 And Month <>0;
Drop Assessment_DT Month;
If Month = 6 Then FAO6 = FAOS;
Run;

Data change;
Set new_faos0;
Set new_faos6;
   fao_change = FAO6 - FAO0;
Drop FAOS;
Run;

Proc Print Data= change;
Run;

*(b);
Ods Graphics On;

Proc Corr Data = change Pearson Spearman
Plots = matrix(Histogram);
Var FAO0 FAO6 fao_change;
Run;
Ods Graphics Off;

*(c);
Proc Sort data= change;
by TreatmentGroup;
Run;

Proc ttest Data= change;
By TreatmentGroup;
Var FAO6 fao_change;
Run;


*(d) Based on the output from the PROC TTEST, provide evidence to support/refute 
the assumptions of approximate normality and equal variance for both the 6-month FAOS and the 6-month change in FAOS.;

/*The results from the TTEST suggest that the assumptions of approximate normality and equal variance
are false for the 6-month FAOS since it's distribution is skewed to the right and is too narrow and tall
to match the normal distribution.
However, the TTEST of the 6-month change in FAOS suggests that assumptions of approximate normality and equal variance
are true! The distribution plot fits the normal distribution Quite well. Moreover, since it's width is very similar,
this means that the varaince is close to equal to the variance of the normal.*/

*(e);
Title '2e: Nonparametric Wilcoxon Rank-Sum Test';
PROC NPAR1WAY  Wilcoxon Data = change;
Class TreatmentGroup;
Var FAO6 fao_change;
Run;

*The two-sided pvalues for the
	6-month FAOS = 0.0728
	Change in FAOS = 0.0915;

 
*(f);
Proc GLM data = change;
Class TreatmentGroup;
MODEL FAO6 = FAO0 TreatmentGroup / Solution;
Quit;
Run;

*Mean adjusted difference of the FAOS between groups  = 14.7175467-0.0000 = 14.7(?)

Corresponding two-sided p-value = 

Has physiotherapy appeared to have improved or worsened recovery?;

/*I'm not sure how to read the results for between groups! Will have to check out posted solutions*/ 


*(g);
Proc Sort data= change;
by Patient_ID;
Run;

Data merged;
merge change baseline;
by Patient_ID;
Run;

Proc GLM Data= merged Alpha=0.5;
Class TreatmentGroup sex hospital;
Model FAO6 = FAO0 TreatmentGroup weight age sex hospital / Solution;
Quit;
Run;
/*Which of the variables appear to be significantly associated with recovery at alpha=0.05?
/*RECALL: If the p-value is less than or equal to the alpha (p< .05), then we reject the null hypothesis, and
we say the result is statistically significant.*/
/*A small significance probability, Pr > F, indicates that some linear function of the parameters is significantly different from zero.*/ 
	
	*For normal sum of squares, or 'Type I SS',
	Treatment group, weight, and age are significantly associated with alpha = 0.5.

	*For adjusted, or type 'Type III SS',
	 Treatment group and age are significantly associated with alpha = 0.5.;

*(h);
Proc GLM Data= merged Alpha=0.5;
Class TreatmentGroup sex hospital;
Model FAO6 = FAO0 TreatmentGroup weight age sex hospital age*treatmentgroup / Solution;
Quit;
Run;

*p-value for the interaction term = 0.8625
*This is a very large p-value, thus indicating weak evidence against the null hypothesis that there is
no relationship between treatment effect and age. Hence there is not much evidence that the treatment effect may vary by
age;

