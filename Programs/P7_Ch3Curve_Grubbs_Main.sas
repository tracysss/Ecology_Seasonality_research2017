
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

/* define the default values for PROC NLIN */
data work.nlin_default;
	infile DATALINES  delimiter=','; 
	input var  $ y0s x0s a1s a2s a3s y0f  x0f  a1f  a2f  a3f
		y0s_lb y0s_hb x0s_lb  x0s_hb  a1s_lb a1s_hb a2s_lb a2s_hb 
		a3s_lb a3s_hb y0f_lb  y0f_hb  x0f_lb  x0f_hb  a1f_lb a1f_hb  
		a2f_lb  a2f_hb   a3f_lb a3f_hb;
	datalines;
GPP,0.3,157,17,2000,50,0.3,157,17,2000,50,0,99999,130,190,0,9999,-9999,9999,-9999,9999,0,9999,90,190,0,9999,-9999,9999,-9999,9999
PPFD,0,0,0,0,0,0,0,0,0,0,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999
RE,0.3,157,5,2000,50,0.3,157,5,2000,50,0,99999,130,190,0,9999,-9999,9999,-9999,9999,0,9999,80,190,0,9999,-9999,9999,-9999,9999
H,0,0,0,0,0,0,0,0,0,0,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999
LE,0,0,0,0,0,0,0,0,0,0,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999
NEE,0,0,0,0,0,0,0,0,0,0,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999,-9999,9999
;
run;


/*
		GPP Spring: parms y0=0.3 x0=157 a1=17 a2=2000 a3=50; bounds y0>0; bounds 190>x0>130; bounds a1>0; 
		GPP Fall: parms y0=0.3 x0=157 a1=17 a2=2000 a3=50; bounds y0>0; bounds 190>x0>90; bounds a1>0;
		RE Spring: parms y0=0.3 x0=157 a1=5 a2=2000 a3=50; bounds y0>0; bounds 190>x0>130; 
		RE fall: parms y0=0.3 x0=157 a1=5 a2=2000 a3=50; bounds y0>0; bounds 190>x0>80; 
*/


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
