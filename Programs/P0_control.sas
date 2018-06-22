/* This program controls the entire program flow.           */
/* Date: 03/11/2017      By: TS                             */
/*                                                          */
/*                                                          */

* To avoid log full, print log to file;
proc printto log="C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\log_file.log";
run;

* This is the folder that has all programs to execute;
filename job "C:\Users\tnsongbr\Google Drive\Phenoflux_work\Programs";

* execute Program to import all files (2015version);
%let dsname_all=fluxfiles_all;      /* this is the output file name for merged imported files */

* output dataset directory;
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';

* input file directory;
%Let flxdailydir =C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\input_files;
* input file list;
filename DIRLIST pipe 'dir "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\input_files\*.csv" /b ';


%include job(P1A_import_all_files_2015);

* print out the list of imported individual files;
* this list was created by program P1A;
* we will loop through this list for next steps;
%put &dslist; 
%put &dscntlist;

* execute Program to fit Chapter 3 model;

* add file_name loop to process each dataset (curren P7 processes dataset of one imported file, not the merged version);
%let spring_cutoff = 220;
%let fall_cutoff = 180;

/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';   * input dataset folder(output dataset folder of P1A);
LIBNAME fluxch3 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3'; * output dataset folder for ch3 model;
title;

%macro allfiles_Ch3_Model;
	%do file_i=1 %to &dscntlist;
		%let dsname=%scan(&dslist,&file_i,' ');
		%put "P7: Now Processing File: "  &dsname;

		/* store ODS output file in this directory */
		ods pdf file = "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3\Curves&Grubbs_&dsname..pdf";

		* The program that processes each file;
		/* %include job(P7_Curve&Grubbs_Test); */
		%include job(P7_Ch3Curve&Grubbs_Macros);
		%include job(P7_Ch3Curve&Grubbs_Main);

		* delete temporary files to save space;
		proc datasets lib=work memtype=data kill;
 		run;
	%end;
%mend;
%allfiles_Ch3_Model




* execute Program to calculate Chapter 3 metrics;

/* store output sas dataset files in this directory */
libname fluxch3 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3";
%let outputfolder=C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3;

%macro allfiles_Ch3_Metrics;
	%do file_i=1 %to &dscntlist;
		%let dsname=%scan(&dslist,&file_i,' ');
		%put "P9A: Now Processing File: "  &dsname;
		* The program that processes each file;
		%include job(P9A_Ch3_metrics); 
	%end;
%mend;
%allfiles_Ch3_Metrics

* delete temporary files to save space;
proc datasets lib=work memtype=data kill;
run;

* execute Program to fit Chapter 2 model;

* add file_name loop to process each dataset (curren P7 processes dataset of one imported file, not the merged version);

/* store output sas dataset files in this directory */
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';   * input dataset folder(output dataset folder of P1A);
LIBNAME fluxch2 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2'; * output dataset folder for ch2 model;
title;

%macro allfiles_Ch2_Model;
	%do file_i=1 %to &dscntlist;
		%let dsname=%scan(&dslist,&file_i,' ');
		%put "P8: Now Processing File: "  &dsname;

		* The program that processes each file;
		/* %include job(P8_Ch2Curve&Grubbs); */
		%include job(P8_Ch2Curve&Grubbs_Macros);
		%include job(P8_Ch2Curve&Grubbs_Main);
		* delete temporary files to save space;
		proc datasets lib=work memtype=data kill;
 		run;
	%end;
%mend;
%allfiles_Ch2_Model

* execute Program to calculate Chapter 2 metrics;

%let spring_cutoff =150;
%let fall_cutoff=200; 
/* store output sas dataset files in this directory */
libname fluxch2 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2";
%let outputfolder=C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2;
title;

%macro allfiles_Ch2_Metrics;
	%do file_i=1 %to &dscntlist;
		%let dsname=%scan(&dslist,&file_i,' ');
		%put "P9B: Now Processing File: "  &dsname;
		* The program that processes each file;
		%include job(P9B_Ch2_metrics);
	%end;
%mend;
%allfiles_Ch2_Metrics

* delete temporary files to save space;
proc datasets lib=work memtype=data kill;
run;

* Merge Ch2 and Ch3 metrics files;
libname fluxch2 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch2";
libname fluxch3 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\ch3";
LIBNAME fluxout "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015\metrics";  

title;

%macro allfiles_Merge_Metrics;
	%do file_i=1 %to &dscntlist;
		%let dsname=%scan(&dslist,&file_i,' ');
		%put "P10: Now Processing File: "  &dsname;
		* The program that processes each file;
		%include job(P10_merge_metrics);
	%end;
%mend;
%allfiles_Merge_Metrics

* Merge all metrics files to one big file that has all sites;
LIBNAME flux2015 "C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015"; 

proc sql noprint; * this SQL creates a list of all metrc files;
   select memname into : names separated by ' fluxout.'
     from dictionary.tables 
    where libname='FLUXOUT'; /* note: libname must be in upcase */
quit;

data flux2015.metrics_all;
   merge fluxout.&names;
   by File_Name Year Variable_Name;
 run;


* Close log printing;
proc printto;
run;
