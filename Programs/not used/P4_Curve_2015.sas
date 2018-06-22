
/* This program is to draw the model curve over the data plots.    		 */
/*	 			(2015 Data)          									 */
/* Date: 09/02/2016       By : TS                                        */

/************ATTENTION!**************************/
/* Change these macro values 					*/
%Let dsname = us_ha1_1991;       * This dataset already has clearday flag;
%Let Begin_Year = '2000';
%Let End_Year = '2004';

/************************************************/
TITLE1 "2015 Flux Daily Files : &dsname";
title2 "Year &Begin_Year to &End_Year";


/* store output sas dataset files in this directory */
LIBNAME clearday 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\clear_day';

/* store ODS output file in this directory */
ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\clear_day\Plots_&dsname._curve.pdf";

options MLOGIC SYMBOLGEN;

title2 'GPP_NT_VUT_REF by doy';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy >= &Start_Year) and (yyyy <= &End_Year);                                                                                                        
run;

title2 'GPP_NT_VUT_REF by doy - Only Clear Days (Ratio >= 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy >= &Start_Year) and (yyyy <= &End_Year) and (clearday = 1);                                                                                                        
run;

title2 'GPP_NT_VUT_REF by doy - NON Clear Days (Ratio < 6)';
proc gplot data=clearday.&dsname._1;                                                                                                                 
   plot GPP_NT_VUT_REF	*doy =clearday /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
   where (yyyy >= &Start_Year) and (yyyy <= &End_Year) and (clearday = 0);                                                                                                        
run;


/********************************/
/* Fit WEIBULL to daily data 	*/
/*	separate spr & fall, 081008	*/
* fit SPRING GEP ;
%Let modelvar=GPP;
proc nlin data=clearday.&dsname._1 /*noprint*/ method=marquardt; by  yyyy; 
	where doy < 200 and (clearday =1);
	parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
	bounds y0>0; bounds 190>x0>130; bounds a1>0; 
	NUM=doy-x0+a2*log(2)**(1/a3);
	model GPP_NT_VUT_REF =y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
	output out=clearday.&dsname._2 parms=y0_&modelvar x0_&modelvar a1_&modelvar a2_&modelvar a3_&modelvar 
		predicted=pred_&modelvar  r=resid_&modelvar l95m=l95_&modelvar u95m=u95_&modelvar stdi=stdi_&modelvar;
	/*STDI specifies a variable that contains the standard error of the individual predicted value.
	  STDP specifies a variable that contains the standard error of the mean predicted value.
	  STDR specifies a variable that contains the standard error of the residual. */
	run;

%Let Year =2013;
title2 "Year &Year";
proc gplot data=gep_parm_spr;
	plot pred_gep	*doy  GPP_NT_VUT_REF * doy  / overlay haxis=axis1
                            legend=legend1;
	where yyyy = "&Year";
run;

/* prepare final parameter dataset */

proc sort data=clearday.&dsname._2 out= &dsname._&modelvar nodupkey;
	by yyyy;
run;
data clearday.&dsname._parm_&modelvar;
	set &dsname._parm_&modelvar;
	keep yyyy y0_&modelvar x0_&modelvar a1_&modelvar a2_&modelvar a3_&modelvar;
run;



* fit FALL GEP ;
/*		proc nlin data=cheq_cumul_a noprint method=marquardt; by site year; 
		where doy2>180 and gepd>0;
			parms y0=0.3 x0=157 a1=17 a2=2000 a3=50;
			bounds y0>0; bounds 190>x0>90; bounds a1>0;
			NUM=doyreverse-x0+a2*log(2)**(1/a3);
			model gepd=y0+a1*(1-exp(-(abs(NUM/a2)**a3)));
			output out=gep_parm_fall parms=y0gep x0gep a1gep a2gep a3gep predicted=pred_gep  r=resid_gep l95m=l95_gep u95m=u95_gep;
		run;
*/



/* close ODS */
ods pdf close;
