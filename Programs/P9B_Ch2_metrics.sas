

/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */

* %Let dsname =us_wcr_1999;     
* %let spring_cutoff =150;
* %let fall_cutoff=200; 

/* store output sas dataset files in this directory */
* LIBNAME fluxch2 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2A';
* %let outputfolder=C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2A;

/**********************************************************************/




/* prepare data:
	1. take the last row of each variable / year to new dataset parameters_final
	2. calculate predicted values using the parameters in the parameters_final dataset
*/

/* Prepare data step 1: */
proc contents data=fluxch2.&dsname._parameters_ch2;
run;

data work.parameters_final0;
	set fluxch2.&dsname._parameters_ch2 end=eof;

	rename 	File_Name	=	File_Name_c
			Year	=	Year_c
			Variable_Name	=	Variable_Name_c
			Col_Name	=	Col_Name_c
			Iteration	=	Iteration_c
			y0	=	y0_c
			a1	=	a1_c
			a2	=	a2_c
			b1	=	b1_c
			b2	=	b2_c
			t01	=	t01_c
			t02	=	t02_c
			c1	=	c1_c
			c2	=	c2_c
			Outliers	=	Outliers_c
			n_obs	=	n_obs_c
			Status	=	Status_c
			Reason	=	Reason_c;

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
	y0	=	LAG(y0_c);
	a1	=	LAG(a1_c);
	a2	=	LAG(a2_c);
	b1	=	LAG(b1_c);
	b2	=	LAG(b2_c);
	t01	=	LAG(t01_c);
	t02	=	LAG(t02_c);
	c1	=	LAG(c1_c);
	c2	=	LAG(c2_c);
	Outliers	=	LAG(Outliers_c);
	n_obs	=	LAG(n_obs_c);
	Status	=	LAG(Status_c);
	Reason	=	LAG(Reason_c);
	
run;

data work.parameters_final2;
	set work.parameters_final1;
	where iteration_c=1;
run;

data fluxch2.&dsname._ch2_final;
	set work.parameters_final2;
	where iteration NE .;
	drop File_Name_c  Year_c Variable_Name_c Col_Name_c Iteration_c y0_c
		a1_c a2_c b1_c b2_c t01_c  t02_c c1_c c2_c Outliers_c n_obs_c
		Status_c Reason_c;
run;


/* get parameter for the year from Parameter_final dataset */
/* Create a temporary dataset to store all variable names */
/* We can also import a file that has variable names. */

* create Macro lists for variables;
proc sql noprint;
 select Year,Variable_Name,Col_Name,y0,a1,a2,b1,b2,t01,t02,c1,c2
 into 
 	:Year_list separated by ' ',
 	:modelvar_list separated by ' ',
 	:model_col_list separated by ' ',
 	:y0_list separated by ' ',
 	:a1_list separated by ' ',
 	:a2_list separated by ' ',
 	:b1_list separated by ' ',
 	:b2_list separated by ' ',
 	:t01_list separated by ' ',
 	:t02_list separated by ' ',
 	:c1_list separated by ' ',
 	:c2_list separated by ' '
 from fluxch2.&dsname._ch2_final;
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
		%let y0=%scan(&y0_list,&i,' ');
		%let a1=%scan(&a1_list,&i,' ');
		%let a2=%scan(&a2_list,&i,' ');
		%let b1=%scan(&b1_list,&i,' ');
		%let b2=%scan(&b2_list,&i,' ');
		%let t01=%scan(&t01_list,&i,' ');
		%let t02=%scan(&t02_list,&i,' ');
		%let c1=%scan(&c1_list,&i,' ');
		%let c2=%scan(&c2_list,&i,' ');

		%put "Now Processing Variable: " &Year &modelvar &model_col ;

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
				y0	=&y0;
				a1	=&a1;
				a2	=&a2;
				b1	=&b1;
				b2	=&b2;
				t01	=&t01;
				t02	=&t02;
				c1	=&c1;
				c2	=&c2;
				
				part1 = a1 / ((1 + exp (- (doy-t01)/b1)) ** c1);/* error on **, confirmed as data error */
				part2 = a2 / ((1 + exp (- (doy-t02)/b2)) ** c2);
				if part1 =. then part1=0;
				if part2 =. then part2=0;
				pred = y0 + part1 - part2;
				/*pred = y0 + a1 / ((1 + exp (- (doy-t01)/b1)) ** c1) - a2 / ((1+exp(-(doy-t02)/b2))**c2);*/

				output;
			end;

			/*drop part1 part2;*/
		run;
	
		%if &file_exist=1 %then 
		%do;
		proc sort data=work.&dsname._pred_&modelvar._&Year;
			by File_Name Variable_Name  Year;
		run;

		data fluxch2.&dsname._pred;
			merge fluxch2.&dsname._pred work.&dsname._pred_&modelvar._&Year;
			by File_Name Variable_Name  Year;
		run;
		%end;
		%else %do;
			data fluxch2.&dsname._pred;
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

data fluxch2.&dsname._pred; 
	set fluxch2.&dsname._pred;

	lag_pred = lag(pred);
	if doy >1 then der=pred -lag_pred; else der=.; 

	lag_der = lag(der);
	if doy>2 then der2=der-lag_der; else der2=.;

	drop lag_pred lag_der;
run;

data pred_seasonal;
	set fluxch2.&dsname._pred; 
	if doy<= &fall_cutoff then
		der_s = der;
		der2_s = der2;
		pred_s = pred;
	do;
	end;
	if doy>=&spring_cutoff then
	do;
		der_f = der;
		der2_f = der2;
		pred_f = pred;
	end;
run;

proc means data=pred_seasonal mean min max noprint; 
	by file_name variable_name year;  where abs(der2_s)<0.07;
	var der_s der2_s;
	output out=deriv_s mean=m1-m2 min=min1-min2 max=max1-max2;
run;
proc means data=pred_seasonal mean min max noprint; 
	by file_name variable_name year;  where abs(der2_f)<0.07;
	var der_f der2_f;
	output out=deriv_f mean=m1-m2 min=min1-min2 max=max1-max2;
run;

proc sort data=fluxch2.&dsname._pred; 
	by file_name variable_name year doy; 
run;
data /*fluxch2.*/deriv1; 
	merge /*fluxch2.&dsname._pred*/ pred_seasonal
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



proc sort data=deriv1 nodupkey out=d1_start; by file_name variable_name year;  where d1_start ne .; run;
proc sort data=deriv1 nodupkey out=d1_end; by file_name variable_name year;  where d1_end ne .; run;

proc sort data=deriv1 nodupkey out=d2_maxstart; by file_name variable_name year;  where d2_maxstart ne .; run;
proc sort data=deriv1 nodupkey out=d2_minstart; by file_name variable_name year;  where d2_minstart ne .; run;


proc sort data=deriv1 nodupkey out=d2_maxend; by file_name variable_name year; where d2_maxend ne .; run;
proc sort data=deriv1 nodupkey out=d2_minend; by file_name variable_name year;  where d2_minend ne .; run;

proc sort data=fluxch2.&dsname._pred nodupkey out=x0s; 
	by file_name variable_name year; 
	where t01 ne .; 
run;
proc sort data=fluxch2.&dsname._pred nodupkey out=x0f; 
	by file_name variable_name year; 
	where t02 ne .; 
run;

data x0s;
	set x0s;
	rename t01=x0_s t02=x0_f;
run;
data x0f;
	set x0f;
	rename t01=x0_s t02=x0_f;
run;

data deriv2; 
	merge deriv1
	d1_start (keep=file_name variable_name year d1_start)
	d1_end (keep=file_name variable_name year d1_end)
	d2_maxstart (keep=file_name variable_name year d2_maxstart)
	d2_minstart (keep=file_name variable_name year d2_minstart)
	d2_maxend (keep=file_name variable_name year d2_maxend)
	d2_minend (keep=file_name variable_name year d2_minend)
	x0s (keep=file_name variable_name  year x0_s) 
	x0f (keep=file_name variable_name  year x0_f);


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


data fluxch2.&dsname._derivout; merge deriv2short (drop=_TYPE_ 
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


data fluxch2.&dsname._outfig; set fluxch2.&dsname._derivout;
	file "&outputfolder.\&dsname._SOS_EOS_forFIG.txt" lrecl=2000;
	if _n_=1 then put
	"site variable year age lai ba hwconif ASL_AH SOS_A EOS_H LFD LPF LFR RD RR";
	put file_name$ variable_name$ year age lai ba hwconif$ ASL_AH sos_point_a eos_point_h 
		lfd_BD lpf_DE lfr_EG slope_s slope_f;
run;


data derivoutanova; set fluxch2.&dsname._derivout; run;

proc sort data=derivoutanova; by  hwconif; run;


* 	calc phenol metrics OVER																		;
****************************************************************************************************;
					

