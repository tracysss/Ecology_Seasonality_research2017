


/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */

* %Let dsname =us_ha1_1991;       

/* store output sas dataset files in this directory */
* libname fluxch3 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3";
* %let outputfolder=C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3;
/**********************************************************************/


/* prepare data:
	1. take the last row of each variable / year to new dataset parameters_final
	2. calculate predicted values using the parameters in the parameters_final dataset
*/

/* Prepare data step 1: */

proc contents data=fluxch3.&dsname._parameters_ch3;
run;

/* keep only Ch3 parameters */
data fluxch3.&dsname._parameters_ch3;
	set fluxch3.&dsname._parameters_ch3;
	keep File_Name
		Year
		Variable_Name
		Col_Name
		Iteration
		Status
		Reason
		y0_s
		x0_s
		a1_s
		a2_s
		a3_s
		y0_f
		x0_f
		a1_f
		a2_f
		a3_f
		n_obs_s
		n_obs_f
		Outliers_s
		Outliers_f;
	where File_Name NE "" and y0_s NE .;
run;

data work.parameters_final0;
	set fluxch3.&dsname._parameters_ch3 end=eof;

	rename 	File_Name	=	File_Name_c
			Year	=	Year_c
			Variable_Name	=	Variable_Name_c
			Col_Name	=	Col_Name_c
			Iteration	=	Iteration_c

			y0_s = y0_s_c
			x0_s=x0_s_c
			a1_s=a1_s_c
			a2_s=a2_s_c
			a3_s=a3_s_c
			y0_f=y0_f_c
			x0_f=x0_f_c
			a1_f=a1_f_c
			a2_f=a2_f_c
			a3_f=a3_f_c

			Outliers_s	=	Outliers_c
			n_obs_s	=	n_obs_c
			Status	=	Status_c                /* need to add _s for Spring */
			Reason	=	Reason_c
			Outliers_f	=	Outliers_f_c
			n_obs_f	=	n_obs_f_c
			Status_f	=	Status_f_c
			Reason_f	=	Reason_f_c;

	where iteration NE .;

	output;
	
	if eof then 
	do;
		iteration = 1;
		output;
	end;
run;

data work.parameters_final1;
	set work.parameters_final0;

	File_Name	=	LAG(File_Name_c);
	Year	=	LAG(Year_c);
	Variable_Name	=	LAG(Variable_Name_c);
	Col_Name	=	LAG(Col_Name_c);
	Iteration	=	LAG(Iteration_c);

	y0_s = LAG(y0_s_c);
	x0_s = LAG(x0_s_c);
	a1_s = LAG(a1_s_c);
	a2_s = LAG(a2_s_c);
	a3_s = LAG(a3_s_c);

	y0_f = LAG(y0_f_c);
	x0_f = LAG(x0_f_c);
	a1_f = LAG(a1_f_c);
	a2_f = LAG(a2_f_c);
	a3_f = LAG(a3_f_c);

	Outliers	=	LAG(Outliers_c);  		/* need to add _s for Spring */
	n_obs	=	LAG(n_obs_c);
	Status	=	LAG(Status_c);
	Reason	=	LAG(Reason_c);
	Outliers_f	=	LAG(Outliers_f_c);
	n_obs_f		=	LAG(n_obs_f_c);
	Status_f	=	LAG(Status_f_c);
	Reason_f	=	LAG(Reason_f_c);
	
run;

data work.parameters_final2;
	set work.parameters_final1;
	where iteration_c=1;
run;

data fluxch3.&dsname._ch3_final;
	set work.parameters_final2;
	where iteration NE .;
	drop File_Name_c  Year_c Variable_Name_c Col_Name_c Iteration_c 
		y0_s_c x0_s_c a1_s_c a2_s_c a3_s_c 
		y0_f_c x0_f_c a1_f_c a2_f_c a3_f_c
		Outliers_c n_obs_c 		Status_c Reason_c  		/* need to add _s for Spring */
		Outliers_f_c n_obs_f_c	Status_f_c Reason_f_c;
run;


/* get parameter for the year from Parameter_final dataset */
/* Create a temporary dataset to store all variable names */
/* We can also import a file that has variable names. */

* create Macro lists for variables;
proc sql noprint;
 select Year,Variable_Name,Col_Name,y0_s,x0_s,a1_s,a2_s,a3_s,y0_f,x0_f,a1_f,a2_f,a3_f
 into 
 	:Year_list separated by ' ',
 	:modelvar_list separated by ' ',
 	:model_col_list separated by ' ',
 	:y0_s_list separated by ' ',
 	:x0_s_list separated by ' ',
 	:a1_s_list separated by ' ',
 	:a2_s_list separated by ' ',
 	:a3_s_list separated by ' ',
 	:y0_f_list separated by ' ',
 	:x0_f_list separated by ' ',
 	:a1_f_list separated by ' ',
 	:a2_f_list separated by ' ',
 	:a3_f_list separated by ' '
 from fluxch3.&dsname._ch3_final;
 quit;
%let cntlist = &sqlobs; * Get a count of number of variables;

/*
%put &Year_list; 
%put &modelvar_list; 
%put &model_col_list; 
%put &y0_list; 
%put &a1_list; 
%put &a2_list; 
%put &b1_list; 
%put &b2_list; 
%put &t01_list; 
%put &t02_list; 
%put &c1_list; 
%put &c2_list; 
*/

%put &cntlist;

* This macro loops all Variables to process one by one;
%macro pred_dataset;
	
	%let file_exist =0;
	%do i=1 %to &cntlist;

		%let Year=%scan(&Year_list,&i,' ');
		%let modelvar=%scan(&modelvar_list,&i,' ');
		%let model_col=%scan(&model_col_list,&i,' ');
		%let y0_s=%scan(&y0_s_list,&i,' ');
		%let x0_s=%scan(&x0_s_list,&i,' ');
		%let a1_s=%scan(&a1_s_list,&i,' ');
		%let a2_s=%scan(&a2_s_list,&i,' ');
		%let a3_s=%scan(&a3_s_list,&i,' ');
		%let y0_f=%scan(&y0_f_list,&i,' ');
		%let x0_f=%scan(&x0_f_list,&i,' ');
		%let a1_f=%scan(&a1_f_list,&i,' ');
		%let a2_f=%scan(&a2_f_list,&i,' ');
		%let a3_f=%scan(&a3_f_list,&i,' ');

		%put "Now Processing Variable: " &Year &modelvar &model_col;

		%if (&Year = '2012' or &Year = '2008' or &Year = '2004' or &Year= '2000' or &Year = '1996'
			or &Year = '1992') and (mm > '02') %then  %let last_day =366; %else %let last_day=365;
		%let doy=1;

			
		/* create the dataset for curent year/variable, one row per day */
		data work.&dsname._pred_&modelvar._&Year;

			do doy = 1 to &last_day;

				File_Name="&dsname";
				Year=&Year;
				Variable_Name="&modelvar";
				Col_Name="&model_col";
				y0_s	=&y0_s;
				x0_s	=&x0_s;
				a1_s	=&a1_s;
				a2_s	=&a2_s;
				a3_s	=&a3_s;
				y0_f	=&y0_f;
				x0_f	=&x0_f;
				a1_f	=&a1_f;
				a2_f	=&a2_f;
				a3_f	=&a3_f;

				NUM_s=doy-x0_s+a2_s*log(2)**(1/a3_s);  
				pred_s =y0_s+a1_s*(1-exp(-(abs(NUM_s/a2_s)**a3_s))); /*?   "**" WAS NOT RECGONIZED. GOT AN ERROR */
				NUM_f=doy-x0_f+a2_f*log(2)**(1/a3_f);
				pred_f =y0_f+a1_f*(1-exp(-(abs(NUM_f/a2_f)**a3_f)));

				output;
			end;

			/*drop NUM_s NUM_f;*/
		run;
	
		%if &file_exist=1 %then 
		%do;
		proc sort data=work.&dsname._pred_&modelvar._&Year;
			by File_Name Variable_Name  Year;
		run;

		data fluxch3.&dsname._pred;
			merge fluxch3.&dsname._pred work.&dsname._pred_&modelvar._&Year;
			by File_Name Variable_Name  Year;
		run;
		%end;
		%else %do;
			data fluxch3.&dsname._pred;
				set  work.&dsname._pred_&modelvar._&Year;
			run;

			%let file_exist =1;
		%end;

	%end;
%mend;
%pred_dataset



****************************************************************************************************;
	* 	calc phenological metrics 																		;
	* 	create 2 PRED datasets, because there is duplication of DOY between SPRING and FALL fittings 	;
		

data fluxch3.&dsname._pred; 
	set fluxch3.&dsname._pred;

	if doy >1 then der_s=pred_s -lag(pred_s); else der_s=.; 
	if doy>2 then der2_s=der_s-lag(der_s); else der2_s=.;

	if doy >1 then der_f=pred_f -lag(pred_f); else der_f=.; 
	if doy>2 then der2_f=der_f-lag(der_f); else der2_f=.;
run;

* confirm that the derivatives look good & do not exclude outliers ("where" clause) ;
				/*proc gplot data=pred_gep_spr; by site; where abs(der2s_gep)<0.07; plot ders_gep*doy2=year; plot2 der2s_gep*doy2=year; run;
				proc gplot data=pred_gep_fall; by site; where abs(der2f_gep)<0.07 and site='mrp' and year=2003; 
					plot (gepd pred_gep derf_gep)*doy2 / overlay; plot2 der2f_gep*doy2=year; run;
				proc gplot data=pred_er_spr; by site; where abs(der2s_er)<0.07; plot ders_er*doy2=year; plot2 der2s_er*doy2=year; run;
				proc gplot data=pred_er_fall; by site; where abs(der2f_er)<0.07; plot derf_er*doy2=year; plot2 der2f_er*doy2=year; run;
				*/
proc sort data=fluxch3.&dsname._pred;
	by file_name variable_name year; 
run;

proc means data=fluxch3.&dsname._pred mean min max noprint; 
	by file_name variable_name year;  where abs(der2_s)<0.07;
	var der_s der2_s;
	output out=deriv_s mean=m1-m2 min=min1-min2 max=max1-max2;
run;
proc means data=fluxch3.&dsname._pred mean min max noprint; 
	by file_name variable_name year;  where abs(der2_f)<0.07;
	var der_f der2_f;
	output out=deriv_f mean=m1-m2 min=min1-min2 max=max1-max2;
run;

data fluxch3.&dsname._pred; 
	set fluxch3.&dsname._pred;

	if doy<200 then pred = pred_s;
	else pred = pred_f;

run;



proc sort data=fluxch3.&dsname._pred; 
	by file_name variable_name year; 
run;



data deriv1; 
	merge fluxch3.&dsname._pred
		deriv_s (rename=(max1=max1s max2=max2s min1=min1s min2=min2s m1=m1s m2=m2s)) 
		deriv_f (rename=(max1=max1f max2=max2f min1=min1f min2=min2f m1=m1f m2=m2f)); 

	by file_name variable_name year; 
	* season durations ;
	if der_s=max1s then d1_start=doy; 
	if der_f=min1f then d1_end=doy;
	if der2_s=max2s then d2_maxstart=doy;
	if der2_s=min2s then d2_minstart=doy;
	if der2_f=max2f then d2_maxend=doy;
	if der2_f=min2f then d2_minend=doy;
run;

proc sort data=deriv1 nodupkey out=d1_start; 
	by file_name variable_name year; 
	where d1_start ne .; 
run;

proc sort data=deriv1 nodupkey out=d1_end; 
	by file_name variable_name year;  
	where d1_end ne .; 
run;

proc sort data=fluxch3.&dsname._pred nodupkey out=x0s; 
	by file_name variable_name year; 
	where x0_s ne .; 
run;
proc sort data=fluxch3.&dsname._pred nodupkey out=x0f; 
	by file_name variable_name year; 
	where x0_f ne .; 
run;

proc sort data=deriv1 nodupkey out=d2_maxstart; 
	by file_name variable_name year; 
	where d2_maxstart ne .; 
run;
proc sort data=deriv1 nodupkey out=d2_minstart; 
	by file_name variable_name year; 
	where d2_minstart ne .; 
run;

proc sort data=deriv1 nodupkey out=d2_maxend; 
	by file_name variable_name year; 
	where d2_maxend ne .; 
run;

proc sort data=deriv1 nodupkey out=d2_minend; 
	by file_name variable_name year; 
	where d2_minend ne .; 
run;


data deriv2; merge deriv1
	d1_start (keep=file_name variable_name year  d1_start)
	d1_end (keep=file_name variable_name  year  d1_end)
	d2_maxstart (keep=file_name variable_name  year  d2_maxstart)
	d2_minstart (keep=file_name variable_name  year  d2_minstart)
	d2_maxend (keep=file_name variable_name  year  d2_maxend)
	d2_minend (keep=file_name variable_name  year  d2_minend)
	x0s (keep=file_name variable_name  year x0_s) 
	x0f (keep=file_name variable_name  year x0_f) ;
	by file_name variable_name year; 

	smr_length1=d1_end-d1_start; 			* C-F = ;
	smr_lengthx0=(365-x0_f)-x0_s; 			* x0 based = ; 
	smr_length2=d2_minend-d2_minstart; 		* D-E = LPF;
	smr_length2b=d2_maxend-d2_maxstart; 	* B-G = ;
	spr_length2=d2_minstart-d2_maxstart; 	* B-D = LFD;
	fl_length2=d2_maxend-d2_minend; 		* E-G = LFR;

run;

proc reg data=deriv2 outest=slopes_s noprint; 
	by file_name variable_name year; 
	where doy between d2_maxstart and d2_minstart;
	model pred_s=doy; 
run;
proc reg data=deriv2 outest=slopes_f noprint; 
	by file_name variable_name year; 
	where doy between d2_maxend and d2_minend;
	model pred_f=doy; 
run;
proc sort data=deriv2 out=deriv2short nodupkey;
	by file_name variable_name year; 
run;

data fluxch3.&dsname._derivout; merge deriv2short (drop=_TYPE_ 
	rename=
	(smr_lengthx0=asl_x0 smr_length2=lpf_DE spr_length2=lfd_BD fl_length2=lfr_EG))
	slopes_s (where=(_TYPE_="PARMS") rename=(Intercept=interc_s doy=slope_s))
	slopes_f (where=(_TYPE_="PARMS") rename=(Intercept=interc_f doy=slope_f))
			/*			winterbase_gep winterbase_er*/;

	by file_name variable_name year; 

	sos_point_a=(-interc_s/*+gepbase_s*/)/slope_s;
	eos_point_h=(-interc_f/*+gepbase_f*/)/slope_f;
	asl_AH=eos_point_h-sos_point_a;						* A-H ;

	/*if site='ihw' then do; hwconif='hw'; age=17; lai=3.0; ba=12; end;
	if site='irp' then do; hwconif='co'; age=21; lai=2.8; ba=18; end;
	if site='mhw' and year=2002 then do; hwconif='hw'; age=65; lai=3.9; ba=33.5; end;
	if site='mhw' and year=2003 then do; hwconif='hw'; age=66; lai=3.9; ba=33.5; end;
	if site='mrp' and year=2002 then do; hwconif='co'; age=63; lai=2.5; ba=26.9; end;
	if site='mrp' and year=2003 then do; hwconif='co'; age=64; lai=2.7; ba=26.9; end;
	if site='yhw' then do; hwconif='hw'; age=3; lai=1.3; ba=1.5 ; end;
	if site='yrp' then do; hwconif='co'; age=8; lai=0.5; ba=4.7; end; */

	file "&outputfolder.\&dsname._SOS_EOS.txt" lrecl=2000;
	if _n_=1 then put
			'site variable year age lai ba hwconif smr_length1 d1_end d1_start
				asl_x0 x0_f x0_s  ASL_AH sos_point_a
				eos_point_h lpf_DE d2_minend d2_minstart
				smr_length2b d2_maxend d2_maxstart
				lfd_BD d2_minstart d2_maxstart
				lfr_EG d2_maxend d2_minend
				slope_s slope_f 
				interc_f interc_f sos_point_a eos_point_h asl_AH';
	/*if smr_length1_gep ne . then */
	put file_name$ variable_name$ year age lai ba hwconif$ 
		smr_length1 d1_end d1_start
		asl_x0 x0_f x0_s
		ASL_AH
		sos_point_a eos_point_h 
		lpf_DE d2_minend d2_minstart
		smr_length2b d2_maxend d2_maxstart
		lfd_BD d2_minstart d2_maxstart
		lfr_EG d2_maxend d2_minend
		slope_s slope_f
		interc_s interc_f
		sos_point_a  eos_point_h asl_AH;
run;

data fluxch3.&dsname._outfig; set fluxch3.&dsname._derivout;
	file "&outputfolder.\&dsname._SOS_EOS_forFIG.txt" lrecl=2000;
	if _n_=1 then put
	"site variable year age lai ba hwconif ASL_AH SOS_A EOS_H LFD LPF LFR RD RR";
	put file_name$ variable_name$ year age lai ba hwconif$ ASL_AH sos_point_a eos_point_h 
		lfd_BD lpf_DE lfr_EG slope_s slope_f;
run;

* convert DERIVOUT to format suitable for ANOVA-s at the end ;
proc sort data=fluxch3.&dsname._derivout; 
	by  hwconif; 
run;

					

