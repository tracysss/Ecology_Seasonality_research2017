
/* This program is to fit data points to Fall curve.        		 */
/*	 			(2015 Data)          									 */
/* Date: 09/12/2016       By : TS                                        */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname = us_ha1_1991;       * This dataset already has clearday flag;
%Let Begin_Year = '2000';
%Let End_Year = '2000';
%Let Year = '2000';
%let spring_cutoff = 220;
%let fall_cutoff = 180;

/************************************************/
TITLE1 "2015 Flux Daily Files : &dsname";
title2 "Year &Begin_Year to &End_Year";


/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';


/* store ODS output file in this directory */
* ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\Grubbs_&dsname..pdf";

options MLOGIC SYMBOLGEN;


/********************************/
/* Fit WEIBULL to daily data 	*/
/*	separate spr & fall, 081008	*/

data work.&dsname;
	set flux2015.&dsname;

	if yyyy in ('1996','2000','2004','2008','2012','2016') then doyreverse = 366- doy + 1;
	else doyreverse = 365 - doy + 1;

	if doy < &spring_cutoff then Spring = 1; else Spring = 0;
	if doy > &fall_cutoff then Fall = 1; else Fall = 0;
run;

* fit SPRING GEP ;
%Let modelvar=GPP;
proc nlin data=work.&dsname noprint method=marquardt; by  yyyy; 
	where doy<&spring_cutoff;
	parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
	bounds y0>0; bounds 190>x0>130; bounds a1>0; 
	NUM=doy-x0+a2*log(2)**(1/a3);
	model GPP_NT_VUT_REF =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
	output out=flux2015.&dsname._1s parms=y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
		predicted=preds_&modelvar  r=resids_&modelvar l95m=l95s_&modelvar u95m=u95s_&modelvar stdi=stdis_&modelvar;
	/*STDI specifies a variable that contains the standard error of the individual predicted value.
	  STDP specifies a variable that contains the standard error of the mean predicted value.
	  STDR specifies a variable that contains the standard error of the residual. */
	run;

* fit FALL GEP ;
proc nlin data=work.&dsname noprint method=marquardt; by yyyy;
	where doy>&fall_cutoff /*and GPP_NT_VUT_REF>0*/ ;  /*??? */
	parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
	bounds y0>0; bounds 190>x0>90; bounds a1>0;
	NUM=doyreverse-x0+a2*log(2)**(1/a3);
	model GPP_NT_VUT_REF =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
	output out=flux2015.&dsname._1f parms=y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
		predicted=predf_&modelvar  r=residf_&modelvar l95m=l95f_&modelvar u95m=u95f_&modelvar stdi=stdif_&modelvar;
run;


%Let Year =2000;
title2 "Year &Year";
proc gplot data=flux2015.&dsname._1f;
	plot predf_&modelvar	*doy  GPP_NT_VUT_REF * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy = "&Year";
run;

/* merge Spring and Fall curves */
proc sort data=flux2015.&dsname._1s;
	by yyyy doy;
run;
proc sort data=flux2015.&dsname._1f;
	by yyyy doy;
run;
data flux2015.&dsname._1new;
	merge flux2015.&dsname._1s flux2015.&dsname._1f;
	by yyyy doy;
	keep yyyy doy GPP_NT_VUT_REF doyreverse Spring Fall 
	y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
	predf_&modelvar  residf_&modelvar l95f_&modelvar u95f_&modelvar stdif_&modelvar
	y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
	preds_&modelvar  resids_&modelvar l95s_&modelvar u95s_&modelvar stdis_&modelvar;
run;

/* plot the data points (spring & fall) for multiple years */ 
%macro plotmultiple(begin_y=, end_y=);
	title2 "Year &begin_y to &end_y";
	proc gplot data=flux2015.&dsname._1new;
		plot preds_&modelvar	*doy   predf_&modelvar*doy GPP_NT_VUT_REF * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy >= "&begin_y" and yyyy<="&end_y";
	run;
%mend;

%plotmultiple(begin_y=1992,end_y=2000);

/* plot the data points (spring & fall) for 1 year */ 
%macro plot1year(y=);
	title2 "Year &y";
	proc gplot data=flux2015.&dsname._1new;
		plot preds_&modelvar	*doy   predf_&modelvar*doy GPP_NT_VUT_REF * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;
%mend;
%plot1year(y=1992);


%MACRO plotbyyear(begin_y=, end_y=);
%DO y = &begin_y %TO &end_y;
	%plot1year(y=&y);
%END;
%MEND plotbyyear;
%plotbyyear(begin_y=2000,end_y=2005);


%let Year =2000;
/*prepare data for Gubbs' test: only take 1 year, both Spring and Fall */
data flux2015.&dsname._2_&Year;
	set flux2015.&dsname._1new;
	ratio1f_&modelvar = GPP_NT_VUT_REF /predf_&modelvar;
	ratio1s_&modelvar = GPP_NT_VUT_REF /preds_&modelvar;
	where (yyyy = "&Year") /*and GPP_NT_VUT_REF>=0*/; 	/* and (doy>=100 and doy<=265);*/
	keep yyyy doy GPP_NT_VUT_REF   preds_&modelvar ratio1s_&modelvar predf_&modelvar ratio1f_&modelvar Spring Fall;
run;

/******************* Start of Grubbs Test **********************/


/* get num_rows of testing dataset */
proc sql noprint;
	select count(*) into : nobs_s
	from flux2015.&dsname._2_&Year
	where Spring = 1;

   select count(*) into : nobs_f
   from flux2015.&dsname._2_&Year
	where Fall = 1;
quit;
%put "Obs (Spring) in data set:" &nobs_s;
%put "Obs (Fall) in data set:" &nobs_f;

%put "Grubb's Test Iteration:" &iteration;

/* Calculate Critical Grubbs Values - both Spring and Fall*/
%macro grubbs_crit(alpha=0.5, num_s=, num_f=,ds=);
	data &ds;
		t2_s=tinv(&alpha/(2*&num_s), &num_s -2);
		gcrit2_s = ((&num_s -1) / sqrt(&num_s)) * sqrt(t2_s * t2_s/(&num_s -2 + t2_s * t2_s));
		label gcrit2_s = 'Critical (95%) Two-sided Grubbs Multiplier (Spring)';
		/*nobs_s=&num_s;*/

		t2_f=tinv(&alpha/(2*&num_f), &num_f -2);
		gcrit2_f = ((&num_f -1) / sqrt(&num_f)) * sqrt(t2_f * t2_f/(&num_f -2 + t2_f * t2_f));
		label gcrit2_f = 'Critical (95%) Two-sided Grubbs Multiplier (Fall)';
		/*nobs_s=&num_s;*/
	run;
%mend grubbs_crit;

%grubbs_crit(num_s=&nobs_s, num_f=&nobs_f, ds=Grubbs_test);
%put &gcrit2_s;
%put &gcrit2_f;

/* Calculate mean and sd */
proc means data=flux2015.&dsname._2_&Year;
	var ratio1s_&modelvar ratio1f_&modelvar;
	output out=meanratio mean=mean_r_s mean_r_f stddev=sds sdf ;
run;

/* merge mean and sd to main data */
data meanratio;
	set meanratio;
	yyyy = put(&Year, $4.);
	drop _TYPE_ _FREQ_;
run;
proc sql;
	create table flux2015.&dsname._3_&Year_&gi as
	select * from 
		flux2015.&dsname._2_&Year ds ,meanratio m
	where ds.yyyy = m.yyyy;
quit;

/* Calculate G */
data _null_;
	set Grubbs_test;
	* Get Grubb's Test Critical Value from macro dataset;
	call symput("gcrit2_s",gcrit2_s);
	call symput("gcrit2_f",gcrit2_f);
run;
%put &gcrit2_s;
%put &gcrit2_f;

data flux2015.&dsname._3_&Year_&gi;
	set flux2015.&dsname._3_&Year_&gi;
	G_s = abs(ratio1s_&modelvar - mean_r_s) / sds;
	G_f = abs(ratio1f_&modelvar - mean_r_f) / sdf;
	C_s = &gcrit2_s;
	C_f = &gcrit2_f;
	Diff_s = G_s - C_s;
	Diff_f = G_f - C_f;
	if Diff_s >= 0 then Outlier_s = 1; else Outlier_s = 0;
	if Diff_f >= 0 then Outlier_f = 1; else Outlier_f = 0;
run;
/* How many outliers? */
proc freq data=flux2015.&dsname._3_&Year_&gi;
	table Outlier_s /  out=outliercount_s;
	table Outlier_f /  out=outliercount_f;
	/*table Outlier_s Outlier_f; */
run;

proc sql noprint;
	select count(*) into : noutlier_s
	from flux2015.&dsname._3_&Year_&gi
	where Outlier_s = 1;

   select count(*) into : noutlier_f
   from flux2015.&dsname._3_&Year_&gi
	where Outlier_f = 1;;
quit;
%put 'Obs (Spring) in data set:' &noutlier_s;
%put 'Obs (Fall) in data set:' &noutlier_f;


proc gplot data=flux2015.&dsname._3_&Year_&gi;
*by yyyy;
	*plot (GPP_NT_VUT_REF pred_GPP)*doy / overlay;
	plot ratio1s_&modelvar * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot ratio1f_&modelvar * doy=Outlier_f /*vaxis=-5 to 5*/;
	plot GPP_NT_VUT_REF * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot GPP_NT_VUT_REF * doy=Outlier_f /*vaxis=-5 to 5*/;
run;


quit;




/* close ODS */
* ods pdf close;
