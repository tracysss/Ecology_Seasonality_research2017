
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


/********************** MAIN PROGRAM ****************************/
TITLE1 "2015 Flux Daily Files: &dsname.";
Title2 "Chapter 2 Model";


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

/* define the default values for PROC NLIN */
data work.nlin_default;
	infile DATALINES  delimiter=','; 
	input var  $ y0 a1 a2 b1 b2 t01  t02  c1  c2  y0_lb  y0_hb  
		a1_lb  a1_hb  a2_lb  a2_hb  b1_lb  b1_hb  t01_lb  t01_hb  
		t02_lb  t02_hb  c1_lb  c2_hb ;
	datalines;
GPP,0.229,11.33,12.97,4.22,12.22,155,280,0.3,0.145,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
PPFD,30,700,700,25,35,170,250,1,10,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
RE,0,0,0,0,0,0,0,0,0,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
H,0,0,0,0,0,0,0,0,0,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
LE,0,0,0,0,0,0,0,0,0,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
NEE,0,0,0,0,0,0,0,0,0,-5,15,0,1000,0,1000,-5000,5000,-5000,5000,60,200,150,366,0,100,0,100
;
run;
/*
		bounds y0>=-5.0;  bounds y0<=15.0; 
		bounds a1>=0;  	bounds a1<=1000;
		bounds a2>=0;	bounds a2<=1000;
		bounds b1>=-5000;	bounds b1<=5000;
		bounds b2>=-5000;	bounds b2<=5000;
		bounds t01>=60; bounds t01<=200;
		bounds t02>=150; bounds t02<=366;
		bounds c1>=0.0;	bounds c1<=100; 
		bounds c2>=0.0;	bounds c2<=100; */

/* create a mew parameter dataset to store all parameters by Grubb's test iterations */
data work.&dsname._parameters_ch2;
	length 	File_Name 	$30.
			Year 		$4.
			Variable_Name 	$10.
			Col_Name	$20.
			Iteration	8.
			y0	8.
			a1	8.
			a2	8.
			b1	8.
			b2	8.
			t01	8.
			t02	8.
			c1	8.
			c2	8.
			Outliers	8.
			n_obs		8.
			status		8.
			reason		$200.;

run;

/* Create a temporary dataset to store all variable names */
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

/* remove empty lines in parameters data set */
data fluxch2.&dsname._parameters_ch2;
	set work.&dsname._parameters_ch2;
	where File_Name NE "";
run;

/********************* END OF PROGRAM ***************************/
/* close ODS */

