
/* This program fits Chapter 2 curve. */
/* This program will run for all years that are in the dataset. */

/*	 			(2015 Data)         				 */
/* Date: 10/12/2016       By : TS                    */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname =us_umb_2000;       
%Let Begin_Year = 2000;		
%Let End_Year = 2014;
%Let modelvar=PPFD;
%Let model_col=PPFD_IN;
%let gi=1;



/************************************************/



/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';

options MLOGIC SYMBOLGEN;

/*--------- Definition of Macros -----------------------*/


%MACRO Curves_ch2(dsname=,modelvar=,model_col=);
	%put "Macro Curves: modelvar=" &modelvar;

	proc nlin data=flux2015.&dsname/*_&modelvar._&Year._&gi*/ noprint method=marquardt NOHALVE; 
		by  yyyy; 
	%put "Proc nlin";

		
		/* parms y0=0.5 a1=4.0 a2=4.0 b1=10.0 b2=5.0 t01=50 t02=300 c1=1.0 c2=1.0;*/   /* lianhong; */ 
		 /*Good: 1996, 1999, 2001 */

		  parms y0=115 a1=1000 a2=1000 b1=50 b2=50 t01=153 t02=210 c1=10 c2=10;  








		/*parms y0=0.12 a1=13.0 a2=13.0 b1=4.1 b2=10.5 t01=160 t02=250 c1=0.27 c2=1.0; */

		/*parms y0=0.1 a1=50 a2=50 b1=5 b2=5 t01=150 t02=250 c1=100; */

		bounds b1>=-5000;	bounds b1<=5000;
		bounds b2>=-5000;	bounds b2<=5000;


		bounds y0>=-5.0;  bounds y0<=1500.0; 
		bounds a1>=0;  	bounds a1<=1500.0;
		bounds a2>=0;	bounds a2<=2500.0;
		/*bounds b1>=-10000.0;	bounds b1<=10000.0;
		bounds b2>=-10000.0;	bounds b2<=10000.0;*/

		bounds c1>=0.0;	bounds c1<=10000.0; 
		bounds c2>=0.0;	bounds c2<=10000.0;
		bounds t01>=60; bounds t01<=200;
		bounds t02>=150; bounds t02<=366;


		model &model_col =y0+ (a1 / ((1+exp(-(doy-t01)/b1))**c1)) - a2 / ((1+exp(-(doy-t02)/b2))**c2);
		output out=flux2015.&dsname._&modelvar._ch2 parms=y0_&modelvar a1_&modelvar a2_&modelvar 
										 b1_&modelvar  b2_&modelvar  t01_&modelvar  t02_&modelvar  c1_&modelvar c2_&modelvar
			predicted=pred_&modelvar  r=resid_&modelvar l95m=l95_&modelvar u95m=u95_&modelvar stdi=stdi_&modelvar;

	run;

	data flux2015.&dsname._&modelvar._ch2_year;
		set flux2015.&dsname._&modelvar._ch2;
		keep yyyy y0_&modelvar a1_&modelvar a2_&modelvar b1_&modelvar  b2_&modelvar 
			t01_&modelvar  t02_&modelvar  c1_&modelvar c2_&modelvar;
	run;
	proc sort data=flux2015.&dsname._&modelvar._ch2_year nodupkey;
		by yyyy;
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



%Mend CURVES_CH2; 
 


/* plot the data points (spring & fall) for 1 year */ 
%macro plot1year(y=, dsname=);
	title3 "Year &y";
	proc gplot data=flux2015.&dsname._ch2;
		plot pred_&modelvar	*doy   /*predf_&modelvar*doy*/ &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy  = "&y";
	run;
%mend plot1year; 
/* plot the data points (spring & fall) for multiple years */ 
%macro plotmultiple(begin_y=, end_y=);
	TITLE1 "2015 Flux Daily Files : &dsname.";
	title2 "&modelvar., &model_col";
	proc gplot data=flux2015.&dsname._ch2;
		plot preds_&modelvar	*doy   predf_&modelvar*doy &model_col * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy >= "&begin_y" and yyyy<="&end_y";
	run;
%mend plotmultiple; 

%MACRO plotbyyear(begin_y=, end_y=);
	TITLE1 "2015 Flux Daily Files : &dsname.";
	title2 "&modelvar., &model_col";
	%DO y = &begin_y %TO &end_y;
		%plot1year(y=&y, dsname=&dsname);
	%END;
%MEND plotbyyear; /* End of %MACRO plotbyyear */





/********************** MAIN PROGRAM ****************************/





/*
GPP,GPP_NT_VUT_REF
RE,RECO_NT_VUT_REF
PPFD,PPFD_IN
H,H_CORR
LE,LE_CORR
NEE,NEE_VUT_REF
*/

%Curves_ch2(dsname=&dsname,modelvar=&modelvar,model_col=&model_col)
%plotbyyear(begin_y=&Begin_Year,end_y=&End_Year) 


quit;



/********************* END OF PROGRAM ***************************/
/* close ODS */

