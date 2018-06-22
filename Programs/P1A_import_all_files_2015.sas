/* This program is to import 2015 version files.            */
/* Date: 11/2/2016       By: TS                             */
/*                                                          */
/* This program imports all csv files in the input folder.  */
/* The output is a dataset that contains all imported csv   */
/* files. Output dataset is flux2015.fluxfiles_all          */
/*                                                          */

/***************************ATTENTION!*********************************/
/* Change this part if using values other than in the control program */
* %let dsname_all=newfile;
/**********************************************************************/





%MACRO Import1file(filename=,dsname=);

* import one file &filename;
data flux2015.&dsname;
	INFILE "&flxdailydir\&filename" 
		DLM = ',' MISSOVER DSD FIRSTOBS = 2 LRECL = 100000;

		File_name="&dsname";

	INFORMAT TIMESTAMP $8.	TA_F	TA_F_QC	SW_IN_POT	SW_IN_F	SW_IN_F_QC	
		LW_IN_F	LW_IN_F_QC	VPD_F	VPD_F_QC	PA_F	PA_F_QC	P_F	P_F_QC	WS_F	
		WS_F_QC	USTAR	USTAR_QC	NETRAD	NETRAD_QC	PPFD_IN	PPFD_IN_QC	CO2_F_MDS	
		CO2_F_MDS_QC	TS_F_MDS_1	TS_F_MDS_1_QC	SWC_F_MDS_1	SWC_F_MDS_1_QC	
		G_F_MDS	G_F_MDS_QC	LE_F_MDS	LE_F_MDS_QC	LE_CORR	LE_CORR_25	LE_CORR_75	
		LE_RANDUNC	H_F_MDS	H_F_MDS_QC	H_CORR	H_CORR_25	H_CORR_75	H_RANDUNC	
		NEE_VUT_REF	NEE_VUT_REF_QC	NEE_VUT_REF_RANDUNC	NEE_VUT_25	NEE_VUT_50	
		NEE_VUT_75	NEE_VUT_25_QC	NEE_VUT_50_QC	NEE_VUT_75_QC	RECO_NT_VUT_REF	
		RECO_NT_VUT_25	RECO_NT_VUT_50	RECO_NT_VUT_75	GPP_NT_VUT_REF	GPP_NT_VUT_25	
		GPP_NT_VUT_50	GPP_NT_VUT_75	RECO_DT_VUT_REF	RECO_DT_VUT_25	RECO_DT_VUT_50	
		RECO_DT_VUT_75	GPP_DT_VUT_REF	GPP_DT_VUT_25	GPP_DT_VUT_50	GPP_DT_VUT_75	
		RECO_SR	RECO_SR_N 8.;


		INPUT TIMESTAMP 	TA_F	TA_F_QC	SW_IN_POT	SW_IN_F	SW_IN_F_QC	
		LW_IN_F	LW_IN_F_QC	VPD_F	VPD_F_QC	PA_F	PA_F_QC	P_F	P_F_QC	WS_F	
		WS_F_QC	USTAR	USTAR_QC	NETRAD	NETRAD_QC	PPFD_IN	PPFD_IN_QC	CO2_F_MDS	
		CO2_F_MDS_QC	TS_F_MDS_1	TS_F_MDS_1_QC	SWC_F_MDS_1	SWC_F_MDS_1_QC	
		G_F_MDS	G_F_MDS_QC	LE_F_MDS	LE_F_MDS_QC	LE_CORR	LE_CORR_25	LE_CORR_75	
		LE_RANDUNC	H_F_MDS	H_F_MDS_QC	H_CORR	H_CORR_25	H_CORR_75	H_RANDUNC	
		NEE_VUT_REF	NEE_VUT_REF_QC	NEE_VUT_REF_RANDUNC	NEE_VUT_25	NEE_VUT_50	
		NEE_VUT_75	NEE_VUT_25_QC	NEE_VUT_50_QC	NEE_VUT_75_QC	RECO_NT_VUT_REF	
		RECO_NT_VUT_25	RECO_NT_VUT_50	RECO_NT_VUT_75	GPP_NT_VUT_REF	GPP_NT_VUT_25	
		GPP_NT_VUT_50	GPP_NT_VUT_75	RECO_DT_VUT_REF	RECO_DT_VUT_25	RECO_DT_VUT_50	
		RECO_DT_VUT_75	GPP_DT_VUT_REF	GPP_DT_VUT_25	GPP_DT_VUT_50	GPP_DT_VUT_75	
		RECO_SR	RECO_SR_N;

		if TA_F = -9999 then TA_F = .;
		if SW_IN_F = -9999 then SW_IN_F = .;
		if LW_IN_F = -9999 then LW_IN_F = .;
		if NETRAD = -9999 then NETRAD = .;
		if PPFD_IN = -9999 then PPFD_IN = .;
		if LE_CORR = -9999 then LE_CORR = .;
		if H_CORR = -9999 then H_CORR = .;
		if NEE_VUT_REF = -9999 then NEE_VUT_REF = .;
		if RECO_NT_VUT_REF = -9999 then RECO_NT_VUT_REF = .;
		if GPP_NT_VUT_REF = -9999 then GPP_NT_VUT_REF = .;
		if RECO_DT_VUT_REF = -9999 then RECO_DT_VUT_REF = .;
		if GPP_DT_VUT_REF = -9999 then GPP_DT_VUT_REF = .;
		if RECO_SR = -9999 then RECO_SR = .;


		yyyy=substr(timestamp,1,4);
		mmdd=substr(timestamp,5,4);
		mm = substr(timestamp,5,2);
		dd = substr(timestamp,7,2);

		if mm = '01' then doy = 0 + dd;
		if mm = '02' then doy = 31 + dd;
		if mm = '03' then doy = 31 + 28+ dd;
		if mm = '04' then doy = 31 + 28+ 31 + dd;
		if mm = '05' then doy = 31 + 28+ 31 + 30 + dd;
		if mm = '06' then doy = 31 + 28+ 31 + 30 + 31 + dd;
		if mm = '07' then doy = 31 + 28+ 31 + 30 + 31 + 30 + dd;
		if mm = '08' then doy = 31 + 28+ 31 + 30 + 31 + 30 + 31 + dd;
		if mm = '09' then doy = 31 + 28+ 31 + 30 + 31 + 30 + 31 + 31 + dd;
		if mm = '10' then doy = 31 + 28+ 31 + 30 + 31 + 30 + 31 + 31 + 30 + dd;
		if mm = '11' then doy = 31 + 28+ 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + dd;
		if mm = '12' then doy = 31 + 28+ 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + dd;

		if (yyyy = '2012' or yyyy = '2008' or yyyy = '2004' or yyyy= '2000' or yyyy = '1996'
			or yyyy = '1992') and (mm > '02') then doy =doy + 1;
		
		Keep File_name Timestamp yyyy doy  TA_F	SW_IN_F	LW_IN_F	VPD_F	NETRAD	PPFD_IN	LE_CORR
			H_CORR	NEE_VUT_REF	RECO_NT_VUT_REF	GPP_NT_VUT_REF	RECO_DT_VUT_REF
			GPP_DT_VUT_REF	RECO_SR;
run;

* sort the dataset - all datasets will be merged together later;
proc sort data=flux2015.&dsname;	
	by File_name TIMESTAMP;
run;

* merge this file with previously imported files;
data flux2015.&dsname_all;
	merge flux2015.&dsname_all
			flux2015.&dsname;
	by File_name TIMESTAMP;
run;


%mend import1file;

* get a list of all CSV file names in the directory;
data dirlist;
   infile dirlist lrecl=200 truncover;  /* dirlist is defined in the beginning of the program */
   input file_name $100.;
   	country =substr(file_name,5,2);
	site=substr(file_name,8,3);
	begin_year=substr(file_name,34,4);
	end_year=substr(file_name,39,4);
	/*dataset_name=country||"_"||site||"_"||begin_year||"_"||end_year;*/
	dataset_name=substr(file_name,5,2)||"_"||substr(file_name,8,3)||"_"||substr(file_name,34,4)||"_"||substr(file_name,39,4);
run;

* create Macro lists for variables;
proc sql noprint;
 select file_name, dataset_name
 into :filelist separated by ' ',
 :dslist separated by ' '
 from dirlist;
 quit;
%let dscntlist = &sqlobs; * Get a count of number of variables;
%put &filelist; 
%put &dslist; 
%put &dscntlist;

* This macro loops all file names to process one by one;
%macro allfiles;
	%do i=1 %to &dscntlist;
		%let filename=%scan(&filelist,&i,' ');
		%let dsname=%scan(&dslist,&i,' ');
		%put "Now Processing File: " &filename &dsname;
		* The main Macro that process each file;
		%import1file(filename=&filename,dsname=&dsname)
	%end;
%mend;
%allfiles

quit;

