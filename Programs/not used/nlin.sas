/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';


ods listing close;
ods graphics off;

ods output ParameterEstimates = parm;
/* proc nlin */
	proc nlin data=flux2015.testdata /*noprint*/ method=marquardt NOHALVE; 
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

		ods output ConvergenceStatus=work.status;

	run;

	proc print data = parm ;run;

ods listing;

data work.parm;
	set work.parm;
	keep year parameter stderr;
	if parameter in ('a1','a2','b1','b2','c1','c2','y0','t01','t02');
run;

proc sort data=work.parm;
	by year parameter;
run;


proc transpose data=work.parm out=work.parmse prefix=se;
    by year ;
    id parameter;
    var StdErr;

run;

data work.parmse;
	set work.parmse;
	drop _label_ _name_;

	rename sea1=a1_se sea2=a2_se seb1=b1_se seb2=b2_se sec1=c1_se sec2=c2_se
		sey0=y0_se set01=t01_se set02=t02_se;
run;
