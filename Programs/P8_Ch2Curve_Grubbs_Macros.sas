
/* This program fits Chapter 2 curve. */
/* This program will run for all years that are in the dataset. */

/*	 			(2015 Data)         				 */
/* Date: 10/12/2016       By : TS                    */

/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */
* %Let dsname =us_wcr_1999;       

/* store output sas dataset files in this directory */
* LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015'; * input dataset folder(output dataset folder of P1A);
* LIBNAME fluxch2 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2'; * output dataset folder for ch2 model;

/**********************************************************************/


options MLOGIC SYMBOLGEN;

/*--------- Definition of Macros -----------------------*/
%macro default_parameters;

	/*take the row of default values for the variable in process: */
	data _null_;
		set work.nlin_default;

		call symput("y0",y0);
		call symput("a1",a1);
		call symput("a2",a2);
		call symput("b1",b1);
		call symput("b2",b2);
		call symput("t01",t02);
		call symput("t02",t02);
		call symput("c1",c1);
		call symput("c2",c2);	

		call symput("y0_lb",y0_lb);
		call symput("a1_lb",a1_lb);
		call symput("a2_lb",a2_lb);
		call symput("b1_lb",b1_lb);
		call symput("b2_lb",b2_lb);
		call symput("t01_lb",t02_lb);
		call symput("t02_lb",t02_lb);
		call symput("c1_lb",c1_lb);
		call symput("c2_lb",c2_lb);	

		call symput("y0_hb",y0_hb);
		call symput("a1_hb",a1_hb);
		call symput("a2_hb",a2_hb);
		call symput("b1_hb",b1_hb);
		call symput("b2_hb",b2_hb);
		call symput("t01_hb",t02_hb);
		call symput("t02_hb",t02_hb);
		call symput("c1_hb",c1_hb);
		call symput("c2_hb",c2_hb);	

		where var ="&modelvar";
	run;


%mend default_parameters;

%MACRO Curves_ch2(dsname=,modelvar=,model_col=,Year=,gi=);
	%put "Macro Curves_ch2 starts!: modelvar=" &modelvar;

	/* Default parameters are used in iteration 1. Parameters of last iteration are used in
		iteration 2 and after. */ 
	/* If we want to use default parameter values for all, remove the "if condition"
	   and run &default_parameters here for all iterations. */
	%if &gi = 1 %then
		%do;
			%default_parameters
		%end;

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
	ods output ParameterEstimates = work.parm;

	proc nlin data=work.&dsname._&modelvar._&Year._&gi /*noprint*/ method=marquardt NOHALVE; 
		by  yyyy; 
	%put "Proc nlin";
	%put "nlin data is" work.&dsname._&modelvar._&Year._&gi;

		
		/* parms y0=0.5 a1=4.0 a2=4.0 b1=10.0 b2=5.0 t01=50 t02=300 c1=1.0 c2=1.0;*/   /* lianhong; */ 

		parms y0=&y0 a1=&a1 a2=&a2 b1=&b1 b2=&b2 t01=&t01 t02=&t02 c1=&c1 c2=&c2;  

		bounds y0>=&y0_lb;  bounds y0<=&y0_hb; 
		bounds a1>=&a1_lb;  	bounds a1<=&a1_hb;
		bounds a2>=&a2_lb;	bounds a2<=&a2_hb;
		bounds b1>=&b1_lb;	bounds b1<=&b1_hb;
		bounds b2>=&b2_lb;	bounds b2<=&b2_hb;
		bounds t01>=&t01_lb; bounds t01<=&t01_hb;
		bounds t02>=&t02_lb; bounds t02<=&t02_hb;
		bounds c1>=&c1_lb;	bounds c1<=&c1_hb; 
		bounds c2>=&c2_lb;	bounds c2<=&c2_hb;

		/*
		bounds y0>=-5;  bounds y0<=15.0; 
		bounds a1>=0;  	bounds a1<=1000;
		bounds a2>=0;	bounds a2<=1000;
		bounds b1>=-5000;	bounds b1<=5000;
		bounds b2>=-5000;	bounds b2<=5000;
		bounds t01>=60; bounds t01<=200;
		bounds t02>=150; bounds t02<=366;
		bounds c1>=0.0;	bounds c1<=100; 
		bounds c2>=0.0;	bounds c2<=100; */

		model &model_col =y0+ (a1 / ((1+exp(-(doy-t01)/b1))**c1)) - a2 / ((1+exp(-(doy-t02)/b2))**c2);
		output out=work.&dsname._&modelvar._&Year._c_&gi
		parms=y0_&modelvar a1_&modelvar a2_&modelvar 
				b1_&modelvar  b2_&modelvar  t01_&modelvar  t02_&modelvar  c1_&modelvar c2_&modelvar
			predicted=pred_&modelvar  r=resid_&modelvar l95m=l95_&modelvar u95m=u95_&modelvar stdi=stdi_&modelvar;

		ods output ConvergenceStatus=work.status; * write PROC NLIN convergence status to dataset;

	run;
	ods listing;   * resume ODS printing;


	data work.&dsname._&modelvar._&Year._c_&gi;
		set work.&dsname._&modelvar._&Year._c_&gi;

		ratio1_&modelvar = &model_col /pred_&modelvar;

		keep yyyy doy timestamp &model_col  y0_&modelvar a1_&modelvar a2_&modelvar b1_&modelvar  b2_&modelvar 
			t01_&modelvar  t02_&modelvar  c1_&modelvar c2_&modelvar pred_&modelvar ratio1_&modelvar;
	run;
	proc sort data=work.&dsname._&modelvar._&Year._c_&gi out=work.&dsname._ch2_&Year._&gi nodupkey;
		by yyyy;
	run;
	
	proc sort data=work.&dsname._&modelvar._&Year._&gi;
		by yyyy doy;
	run;
	proc sort data=work.&dsname._&modelvar._&Year._c_&gi;
		by yyyy doy;
	run;
	data work.&dsname._&modelvar._&Year._&gi;
		merge work.&dsname._&modelvar._&Year._&gi
				work.&dsname._&modelvar._&Year._c_&gi;
		by yyyy doy;
	run;


		/* From Lianhong Gu

      b1=10.0d0
      beta(2)=b1
      betamin(2)=-10000.0d0
      betamax(2)=10000.0d0

      c1=1.0d0
      beta(3)=c1
      betamin(3)=0.0d0
      betamax(3)=20000.0d0

      x01=50.0d0           ---> use this for t1
      beta(4)=x01
      betamin(4)=0.0d0
      betamax(4)=366.0d0

      y0=0.5d0
      beta(5)=y0
      betamin(5)=-5.0d0
      betamax(5)=10.0d0

	  a1=4.0d0
      beta(1)=a1
      betamin(1)=0.0d0
      betamax(1)=15.0d0

      a2=4.0d0
      beta(6)=a2
      betamin(6)=0.0d0
      betamax(6)=15.0d0

      b2=5.0d0
      beta(7)=b2
      betamin(7)=-10000.0d0
      betamax(7)=10000.0d0

      c2=1.0d0                   ---> change the 2nd c1 to c2
      beta(8)=c2
      betamin(8)=0.0d0
      betamax(8)=20000.0d0

      x02=300.0d0  ---> use this for t2
      beta(9)=x02
      betamin(9)=0.0d0
      betamax(9)=366.0d0

		*/


	data work.parameters;
		set work.&dsname._&modelvar._&Year._c_&gi(rename=(y0_&modelvar=y0  a1_&modelvar=a1
			a2_&modelvar=a2 b1_&modelvar=b1  b2_&modelvar=b2 
			t01_&modelvar=t01  t02_&modelvar=t02  c1_&modelvar=c1 c2_&modelvar=c2 yyyy=Year));


		where y0 NE .;

		File_Name ="&dsname";
		Variable_Name="&modelvar";
		Col_Name="&model_col";
		iteration =&gi;

		keep Year File_Name Variable_Name Col_Name y0  a1 a2 b1 b2 t01 t02 c1 c2 iteration;
	run;

	/* set the Proc Nlin parameter values to the regression result from current iteration */
	data _null_;
		set work.parameters; 
		call symput("y0",y0);
		call symput("a1",a1);
		call symput("a2",a2);
		call symput("b1",b1);
		call symput("b2",b2);
		call symput("t01",t01);
		call symput("t02",t02);
		call symput("c1",c1);
		call symput("c2",c2);
	run;
	%put "from work.parameters:" &y0 &a1 &a2 &b1 &b2 &t01 &t02 &c1 &c2;

	/* merge convergence status to parameter data set */
	data work.parameters;
		merge work.parameters
				work.status (rename=(yyyy=year));
		by year;
	run;

	/* prepare the standard error dataset to merge in parameter dataset */
	data work.parm;
		set work.parm;
		rename yyyy=year;
		keep yyyy parameter stderr;
		if parameter in ('y0','a1','a2','b1','b2','c1','c2','t01','t02');
	run;

	proc sort data=work.parm;
		by year parameter;
	run;

	proc transpose data=work.parm out=work.parmse prefix=se;
    	by year ;
    	id parameter;
    	var StdErr;
	run;

	data work.parmse ;
		set work.parmse;
		drop _label_ _name_;
		rename sey0=y0_se sea1=a1_se sea2=a2_se seb1=b1_se seb2=b2_se
			 sec1=c1_se sec2=c2_se set01=t01_se set02=t02_se;
	run;

	proc sort data=work.parmse;
		by year;
	run;

	/* merge paramater standard errors to parameter data set */
	data work.parameters;
		merge work.parameters
				work.parmse;
		by year;
	run;

	/* remove empty lines in parameter dataset */
	proc sort data=work.parameters nodupkey;
		by File_Name year Variable_Name iteration;
	run;



%Mend CURVES_CH2; 
 

/* plot the data points (spring & fall) for 1 year */ 
%macro plot1year(y=, dsname=);
	%put "plot1year starts!";
	title3 "Year &y";
	proc gplot data=work.&dsname._&modelvar._&Year._b_&gi;
		plot pred_&modelvar	*doy    &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	%put "plot1year ends!";
	run;
%mend plot1year; 
/* plot the data points (spring & fall) for multiple years */ 
%macro plotmultiple(begin_y=, end_y=);
	%put "plotmultiple starts!";
	TITLE1 "2015 Flux Daily Files : &dsname.";
	title2 "&modelvar., &model_col";
	proc gplot data=work.&dsname._&modelvar._&Year._c_&gi;
		plot pred_&modelvar	*doy    &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy >= "&begin_y" and yyyy<="&end_y";
	run;
%mend plotmultiple; 

%MACRO plotbyyear(begin_y=, end_y=);
	%put "plotbyyear starts!";
	TITLE1 "2015 Flux Daily Files : &dsname.";
	title2 "&modelvar., &model_col";
	%DO y = &begin_y %TO &end_y;
		%plot1year(y=&y, dsname=&dsname);
	%END;
%MEND plotbyyear; /* End of %MACRO plotbyyear */




/* Calculate Critical Grubbs Values - both Spring and Fall */
/* This Macro will be called by Macro Grubbs               */
%macro grubbs_crit(alpha=0.5, num=,ds=);
	%put "Macro Grubbs_Crit starts";
	data &ds;
		t2=tinv(&alpha/(2*&num), &num -2);
		/*Critical (95%) Two-sided Grubbs Multiplier (Spring)*/
		gcrit2 = ((&num -1) / sqrt(&num)) * sqrt(t2 * t2/(&num -2 + t2 * t2));
		%let gcv=gcrit2;

	run;
		%put "Macro Grubbs_Crit ends";
%mend grubbs_crit;


/******************* Start of Grubbs Test **********************/
/* Grubb's Test will conclude when Numbers of Outliers(both */
/* Spring and Fall) are zeroes.                             */
%Macro Grubbs(dsname=,modelvar=,model_col=,Year=);
	%put "Macro Grubbs starts!";


%put "Macro Grubbs: modelvar, year=" &modelvar &Year;
/* Grubb's Test iteration - initialized to 1 */
%let gi=1;
%let noutlier=1;

/* initialize parameter values to default */
%default_parameters

/* Prepare data for the first time run of Curves */
	* prepare doy for spring and fall;
	data work.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname;
		where (yyyy = "&Year");
	run;

/**** Beginning of one iteration ***/
%do %until ((&noutlier=0) or &gi>15);
title2 "Variable: &modelvar., Year: &Year.,Grubb's Test Iteration &gi";

%put "**********New Grubb's Iteration Begins *************";
%put "Grubb's Test Iteration. gi=" &gi;
%put "Number of outliers from last iteration(noutlier):" &noutlier;

/* get num_rows of testing dataset */
proc sql noprint;
	select count(*) into : nobs
   from work.&dsname._&modelvar._&Year._&gi;

quit;

%put "Obs in data set:" &nobs;

title3 "Number of Obs: Total:&nobs";

/* fit curves */
%Curves_ch2(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year,gi=&gi)
* Curves QA - plot curves for this year;
/* %plot1year(y=&Year, dsname=&dsname) */

/* run Macro to calculate Grubb's critical value */
%grubbs_crit(num=&nobs, ds=Grubbs_test)

/* Calculate mean and sd */
proc means data=work.&dsname._&modelvar._&Year._&gi;
	var ratio1_&modelvar;
	output out=meanratio mean=mean_r  stddev=sd;
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

proc sql;
	create table work.&dsname._&modelvar._&Year._b_&gi as
	select * from 
		work.&dsname._&modelvar._&Year._b_&gi b ,
		work.&dsname._&modelvar._&Year._c_&gi c
	where c.timestamp = b.timestamp;
quit;

/* Calculate G */
data _null_;
	set Grubbs_test;
	/* Get Grubb's Test Critical Value from macro dataset*/
	call symput("gcrit2",gcrit2);

run;
%put &gcrit2;

/* identify outliers */
data work.&dsname._&modelvar._&Year._b_&gi;
	set work.&dsname._&modelvar._&Year._b_&gi;
	G = abs(ratio1_&modelvar - mean_r) / sd;
	C = &gcrit2;
	Diff = G - C;
	if Diff >= 0 then Outlier = 1; else Outlier = 0;
run;
/* How many outliers? */
proc freq data=work.&dsname._&modelvar._&Year._b_&gi;
	table Outlier /  out=outliercount;

run;
proc sql noprint;
	select count(*) into : noutlier
	from work.&dsname._&modelvar._&Year._b_&gi
	where Outlier = 1;
quit;
%put "Outliers in data set:" &noutlier;

data work.&dsname._&modelvar._&Year._b_&gi;
	set work.&dsname._&modelvar._&Year._b_&gi;
	if pred_&modelvar<=0 then pred_&modelvar=.;
run;

proc gplot data=work.&dsname._&modelvar._&Year._b_&gi;
 *	plot (&model_col /*pred__&modelvar*/)*doy / overlay;
	plot ratio1_&modelvar * doy=Outlier /*vaxis=-5 to 5*/;
	plot &model_col * doy=Outlier /*vaxis=-5 to 5*/;
	plot pred_&modelvar	*doy  &model_col * doy   / overlay haxis=axis1
                            legend=legend1;
run;

/* create a row in dataset for all parameters */
data work.parameters;
	set work.parameters;
	n_obs=&nobs;
	Outliers=&noutlier;

run;
proc sort data=work.parameters;
	by year Variable_Name Iteration;
run;
proc sort data=work.&dsname._parameters_ch2; 
	by year Variable_Name Iteration;
run;

data work.&dsname._parameters_ch2;
	merge work.&dsname._parameters_ch2
		work.parameters;
		by year Variable_Name Iteration;
run;
/* remove outliers */
%let gi_new=%SYSEVALF(&gi+1);

%put "creating new dataset:" &gi &gi_new;

data work.&dsname._&modelvar._&Year._b_&gi_new;
	set work.&dsname._&modelvar._&Year._b_&gi;
	where Outlier=0;
run;

proc sql;
	create table work.&dsname._&modelvar._&Year._b_&gi_new as
	select * from 
		work.&dsname._&modelvar._&Year._b_&gi_new ds ,meanratio m
	where ds.Outlier=0;
quit;

proc sql noprint;
	select count(*) into : nobs_new
	from work.&dsname._&modelvar._&Year._b_&gi_new;
quit;
%put "N_obs inthe new B data set:" &nobs_new;

proc sql noprint;
	select count(*) into : n_outlier_new
	from work.&dsname._&modelvar._&Year._b_&gi_new
	where Outlier=1;
quit;
%put "N_outliers inthe new B data set:" &n_outlier_new;

data work.&dsname._&modelvar._&Year._&gi_new;
	set  work.&dsname._&modelvar._&Year._b_&gi_new;
	keep yyyy doy timestamp &model_col pred_&modelvar;
run;

%put "**********End of iteration. gi=" &gi "*****";

%let gi=%SYSEVALF(&gi+1);

%end; /* end of Grubbs' test iteration */

	proc gplot data=work.&dsname._&modelvar._&Year._&gi_new;
		plot pred_&modelvar	*doy    &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;

%mend Grubbs; * end of Macro Grubbs;

* Macro for whole process for one variable;
%Macro Proc_var(dsname=,modelvar=,model_col=, begin_y=,end_y=);

	%put "Macro Proc_var starts!" &dsname &modelvar &model_col;

	/* %Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col)*/

	%let Year=%SYSEVALF(&begin_y);
	
	%put "Before loop: Year=" &Year;
	
	TITLE1 "2015 Flux Daily Files : &dsname.";

	%DO %UNTIL (&Year > &end_y);
		* Perform Grubbs Test;

		%grubbs(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year)
	
		* Move to the next year;
		%let Year=%SYSEVALF(&Year+1);
	%END; /* End of processing for this %Year*/



%MEND Proc_var;
