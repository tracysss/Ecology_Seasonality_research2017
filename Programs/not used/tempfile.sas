
/* 1. fit Spring & Fall curves.                 		 */
/* 2. Apply Grubb's Test to remove outliers  			 */
/* This program apply the same process to all variables. */
/* This program will run for all years that are in the dataset. */

/*	 			(2015 Data)         				 */
/* Date: 09/19/2016       By : TS                    */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname =us_ha1_1991;       
%Let Begin_Year = 1990;		
%Let End_Year = 2010;
%Let modelvar=GPP;
%Let model_col=GPP_NT_VUT_REF;
%let spring_cutoff = 220;
%let fall_cutoff = 180;
/************************************************/



/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';


data flux2015.&dsname._test;
	set flux2015.&dsname;
	where yyyy in ('2000'/*,'2001','2002'*/);
run;

/* prepare test data for proc nlin */
data flux2015.testdata;
	set flux2015.us_ha1_1991(rename = (yyyy=year GPP_NT_VUT_REF = gpp ));

	keep timestamp	gpp year doy;
	

run;


/* proc nlin */
	proc nlin data=flux2015.testdata noprint method=marquardt NOHALVE; 
		by  year; 

		parms y0=0.229 a1=11.33 a2=12.97 b1=4.22 b2=12.22 t01=155 t02=280 c1=0.30 c2=0.145;  

		bounds y0>=-5.0;  bounds y0<=15.0; 
		bounds a1>=0;  	bounds a1<=1000;
		bounds a2>=0;	bounds a2<=1000;
		bounds b1>=-5000;	bounds b1<=5000;
		bounds b2>=-5000;	bounds b2<=5000;
		bounds t01>=60; bounds t01<=200;
		bounds t02>=150; bounds t02<=366;
		bounds c1>=0.0;	bounds c1<=100; 
		bounds c2>=0.0;	bounds c2<=100;

		model gpp =y0+ (a1 / ((1+exp(-(doy-t01)/b1))**c1)) - a2 / ((1+exp(-(doy-t02)/b2))**c2);

		output out=work.testdata_out
			parms=y0 a1 a2	b1  b2  t01  t02  c1 c2
			predicted=pred  r=resid l95m=l95 u95m=u95 stdi=stdi;

	run;
