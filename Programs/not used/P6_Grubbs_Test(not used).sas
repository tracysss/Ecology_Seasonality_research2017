
/* This program is to detect outliers using Grubb's Test.        		 */
/*	 			(2015 Data)          									 */
/* Date: 09/06/2016       By : TS                                        */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname = us_ha1_1991;       * This dataset already has clearday flag;
%Let Begin_Year = '2000';
%Let End_Year = '2000';
%Let Year = '2000';
%let num_days = 220;
/************************************************/
TITLE1 "2015 Flux Daily Files : &dsname";
title2 "Year &Begin_Year to &End_Year";


/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';


/* store ODS output file in this directory */
ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\Grubbs_&dsname..pdf";

options MLOGIC SYMBOLGEN;


/********************************/
/* Fit WEIBULL to daily data 	*/
/*	separate spr & fall, 081008	*/
* fit SPRING GEP ;
%Let modelvar=GPP;
proc nlin data=flux2015.&dsname /*noprint*/ method=marquardt; by  yyyy; 
	where doy<&num_days;
	parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
	bounds y0>0; bounds 190>x0>130; bounds a1>0; 
	NUM=doy-x0+a2*log(2)**(1/a3);
	model GPP_NT_VUT_REF =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
	output out=flux2015.&dsname._1 parms=y0_&modelvar x0_&modelvar a1_&modelvar a2_&modelvar a3_&modelvar 
		predicted=pred_&modelvar  r=resid_&modelvar l95m=l95_&modelvar u95m=u95_&modelvar stdi=stdi_&modelvar;
	/*STDI specifies a variable that contains the standard error of the individual predicted value.
	  STDP specifies a variable that contains the standard error of the mean predicted value.
	  STDR specifies a variable that contains the standard error of the residual. */
	run;

/*prepare data for Gubbs' test: only take 1 year, first &num_days days */
data flux2015.&dsname._2;
	set flux2015.&dsname._1;
	gpp_ratio1 = GPP_NT_VUT_REF /pred_GPP ;
	gpp_ratio2 = pred_GPP / GPP_NT_VUT_REF ;
	where (yyyy = &Year) /*and GPP_NT_VUT_REF>=0*/; 	/* and (doy>=100 and doy<=265);*/
	keep yyyy doy GPP_NT_VUT_REF   pred_GPP gpp_ratio1  gpp_ratio2 ;
run;

/********** Start of Grubbs Test ***********/

/* get num_rows of testing dataset */
proc sql noprint;
   select count(*) into : nobs
   from flux2015.&dsname._2;
quit;
%put 'Obs in data set:' &nobs;

/* Calculate Critical Grubbs Values */
%macro grubbs_crit(alpha=0.5, num=, ds=);
	data &ds;
		t2=tinv(&alpha/(2*&num), &num -2);
		gcrit2 = ((&num -1) / sqrt(&num)) * sqrt(t2 * t2/(&num -2 + t2*t2));
		label gcrit2 = 'Critical (95%) Two-sided Grubbs Multiplier';
		n=&num;
	run;
%mend grubbs_crit;

%grubbs_crit(num=&nobs, ds=Grubbs_spring_test);

/* Calculate mean and sd */
proc means data=flux2015.&dsname._2;
	var gpp_ratio1 gpp_ratio2;
	output out=meanratio mean=mean_r1 mean_r2 stddev=sd1 sd2 ;
run;

/* merge mean and sd to main data */
data meanratio;
	set meanratio;
	yyyy = put(&Year, $4.);
	drop _TYPE_ _FREQ_;
run;
proc sql;
	create table flux2015.&dsname._3 as
	select * from 
		flux2015.&dsname._2 ds ,meanratio m
	where ds.yyyy = m.yyyy;
quit;

/* Calculate G */
data _null_;
	set Grubbs_spring_test;
	* Get Grubb's Test Critical Value from macro dataset;
	call symput("gcrit2",gcrit2);
run;
%put &gcrit2;
data flux2015.&dsname._3;
	set flux2015.&dsname._3;
	G1 = abs(gpp_ratio1 - mean_r1) / sd1;
	G2 = abs(gpp_ratio2 - mean_r2) / sd2;
	C = &gcrit2;
	Diff1 = G1 - C;
	Diff2 = G2 - C;
	if Diff1 >= 0 then Outlier1 = 1; else Outlier1 = 0;
	if Diff2 >= 0 then Outlier2 = 1; else Outlier2 = 0;
run;
/* How many outliers? */
proc freq data=flux2015.&dsname._3;
	table Outlier1 Outlier2;
run;

proc gplot data=flux2015.&dsname._3;
*by yyyy;
	*plot (GPP_NT_VUT_REF pred_GPP)*doy / overlay;
	plot gpp_ratio1 * doy=outlier1 /*vaxis=-5 to 5*/;
	plot gpp_ratio2 * doy=outlier2 /*vaxis=-5 to 5*/;
	plot GPP_NT_VUT_REF * doy=outlier1 /*vaxis=-5 to 5*/;
	plot GPP_NT_VUT_REF * doy=outlier2 /*vaxis=-5 to 5*/;
run;



/* close ODS */
ods pdf close;




/* 
proc univariate data=flux2015.&dsname._2 noprint;
	var gpp_ratio1;
	histogram gpp_ratio1/exp(fill l=3) cfill=red normal(noprint);
	output out=out_Gtest std=std mean=mn skewness=skw kurtosis=kurt;
run;

proc means data=flux2015.&dsname._2;
	var gpp_ratio1;
run; */
/* Robust regression proc 
proc robustreg data = flux2015.&dsname._2 method=MM; *Methods: LTS,M,MM,S;
	model gpp_ratio1=doy/ diagnostics(all);
	output out=diag_out r=resid sr=stres outlier=otlr leverage=lvr rho=r;

run; */
