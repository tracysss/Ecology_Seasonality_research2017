
/* 1. fit Spring & Fall curves.                 		 */
/* 2. Apply Grubb's Test to remove outliers  			 */
/* This program apply the same process to all variables. */
/* This program will run for all years that are in the dataset. */

/*	 			(2015 Data)         				 */
/* Date: 09/19/2016       By : TS                    */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname =us_ha1_1991_test;       
%Let Begin_Year = 1990;		
%Let End_Year = 2010;
%Let modelvar=GPP;
%Let model_col=GPP_NT_VUT_REF;
%let spring_cutoff = 220;
%let fall_cutoff = 180;
/************************************************/



/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';




options MLOGIC SYMBOLGEN;

/*--------- Definition of Macros -----------------------*/

%MACRO Curves(dsname=,modelvar=,model_col=,Year=,gi=);
	%put "Macro Curves: modelvar=" &modelvar;

	data flux2015.&dsname._&modelvar._&Year._&gi;
		set flux2015.&dsname;

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


	data work.parameters;
		set flux2015.&dsname._&modelvar._&Year._c_&gi(rename=(y0s_&modelvar=y0_s  x0s_&modelvar=x0_s a1s_&modelvar=a1_s
			a2s_&modelvar=a2_s a3s_&modelvar=a3_s y0f_&modelvar=y0_f x0f_&modelvar=x0_f a1f_&modelvar=a1_f 
			a2f_&modelvar=a2_f a3f_&modelvar=a3_f yyyy=year));

		where y0_s NE . and y0_f NE .;

		File_Name ="&dsname";
		Variable_Name="&modelvar";
		Col_Name="&model_col";
		iteration =&gi;

		keep year File_Name Variable_Name Col_Name y0_s  x0_s a1_s a2_s a3_s y0_f x0_f a1_f a2_f a3_f iteration;
	run;

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
	proc gplot data=flux2015.&dsname._&modelvar;
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




/********************** MAIN PROGRAM ****************************/
TITLE1 "2015 Flux Daily Files : &dsname.";


%Let dsname =us_ha1_1991_test;       
%Let Begin_Year = 1990;		
%Let End_Year = 2010;
%Let modelvar=GPP;
%Let model_col=GPP_NT_VUT_REF;
%let Year=2000;
%let gi=1;

%Curves(dsname=&dsname,modelvar=&modelvar,model_col=&model_col,Year=&Year,gi=&gi)





quit;



/********************* END OF PROGRAM ***************************/

