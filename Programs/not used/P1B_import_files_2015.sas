TITLE1 'Flux Daily Files';
LIBNAME flux2015 'C:\Users\tnsongbr\Google Drive\Phenoflux_work\2015';

%Let flxdailydir = C:\Users\tnsongbr\Google Drive\Phenoflux_fluxdata\FLUXNET_2015_Daily;

title2 "&filename";


/* This program is to import files. */
/* Date: 11/2/2016       By: TS                             */

%MACRO Import1file(filename=,dsname=);

/* import file &filename */
data flux2015.&dsname;
	INFILE "&flxdailydir\&filename..csv" 
		DLM = ',' MISSOVER DSD FIRSTOBS = 2 LRECL = 100000;

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
		
		Keep Timestamp yyyy doy  TA_F	SW_IN_F	LW_IN_F	VPD_F	NETRAD	PPFD_IN	LE_CORR
			H_CORR	NEE_VUT_REF	RECO_NT_VUT_REF	GPP_NT_VUT_REF	RECO_DT_VUT_REF
			GPP_DT_VUT_REF	RECO_SR;
run;

%mend import1file;
/*
PROC CONTENTS DATA =flxdaily.&dsname; 
RUN;
*/

/* Create the overlay plots by year */
/*symbol1 font=marker v=C   c=vibg  i=none h=1;
symbol2 font=marker v=S   c=depk  i=none h=1;
symbol3             v=dot c=mob   i=none h=1;

axis1 order=(1 to 366 by 30) offset=(1,1)                                                                                            
      label=none minor=(n=10); 
*/
/* Define legend options */                                                                                                             
/*legend1 position=(top center inside)                                                                                                    
        label=none                                                                                                                      
        mode=share;
*/
/*
title3 'TA_F by doy';
proc gplot data=flxdaily.&dsname;  
   plot TA_F*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;                                                                                                                                    


title3 'SW_IN_F by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot SW_IN_F*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                           
run;                                                                                                                                    


title3 'LW_IN_F by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot LW_IN_F*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;   

title3 'VPD_F by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot VPD_F*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'NETRAD	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot NETRAD	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'PPFD_IN	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot PPFD_IN	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'LE_CORR by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot LE_CORR*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'H_CORR	 by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot H_CORR	*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'NEE_VUT_REF by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot NEE_VUT_REF*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'RECO_NT_VUT_REF by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot RECO_NT_VUT_REF*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'GPP_NT_VUT_REF by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot GPP_NT_VUT_REF*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'RECO_DT_VUT_REF by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot RECO_DT_VUT_REF*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'GPP_DT_VUT_REF by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot GPP_DT_VUT_REF*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run; 

title3 'RECO_SR by doy';
proc gplot data=flxdaily.&dsname;                                                                                                                 
   plot RECO_SR*doy =yyyy /haxis=axis1                                                                                                  
                            legend=legend1;                                                                                           
                                                                                                             
run;
*/


/* Create a temporary dataset to store all file names */
/* We can also import a file that has variable names. */
data flux2015.filelist;
	 INFILE DATALINES DLM=','; 
		input filename  $50.;
	datalines;
FLX_AR-SLu_FLUXNET2015_SUBSET_DD_2009-2011_1-2
FLX_AR-Vir_FLUXNET2015_SUBSET_DD_2009-2012_1-2
FLX_AT-Neu_FLUXNET2015_SUBSET_DD_2002-2012_1-2
FLX_AU-Ade_FLUXNET2015_SUBSET_DD_2007-2009_1-2
FLX_AU-ASM_FLUXNET2015_SUBSET_DD_2010-2013_1-2
;
run;
/* Generate dataset names */
data flux2015.filelist;
	set flux2015.filelist;
	length country $2. site $3. begin_year $4. end_year $4.;
	country =substr(filename,5,2);
	site=substr(filename,8,3);
	begin_year=substr(filename,34,4);
	end_year=substr(filename,39,4);
	dsname=country||"_"||site||"_"||begin_year||"_"||end_year;
	/*dsname=substr(filename,5,2)||"_"||substr(filename,8,3)||"_"||substr(filename,34,4)||"_"||substr(filename,39,4);*/
run;

* create Macro lists for variables;
proc sql noprint;
 select filename, dsname
 into :filelist separated by ' ',
 :dslist separated by ' '
 from flux2015.filelist;
 quit;
%let cntlist = &sqlobs; * Get a count of number of variables;
%put &filelist; 
%put &dslist; 
%put &cntlist;

* This macro loops all Variables to process one by one;
%macro allfiles;
	%do i=1 %to &cntlist;
		%let filename=%scan(&filelist,&i,' ');
		%let dsname=%scan(&dslist,&i,' ');
		%put "Now Processing Variable: " &filename &dsname;
		* The main Macro that process on Variable level;
		%import1file(filename=&filename,dsname=&dsname)
	%end;
%mend;
%allfiles


quit;
