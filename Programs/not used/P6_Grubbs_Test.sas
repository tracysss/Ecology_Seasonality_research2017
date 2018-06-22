/* This program is apply Grubb's Test.        		 */
/*	 			(2015 Data)         				 */
/* Date: 09/14/2016       By : TS                    */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname = us_ha1_1991;       * This dataset already has clearday flag;
%let Year =2000;
%Let modelvar=PPFD;
%Let model_col=PPFD_IN;
%let spring_cutoff = 220;
%let fall_cutoff = 180;
/************************************************/
TITLE1 "2015 Flux Daily Files : &dsname., Year: &Year";


/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';


/* store ODS output file in this directory */
* ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\Grubbs_&dsname._&Year..pdf";

options MLOGIC SYMBOLGEN;


/*--------- Definition of Macros -----------------------*/

%MACRO Curves(dsname=,modelvar=,model_col=,Year=,gi=);
	%put "Macro Curves: modelvar=" &modelvar;

	data flux2015.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname._&modelvar._&Year._&gi;

		if yyyy in ('1992','1996','2000','2004','2008','2012','2016') then doyreverse = 366- doy + 1;
		else doyreverse = 365 - doy + 1;

		if doy <= &spring_cutoff then Spring = 1; else Spring = 0;
		if doy >= &fall_cutoff then Fall = 1; else Fall = 0;

		where (yyyy = "&Year");
	run;


	/* Fit WEIBULL to daily data 	*/
	* fit SPRING GEP (or other variables);
	proc nlin data=flux2015.&dsname._&modelvar._&Year._&gi noprint method=marquardt; by  yyyy; 
		where doy<&spring_cutoff;
		parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
		bounds y0>0; bounds 190>x0>130; bounds a1>0; 
		NUM=doy-x0+a2*log(2)**(1/a3);
		model &model_col =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
		output out=work.&dsname._1s parms=y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
			predicted=preds_&modelvar  r=resids_&modelvar l95m=l95s_&modelvar u95m=u95s_&modelvar stdi=stdis_&modelvar;
		/*STDI specifies a variable that contains the standard error of the individual predicted value.
		  STDP specifies a variable that contains the standard error of the mean predicted value.
		  STDR specifies a variable that contains the standard error of the residual. */
		run;
	
	* fit FALL GEP (or other variables);
	proc nlin data=flux2015.&dsname._&modelvar._&Year._&gi noprint method=marquardt; by yyyy;
		where doy>&fall_cutoff /*and &model_col>0*/ ;  /*??? */
		parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
		bounds y0>0; bounds 190>x0>90; bounds a1>0;
		NUM=doyreverse-x0+a2*log(2)**(1/a3);
		model &model_col =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
		output out=work.&dsname._1f parms=y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
			predicted=predf_&modelvar  r=residf_&modelvar l95m=l95f_&modelvar u95m=u95f_&modelvar stdi=stdif_&modelvar;
	run;
	/* merge Spring and Fall curves */
	proc sort data=work.&dsname._1s;
		by yyyy doy;
	run;
	proc sort data=work.&dsname._1f;
		by yyyy doy;
	run;	
	data flux2015.&dsname._&modelvar._&Year._c_&gi;
		merge work.&dsname._1s work.&dsname._1f;
		by yyyy doy;
		keep yyyy doy &model_col doyreverse Spring Fall 
		y0f_&modelvar x0f_&modelvar a1f_&modelvar a2f_&modelvar a3f_&modelvar 
		predf_&modelvar  residf_&modelvar l95f_&modelvar u95f_&modelvar stdif_&modelvar
		y0s_&modelvar x0s_&modelvar a1s_&modelvar a2s_&modelvar a3s_&modelvar 
		preds_&modelvar  resids_&modelvar l95s_&modelvar u95s_&modelvar stdis_&modelvar;
	run;

	/*prepare data for Gubbs' test: only take 1 year, both Spring and Fall */
	data flux2015.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname._&modelvar._&Year._c_&gi;
		ratio1f_&modelvar = &model_col /predf_&modelvar;
		ratio1s_&modelvar = &model_col /preds_&modelvar;
		keep yyyy doy &model_col   preds_&modelvar ratio1s_&modelvar predf_&modelvar ratio1f_&modelvar Spring Fall;
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
	data flux2015.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname;

		if yyyy in ('1992','1996','2000','2004','2008','2012','2016') then doyreverse = 366- doy + 1;
		else doyreverse = 365 - doy + 1;

		if doy <= &spring_cutoff then Spring = 1; else Spring = 0;
		if doy >= &fall_cutoff then Fall = 1; else Fall = 0;

		where (yyyy = "&Year");
	run;

/*prepare data for Gubbs' test: only take 1 year, both Spring and Fall */
/*data flux2015.&dsname._&modelvar._&Year._&gi;
	set flux2015.&dsname._&modelvar._&Year._&gi;
	ratio1f_&modelvar = &model_col /predf_&modelvar;
	ratio1s_&modelvar = &model_col /preds_&modelvar;
	keep yyyy doy &model_col   preds_&modelvar ratio1s_&modelvar predf_&modelvar ratio1f_&modelvar Spring Fall;
run;
*/

/**** Beginning of one iteration ***/
%do %until ((&noutlier_s=0 and &noutlier_f=0) or &gi>30);
title2 "Variable: &modelvar., Grubb's Test Iteration &gi";

%put "**********New Grubb's Iteration Begins *************";
%put "Grubb's Test Iteration. gi=" &gi;
%put "Number of outliers from last iteration(noutlier_s,noutlier_f):" &noutlier_s &noutlier_f;

/* get num_rows of testing dataset */
proc sql noprint;
	select count(*) into : nobs_s
	from flux2015.&dsname._&modelvar._&Year._&gi
	where Spring = 1;

   select count(*) into : nobs_f
   from flux2015.&dsname._&modelvar._&Year._&gi
	where Fall = 1;

	select count(*) into : nobs
   from flux2015.&dsname._&modelvar._&Year._&gi;

quit;
%put "Obs (Spring) in data set:" &nobs_s;
%put "Obs (Fall) in data set:" &nobs_f;
%put "Obs (Spring&Fall) in data set:" &nobs;

title3 "Number of Obs: Spring:&nobs_s., Fall:&nobs_f., Total:&nobs";

/* fit curves */
%Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year,gi=&gi)
* Curves QA - plot curves for this year;
%plot1year(y=&Year, ds=flux2015.&dsname._&modelvar._&Year._&gi)

/* run Macro to calculate Grubb's critical value */
%grubbs_crit(num_s=&nobs_s, num_f=&nobs_f, ds=Grubbs_test)

/* Calculate mean and sd */
proc means data=flux2015.&dsname._&modelvar._&Year._&gi;
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
	create table flux2015.&dsname._&modelvar._&Year._b_&gi as
	select * from 
		flux2015.&dsname._&modelvar._&Year._&gi ds ,meanratio m
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
data flux2015.&dsname._&modelvar._&Year._b_&gi;
	set flux2015.&dsname._&modelvar._&Year._b_&gi;
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
proc freq data=flux2015.&dsname._&modelvar._&Year._b_&gi;
	table Outlier_s /  out=outliercount_s;
	table Outlier_f /  out=outliercount_f;
	/*table Outlier_s Outlier_f; */
run;
proc sql noprint;
	select count(*) into : noutlier_s
	from flux2015.&dsname._&modelvar._&Year._b_&gi
	where Outlier_s = 1;

   select count(*) into : noutlier_f
   from flux2015.&dsname._&modelvar._&Year._b_&gi
	where Outlier_f = 1;
quit;
%put "Outliers (Spring) in data set:" &noutlier_s;
%put "Outliers (Fall) in data set:" &noutlier_f;


proc gplot data=flux2015.&dsname._&modelvar._&Year._b_&gi;
 	plot (&model_col /*pred__&modelvar*/)*doy / overlay;
	plot ratio1s_&modelvar * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot ratio1f_&modelvar * doy=Outlier_f /*vaxis=-5 to 5*/;
	plot &model_col * doy=Outlier_s /*vaxis=-5 to 5*/;
	plot &model_col * doy=Outlier_f /*vaxis=-5 to 5*/;
run;

/* remove outliers */
%let gi_new=%SYSEVALF(&gi+1);

%put "creating new dataset:" &gi &gi_new;

proc sql;
	create table flux2015.&dsname._&modelvar._&Year._b_&gi_new as
	select * from 
		flux2015.&dsname._&modelvar._&Year._b_&gi ds ,meanratio m
	where ds.Outlier_s=0 and ds.Outlier_f=0;
quit;
data flux2015.&dsname._&modelvar._&Year._&gi_new;
	set flux2015.&dsname._&modelvar._&Year._b_&gi_new;
	keep &model_col yyyy doy Spring Fall preds_&modelvar
		predf_&modelvar ratio1s_&modelvar ratio1f_&modelvar;
run;


%put "**********End of iteration. gi=" &gi "*****";

%let gi=%SYSEVALF(&gi+1);

%end; /* end of Grubbs' test iteration */

	proc gplot data=flux2015.&dsname._&modelvar._&Year._&gi_new;
		plot preds_&modelvar	*doy   predf_&modelvar*doy &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;

%mend Grubbs; * end of Macro Grubbs;


/************** Call Macro to perform Grubbs Test *******************/




%Grubbs(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year)
/* %Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year,gi=1)  */

quit;

/* close ODS */
* ods pdf close;
