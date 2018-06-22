/* Boundary Detection */
/*	 			(2015 Data)         				 */
/* Date: 11/03/2016       By : TS                    */

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


 


/* plot the data points (spring & fall) for 1 year */ 
%macro Boundary(dsname=,model_col=,Year=);
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';
%Let dsname =us_ha1_1991_test;
%let Year=2000;
%Let modelvar=GPP;
%let model_col=GPP_NT_VUT_REF;



* create a new dataset;
data flux2015.&dsname._&modelvar._boundary;
	length doy 8. day_used 8. &model_col 8. yyyy $4.;
run; 

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


	%let Year=%SYSEVALF(&Begin_Year);
	
	%put "Before loop: Year=" &Year;

	%DO %UNTIL (&Year > &End_Year);
		%put "Begin loop. Year=" &Year;
		* Perform Grubbs Test;

		%boundary_year((Year=&Year, dsname=&dsname,modelvar=&modelvar,model_col=&model_col)
	
		* Move to the next year;
		%let Year=%SYSEVALF(&Year+1);
				%put "End of loop. Year=" &Year;
	%END; /* End of processing for this %Year*/




%mend Boundary; 

* get the 80-percentile point for each day;
%macro individualpoint(day=);
/* %let day=100;*/
* create a temporary table of 5 points (+/-2 days);
%put "Day passed to Macro = " &day;

proc sql noprint;
	create table work.temp as
 	select yyyy, &day as doy, doy as day_used, &model_col
 	from work.&modelvar._&Year
	/*where doy>= %SYSEVALF(input(&day,$3.)-2) and doy<=%SYSEVALF(input(&day,$3.)+2) and yyyy=&Year;*/
	/*	where doy>= (input(&day,$3.)-2) and doy<=(input(&day,$3.)+2) and yyyy=&Year;*/
				where doy>= &day-2 and doy<=&day+2 and yyyy="&Year";
quit;

proc sort data=work.temp;
	by descending &model_col;
run;
* get the 2nd greatest value out of 5;
data work.temp;
	set work.temp ;
	if _n_ = 2;
	call symput("point_value",&model_col);
	&model_col._b = &model_col;
	drop &model_col;
run;

%put "Point_value=" &point_value;

* merge this new observation into the dataset;
proc sort data=work.temp;
	by yyyy doy;
run;
proc sort data=flux2015.&dsname._&modelvar._boundary;
	by yyyy doy;
run;
data flux2015.&dsname._&modelvar._boundary;
	merge flux2015.&dsname._&modelvar._boundary work.temp;
	by yyyy doy;
run; 


%mend individualpoint;


%macro boundary_year(Year=, dsname=, modelvar=, model_col=);
%Let modelvar=GPP;
%Let model_col=GPP_NT_VUT_REF;
%Let dsname =us_ha1_1991_test; 

%let Year=2000;

* create a subset for the year * model_col;

data work.&modelvar._&Year;
	set flux2015.&dsname;
	where yyyy="&Year";
	keep doy &model_col yyyy;
run;
* get the max doy;
proc sort data=work.&modelvar._&Year;
	by yyyy doy;
run;
data _null_ ;
	set work.&modelvar._&Year nobs=obscount;
	if _n_ = obscount then 
		call symput("Max_doy",doy);
run;

%put "max doy=" &Max_doy;

%do i= 3 %to %SYSEVALF(&Max_doy -2);
	%individualpoint(day=&i)
%end;

%mend boundary_year;





/********************** MAIN PROGRAM ****************************/
TITLE1 "2015 Flux Daily Files : &dsname.";


%Let dsname =us_ha1_1991_test;       
%Let Begin_Year = 1990;		
%Let End_Year = 2010;
%Let modelvar=GPP;
%Let model_col=GPP_NT_VUT_REF;
%let Year=2000;


%Boundary(dsname=&dsname,model_col=&model_col,Year=&Year)

%macro test_my_loop;
	%put "test starts";
	%do i= 3 %to 10;
		%put "i=" &i;
	%individualpoint(day=&i)
	%end;
%mend test_my_loop;


%test_my_loop


quit;



/********************* END OF PROGRAM ***************************/

