
/* 1. fit Spring & Fall curves.                 		 */
/* 2. Apply Grubb's Test to remove outliers  			 */
/* This program apply the same process to all variables. */
/* This program will run for all years that are in the dataset. */

/*	 			(2015 Data)         				 */
/* Date: 09/19/2016       By : TS                    */

/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */

* %Let dsname =us_ha1_1991;       

* %let spring_cutoff = 220;
* %let fall_cutoff = 180;


/* store output sas dataset files in this directory */
* LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015'; * input dataset folder(output dataset folder of P1A);
* LIBNAME fluxch3 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3'; * output dataset folder for ch3 model;

/* store ODS output file in this directory */
* ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\Curves&Grubbs_&dsname..pdf";


/**********************************************************************/


options MLOGIC SYMBOLGEN;

/*--------- Definition of Macros -----------------------*/

%MACRO Curves(dsname=,modelvar=,model_col=,Year=,gi=);
	%put "Macro Curves: modelvar=" &modelvar;

	data work.&dsname._&modelvar._&Year._&gi;
		set work.&dsname._&modelvar._&Year._&gi;

		if yyyy in ('1992','1996','2000','2004','2008','2012','2016') then doyreverse = 366- doy + 1;
		else doyreverse = 365 - doy + 1;

		if doy <= &spring_cutoff then Spring = 1; else Spring = 0;
		if doy >= &fall_cutoff then Fall = 1; else Fall = 0;

		where (yyyy = "&Year");
	run;


	/* Fit WEIBULL to daily data 	*/
	* fit SPRING GEP (or other variables);

	/* steps to write PROC NLIN convergence status to a data set:
		(1) remove noprint option in PROC NLIN;
		(2) close ODS before PROC NLIN;
		(3) add ODS OUTPUT statement;
		(4) after PROC NLIN, open ODS again;
	*/

	/* steps to write PROC NLIN parm standard error into a data set:
		(1) Turn ODS graphisc off before PROC NLIN;
		(2) add "ods output ParameterEstimates = parm" before PROC NLIN;
		(3) add variables (e.g. &model_var) into the dataset;
	*/
	ods listing close; * close ODS to print PROC NLIN convergence status to dataset;
	
	ods graphics off;

	ods output ParameterEstimates = work.parm_s;
	proc nlin data=work.&dsname._&modelvar._&Year._&gi /*noprint*/ method=marquardt; by  yyyy; 
		where doy<&spring_cutoff;
		parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
		bounds y0>0; bounds 190>x0>130; bounds a1>0; 
		NUM=doy-x0+a2*log(2)**(1/a3);
		model &model_col =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
		output out=work.&dsname._1s parms=y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
			predicted=preds_&modelvar  r=resids_&modelvar l95m=l95s_&modelvar u95m=u95s_&modelvar stdi=stdis_&modelvar;

		ods output ConvergenceStatus=work.status_s; * write PROC NLIN convergence status to dataset;

		/*STDI specifies a variable that contains the standard error of the individual predicted value.
		  STDP specifies a variable that contains the standard error of the mean predicted value.
		  STDR specifies a variable that contains the standard error of the residual. */
	run;
	
	* fit FALL GEP (or other variables);
	ods output ParameterEstimates = work.parm_f;
	proc nlin data=work.&dsname._&modelvar._&Year._&gi /*noprint*/ method=marquardt; by yyyy;
		where doy>&fall_cutoff /*and &model_col>0*/ ;  /*??? */
		parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
		bounds y0>0; bounds 190>x0>90; bounds a1>0;
		NUM=doyreverse-x0+a2*log(2)**(1/a3);
		model &model_col =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
		output out=work.&dsname._1f parms=y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
			predicted=predf_&modelvar  r=residf_&modelvar l95m=l95f_&modelvar u95m=u95f_&modelvar stdi=stdif_&modelvar;

		ods output ConvergenceStatus=work.status_f; * write PROC NLIN convergence status to dataset;
	run;

	ods listing;   * resume ODS printing;

	/* merge Spring and Fall curves */
	proc sort data=work.&dsname._1s;
		by yyyy doy;
	run;
	proc sort data=work.&dsname._1f;
		by yyyy doy;
	run;	
	data work.&dsname._&modelvar._&Year._c_&gi;
		merge work.&dsname._1s work.&dsname._1f;
		by yyyy doy;
		keep yyyy doy &model_col doyreverse Spring Fall 
		y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
		predf_&modelvar  residf_&modelvar l95f_&modelvar u95f_&modelvar stdif_&modelvar
		y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
		preds_&modelvar  resids_&modelvar l95s_&modelvar u95s_&modelvar stdis_&modelvar;
	run;

	/*prepare data for Gubbs' test: only take 1 year, both Spring and Fall */
	data work.&dsname._&modelvar._&Year._&gi;
		set work.&dsname._&modelvar._&Year._c_&gi;
		ratio1f_&modelvar = &model_col /predf_&modelvar;
		ratio1s_&modelvar = &model_col /preds_&modelvar;
		keep yyyy doy &model_col   preds_&modelvar ratio1s_&modelvar predf_&modelvar ratio1f_&modelvar Spring Fall;
	run;


	data work.parameters;
		set work.&dsname._&modelvar._&Year._c_&gi(rename=(y0s_&modelvar=y0_s  x0s_&modelvar=x0_s a1s_&modelvar=a1_s
			a2s_&modelvar=a2_s a3s_&modelvar=a3_s y0f_&modelvar=y0_f x0f_&modelvar=x0_f a1f_&modelvar=a1_f 
			a2f_&modelvar=a2_f a3f_&modelvar=a3_f yyyy=year));

		where y0_s NE . and y0_f NE .;

		File_Name ="&dsname";
		Variable_Name="&modelvar";
		Col_Name="&model_col";
		iteration =&gi;

		keep year File_Name Variable_Name Col_Name y0_s  x0_s a1_s a2_s a3_s y0_f x0_f a1_f a2_f a3_f iteration;
	run;

	/* merge convergence status to parameter data set */
	data work.parameters;
		merge work.parameters
				work.status_s (rename=(yyyy=year status=status_s reason=reason_s))
				work.status_f (rename=(yyyy=year status=status_f reason=reason_f));
		by year;
	run;

	/* prepare the 2 standard error datasets to merge in parameter dataset */
	data work.parm_spring;
		set work.parm_s;
		rename yyyy=year;
		keep yyyy parameter stderr;
		if parameter in ('y0','x0','a1','a2','a3');
	run;

	proc sort data=work.parm_spring;
		by year parameter;
	run;

	proc transpose data=work.parm_spring out=work.parmse_s prefix=se;
    	by year ;
    	id parameter;
    	var StdErr;
	run;

	data work.parmse_s ;
		set work.parmse_s;
		drop _label_ _name_;
		rename sea1=a1s_se sea2=a2s_se sea3=a3s_se sex0=x0s_se sey0=y0s_se;
	run;

	proc sort data=work.parmse_s;
		by year;
	run;

	data work.parm_fall;
		set work.parm_f;
		rename yyyy=year;
		keep yyyy parameter stderr;
		if parameter in ('y0','x0','a1','a2','a3');
	run;

	proc sort data=work.parm_fall;
		by year parameter;
	run;

	proc transpose data=work.parm_fall out=work.parmse_f prefix=se;
    	by year ;
    	id parameter;
    	var StdErr;
	run;

	data work.parmse_f ;
		set work.parmse_f;
		drop _label_ _name_;
		rename sea1=a1f_se sea2=a2f_se sea3=a3f_se sex0=x0f_se sey0=y0f_se;
	run;

	proc sort data=work.parmse_f;
		by year;
	run;

	/* merge paramater standard errors to parameter data set */
	data work.parameters;
		merge work.parameters
				work.parmse_s
				work.parmse_f;
		by year;
	run;

	/* remove empty lines in parameter dataset */
	proc sort data=work.parameters nodupkey;
		by year Variable_Name iteration;
	run;

%Mend Curves; 
 


/* plot the data points (spring & fall) for 1 year */ 
%macro plot1year(y=, ds=);
	proc gplot data=&ds;
		plot preds_&modelvar	*doy   predf_&modelvar*doy &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;
%mend plot1year; 

 

%Macro curves_qa(dsname=,modelvar=,model_col=,Year=);
	title2 "Year &Year";
	
	title3 "Spring";
	proc gplot data=work.&dsname._1s;
	plot predf_&modelvar	*doy  &model_col * doy  / overlay haxis=axis1
                          legend=legend1;
	where yyyy = "&Year";

	title3 "Fall";
	pr oc gplot data=work.&dsname._1f;
		plot predf_&modelvar	*doy  &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
		where yyyy = "&Year";
	run;
%mend curves_qa; 

/* plot the data points (spring & fall) for multiple years */ 
%macro plotmultiple(begin_y=, end_y=);
	title2 "Year &begin_y to &end_y";
	proc gplot data=work.&dsname._&modelvar;
		plot preds_&modelvar	*doy   predf_&modelvar*doy &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy >= "&begin_y" and yyyy<="&end_y";
	run;
%mend plotmultiple; 

%MACRO plotbyyear(begin_y=, end_y=);
	%DO y = &begin_y %TO &end_y;
		%plot1year(y=&y);
	%END;
%MEND plotbyyear; /* End of %MACRO plotbyyear */
*%plotbyyear(begin_y=2000,end_y=2005);




/* Calculate Critical Grubbs Values - both Spring and Fall */
/* This Macro will be called by Macro Grubbs               */
%macro grubbs_crit(alpha=0.5, num_s=, num_f=,ds=);
	data &ds;
		t2_s=tinv(&alpha/(2*&num_s), &num_s -2);
		/*Critical (95%) Two-sided Grubbs Multiplier (Spring)*/
		gcrit2_s = ((&num_s -1) / sqrt(&num_s)) * sqrt(t2_s * t2_s/(&num_s -2 + t2_s * t2_s));
		%let gcv_s=gcrit2_s;

		/*nobs_s=&num_s;*/

		t2_f=tinv(&alpha/(2*&num_f), &num_f -2);
		/* Critical (95%) Two-sided Grubbs Multiplier (Fall)*/
		gcrit2_f = ((&num_f -1) / sqrt(&num_f)) * sqrt(t2_f * t2_f/(&num_f -2 + t2_f * t2_f));
		%let gcv_f=gcrit2_f;

		/*nobs_s=&num_s;*/
	run;
%mend grubbs_crit;


/******************* Start of Grubbs Test **********************/
/* Grubb's Test will conclude when Numbers of Outliers(both */
/* Spring and Fall) are zeroes.                             */
%Macro Grubbs(dsname=,modelvar=,model_col=,Year=);

%put "Macro Grubbs: modelvar, year=" &modelvar &Year;
/* Grubb's Test iteration - initialized to 1 */
%let gi=1;
%let noutlier_s=1;
%let noutlier_f=1;

/* Prepare data for the first time run of Curves */
	* prepare doy for spring and fall;
	data work.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname;

		if yyyy in ('1992','1996','2000','2004','2008','2012','2016') then doyreverse = 366- doy + 1;
		else doyreverse = 365 - doy + 1;

		if doy <= &spring_cutoff then Spring = 1; else Spring = 0;
		if doy >= &fall_cutoff then Fall = 1; else Fall = 0;

		where (yyyy = "&Year");
	run;

/*prepare data for Gubbs' test: only take 1 year, both Spring and Fall */
/*data work.&dsname._&modelvar._&Year._&gi;
	set work.&dsname._&modelvar._&Year._&gi;
	ratio1f_&modelvar = &model_col /predf_&modelvar;
	ratio1s_&modelvar = &model_col /preds_&modelvar;
	keep yyyy doy &model_col   preds_&modelvar ratio1s_&modelvar predf_&modelvar ratio1f_&modelvar Spring Fall;
run;
*/

/**** Beginning of one iteration ***/
%do %until ((&noutlier_s=0 and &noutlier_f=0) or &gi>30);
title2 "Variable: &modelvar., Year: &Year.,Grubb's Test Iteration &gi";

%put "**********New Grubb's Iteration Begins *************";
%put "Grubb's Test Iteration. gi=" &gi;
%put "Number of outliers from last iteration(noutlier_s,noutlier_f):" &noutlier_s &noutlier_f;

/* get num_rows of testing dataset */
proc sql noprint;
	select count(*) into : nobs_s
	from work.&dsname._&modelvar._&Year._&gi
	where Spring = 1;

   select count(*) into : nobs_f
   from work.&dsname._&modelvar._&Year._&gi
	where Fall = 1;

	select count(*) into : nobs
   from work.&dsname._&modelvar._&Year._&gi;

quit;
%put "Obs (Spring) in data set:" &nobs_s;
%put "Obs (Fall) in data set:" &nobs_f;
%put "Obs (Spring&Fall) in data set:" &nobs;

title3 "Number of Obs: Spring:&nobs_s., Fall:&nobs_f., Total:&nobs";

/* fit curves */
%Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year,gi=&gi)
* Curves QA - plot curves for this year;
%plot1year(y=&Year, ds=work.&dsname._&modelvar._&Year._&gi)

/* run Macro to calculate Grubb's critical value */
%grubbs_crit(num_s=&nobs_s, num_f=&nobs_f, ds=Grubbs_test)

/* Calculate mean and sd */
proc means data=work.&dsname._&modelvar._&Year._&gi;
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
	create table work.&dsname._&modelvar._&Year._b_&gi as
	select * from 
		work.&dsname._&modelvar._&Year._&gi ds ,meanratio m
	where ds.yyyy = m.yyyy;
quit;

/* Calculate G */
data _null_;
	set Grubbs_test;
	/* Get Grubb's Test Critical Value from macro dataset*/
	call symput("gcrit2_s",gcrit2_s);
	call symput("gcrit2_f",gcrit2_f);
run;
%put &gcrit2_s;
%put &gcrit2_f;
/* identify outliers */
data work.&dsname._&modelvar._&Year._b_&gi;
	set work.&dsname._&modelvar._&Year._b_&gi;
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
proc freq data=work.&dsname._&modelvar._&Year._b_&gi;
	table Outlier_s /  out=outliercount_s;
	table Outlier_f /  out=outliercount_f;
	/*table Outlier_s Outlier_f; */
run;
proc sql noprint;
	select count(*) into : noutlier_s
	from work.&dsname._&modelvar._&Year._b_&gi
	where Outlier_s = 1;

   select count(*) into : noutlier_f
   from work.&dsname._&modelvar._&Year._b_&gi
	where Outlier_f = 1;
quit;
%put "Outliers (Spring) in data set:" &noutlier_s;
%put "Outliers (Fall) in data set:" &noutlier_f;


proc gplot data=work.&dsname._&modelvar._&Year._b_&gi;
 	plot (&model_col /*pred__&modelvar*/)*doy / overlay;
	plot ratio1s_&modelvar * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot ratio1f_&modelvar * doy=Outlier_f /*vaxis=-5 to 5*/;
	plot &model_col * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot &model_col * doy=Outlier_f /*vaxis=-5 to 5*/;
run;

/* create a row in dataset for all parameters */
data work.parameters;
	set work.parameters;

	n_obs_s=&nobs_s;
	n_obs_f=&nobs_f;
	n_obs=&nobs;
	Outliers_s=&noutlier_s;
	Outliers_f=&noutlier_f;

run;
proc sort data=work.parameters;
	by year Variable_Name Iteration;
run;
proc sort data=work.&dsname._para_all;
	by year Variable_Name Iteration;
run;

data work.&dsname._para_all;
	merge work.&dsname._para_all
		work.parameters;
		by year Variable_Name Iteration;
run;
/* remove outliers */
%let gi_new=%SYSEVALF(&gi+1);

%put "creating new dataset:" &gi &gi_new;

proc sql;
	create table work.&dsname._&modelvar._&Year._b_&gi_new as
	select * from 
		work.&dsname._&modelvar._&Year._b_&gi ds ,meanratio m
	where ds.Outlier_s=0 and ds.Outlier_f=0;
quit;
data work.&dsname._&modelvar._&Year._&gi_new;
	set work.&dsname._&modelvar._&Year._b_&gi_new;
	keep &model_col yyyy doy Spring Fall preds_&modelvar
		predf_&modelvar ratio1s_&modelvar ratio1f_&modelvar;
run;


%put "**********End of iteration. gi=" &gi "*****";

%let gi=%SYSEVALF(&gi+1);

%end; /* end of Grubbs' test iteration */

	proc gplot data=work.&dsname._&modelvar._&Year._&gi_new;
		plot preds_&modelvar	*doy   predf_&modelvar*doy &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;

%mend Grubbs; * end of Macro Grubbs;

* Macro for whole process for one variable;
%Macro Proc_var(dsname=,modelvar=,model_col=, begin_y=,end_y=);
	* fit both Spring and Fall curves for this variable (all years);
	%put "Macro Proc_var" &dsname &modelvar &model_col;

	/* %Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col)*/

	%let Year=%SYSEVALF(&begin_y);
	
	%put "Before loop: Year=" &Year;

	%DO %UNTIL (&Year > &end_y);
		* Perform Grubbs Test;

		%grubbs(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year)
	
		* Move to the next year;
		%let Year=%SYSEVALF(&Year+1);
	%END; /* End of processing for this %Year*/

%MEND Proc_var;

/********************** MAIN PROGRAM ****************************/
TITLE1 "2015 Flux Daily Files : &dsname.";


/* find the first and last year in dataset */
proc sort data=flux2015.&dsname out=work.&dsname;
	by yyyy;
run;
data _null_;
	set work.&dsname nobs=obscount;
	by yyyy;
	length begin_y 8. end_y 8.;
	if _n_ = 1 then do;
		begin_y = input(yyyy,8.);
		call symput("Begin_Year",begin_y);
	end;

	if _n_ = obscount then do;
		end_y = input(yyyy,8.);
		call symput("End_Year",end_y);
	end;
run;
%put "Range of years in data:" &Begin_Year &End_Year;

/* 
This is for debugging:

%let Begin_Year=2005;
%let End_Year=2005; 

If not specified, this program will go through all years in the data set. */

/* Create a temporary dataset to store all variable names */
/* We can also import a file that has variable names. */
data work.variables;
	 INFILE DATALINES DLM=','; 
		input var  $ col $20.;
	datalines;
GPP,GPP_NT_VUT_REF
RE,RECO_NT_VUT_REF
PPFD,PPFD_IN
H,H_CORR
LE,LE_CORR
NEE,NEE_VUT_REF
;
run;

/* create a dataset for all parameters */
data work.&dsname._para_all;
	length 	File_Name 	$30.
			Year 		$4.
			Variable_Name 	$10.
			Col_Name	$20.
			Iteration	8.
			y0_s	8.
			x0_s	8.
			a1_s	8.
			a2_s	8.
			a3_s	8.
			y0_f	8.
			x0_f	8.
			a1_f	8.
			a2_f	8.
			a3_f	8.
			Outliers_s	8.
			Outliers_f 	8.
			n_obs_s		8.
			n_obs_f		8.
			n_obs		8.
			status_s	8.
			reason_s	$200.
			status_f	8.
			reason_f	$200.;
run;

* create Macro lists for variables;
proc sql noprint;
 select var, col
 into :varlist separated by ' ',
 :collist separated by ' '
 from work.variables;
 quit;
%let cntlist = &sqlobs; * Get a count of number of variables;
%put &varlist; 
%put &collist; 
%put &cntlist;

* This macro loops all Variables to process one by one;
%macro vars;
	%do i=1 %to &cntlist;
		%let modelvar=%scan(&varlist,&i,' ');
		%let model_col=%scan(&collist,&i,' ');
		%put "Now Processing Variable: " &modelvar &model_col;
		* The main Macro that process on Variable level;
		%Proc_var(dsname=&dsname,modelvar=&modelvar,model_col=&model_col, begin_y=&Begin_Year,end_y=&End_Year)
	%end;
%mend;
%vars


quit;

/* remove empty lines in parameters data set */
data fluxch3.&dsname._parameters_ch3;
	set work.&dsname._para_all;
	where File_Name NE "";
run;


/********************* END OF PROGRAM ***************************/
/* close ODS */
ods pdf close;
