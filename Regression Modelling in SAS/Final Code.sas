/*Importing file 1*/
PROC IMPORT OUT=FirstDataSet 
		DATAFILE='~/Stat computing class/Stat Comp Project/FAA1' DBMS=xls REPLACE;
	SHEET="FAA1";
	GETNAMES=YES;
RUN;

/*Importing file 2*/
PROC IMPORT OUT=SecondDataSet 
		DATAFILE='~/Stat computing class/Stat Comp Project/FAA2' DBMS=xls REPLACE;
	SHEET="FAA2";
	GETNAMES=YES;
RUN;

/*Appending both files into a single dataset*/
DATA FAA1FAA2COMBINED;
	SET FirstDataSet SecondDataSet;
RUN;

/*Summarizing the distribution of each variable*/
PROC MEANS DATA=FAA1FAA2COMBINED N MEAN MEDIAN STD RANGE NMISS;
	/*TITLE'SUMMARY STATS OF COMBINED UNCLEAN DATASET';*/
	VAR DURATION;
	VAR NO_PASG;
	VAR SPEED_GROUND;
	VAR SPEED_AIR;
	VAR HEIGHT;
	VAR PITCH;
	VAR DISTANCE;
	;
RUN;

/* Finding and removing duplicates from the combined set*/
PROC SORT data=FAA1FAA2COMBINED NODUPKEY;
	BY aircraft duration no_pasg;
RUN;

DATA TEST1;
	SET FAA1FAA2COMBINED;

	/* Counting the missing values in all columns*/
	count=nmiss(OF DURATION NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH DISTANCE);

	if count<7;

	/*To avoid choosing rows where all columns are blank*/
	/* Check to see if dataset contains any Invalid characters removing those values in final data set*/
	IF AIRCRAFT NOT IN ('BOEING' , 'AIRBUS');

	IF VERIFY(DURATION, '0123456789');

	IF VERIFY(NO_PASG, '0123456789');

	IF VERIFY(SPEED_GROUND, '0123456789');

	IF VERIFY(SPEED_AIR, '0123456789');

	IF VERIFY(HEIGHT, '0123456789');

	IF VERIFY(PITCH, '0123456789');

	IF VERIFY(DISTANCE, '0123456789');
RUN;

/* Since Duration and Speed_air contain alot of missing values
understanding the distribution of these two columns to decide whether to exclude these columns or not	*/
PROC UNIVARIATE DATA=TEST1;
	VAR DURATION;
	HISTOGRAM DURATION / NORMAL;

	/* HISTOGRAM variables / <OPTIONS> */
	VAR SPEED_AIR;
	HISTOGRAM SPEED_AIR / NORMAL;

	/* HISTOGRAM variables / <OPTIONS> */
Run;

/*Since the two columns have normal and right-skewed distribution, we cannot omit these.
Hence, replacing all missing values with MEDIAN*/
proc stdize data=TEST1 out=NEW1 MISSING=median reponly;
	VAR DURATION;
	VAR NO_PASG;
	VAR SPEED_GROUND;
	VAR SPEED_AIR;
	VAR HEIGHT;
	VAR PITCH;
	VAR DISTANCE;
run;

/* To check outliers for each columns with give specifications*/
DATA NEW2;
	SET NEW1;

	IF DURATION <=40 THEN
		Outlier='Present';
	else
		Outlier="Not present";

	IF SPEED_GROUND <=30 OR SPEED_GROUND>=140 THEN
		Outlier='Present';
	else
		Outlier="Not present";

	IF SPEED_AIR <=30 OR SPEED_AIR>=140 THEN
		Outlier='Present';
	else
		Outlier="Not present";

	IF HEIGHT < 6 THEN
		Outlier='Present';
	else
		Outlier="Not present";
	;
RUN;

DATA FINALCOMBINEDDATA;
	SET NEW2;

	/* Referencing to cancatinated data set*/
	/* Labelling all given columns*/
	LABEL AIRCRAFT='AIRCRAFT';
	LABEL DURATION='DURATION';
	LABEL NO_PASG='NO. OF PASSENGERS';
	LABEL SPEED_GROUND='SPEED ON GROUND';
	LABEL SPEED_AIR='SPEED IN AIR';
	LABEL HEIGHT='HEIGHT';
	LABEL PITCH='PITCH';
	LABEL DISTANCE='DISTANCE';
	;
RUN;

proc print data=FINALCOMBINEDDATA(obs=10);
	title 'FIRST 10 OBSERVATIONS OF DATASET';
RUN;

/*Summarizing the distribution of each variable*/
PROC MEANS DATA=FINALCOMBINEDDATA N MEAN MEDIAN STD RANGE NMISS;
	TITLE'SUMMARY STATS OF COMBINED DATASET AFTER COMPLETING DATA PREPARATION OPERATIONS';
	VAR DURATION;
	VAR NO_PASG;
	VAR SPEED_GROUND;
	VAR SPEED_AIR;
	VAR HEIGHT;
	VAR PITCH;
	VAR DISTANCE;
RUN;

/*CODING AIRBUS=1 AND BOEING=0*/
DATA TESTING;
	SET finalcombineddata;
	LABEL CODING='AIRCRAFT';

	IF AIRCRAFT='airbus' THEN
		CODING=1;
	ELSE if AIRCRAFT='boeing' THEN
		CODING=0;
RUN;

/*PROC PRINT DATA= TESTING;
RUN;*/
/* PLOTS OF LANDING DISTANCE WITH EACH OF OTHER VARIABLES*/
proc plot data=FINALCOMBINEDDATA;
	title 'BASIC PLOTS TO IDENTIFY ANY RELATIONSHIP AMONG VARIABLES';

	/*PLOT OF DEPENDENT VARIABLE WITH ALL OTHER VARIABLES*/
	plot DISTANCE*AIRCRAFT;
	plot DISTANCE*DURATION;
	plot DISTANCE*NO_PASG;
	plot DISTANCE*SPEED_GROUND;
	plot DISTANCE*SPEED_AIR;
	plot DISTANCE*HEIGHT;
	plot DISTANCE*PITCH;

	/*PLOTTING DEPENDENT VARIABLES WITH EACH OTHER TO SEE IF THERE IS ANY CONNECTION*/
	plot SPEED_GROUND*SPEED_AIR;

	/*plot HEIGHT*PITCH;
	plot DURATION*SPEED_AIR;
	plot SPEED_GROUND*PITCH;
	plot HEIGHT*SPEED_AIR; */
	run;

	/* IDENTIFYING IF THERE IS ANY CORRELATION BETWEEN THE VARIABLES*/
proc corr data=FINALCOMBINEDDATA;
	var DISTANCE DURATION NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH;
	title 'PAIRWISE CORRELATION';
run;

/* Performing Regression analysis for all variables*/
PROC REG DATA=TESTING;
	MODEL DISTANCE=CODING DURATION NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH / 
		VIF;
	title 'REGRESSION ANALYSIS INCLUDING ALL VARIABLES';
	run;

	/* Performing Regression analysis for remaining variables to test multicollinearity*/
PROC REG DATA=TESTING;
	MODEL DISTANCE=CODING SPEED_GROUND SPEED_AIR HEIGHT / VIF;
	title 'REGRESSION ANALYSIS FOR REMAINING VARIABLES TO TEST MULTICOLLINEARITY';
	run;
	
	
	
DATA TESTINGNEW;
	SET TESTING;
	/*DO I=1 TO 851;*/
	LANDINGDISTANCE = -6954.39 - (498.24 * CODING) + (36.06 * Speed_Ground) + (52.99*Speed_Air) + (14.71*Height);
	/*FIELD2 = -6954.39 + (36.06 * Speed_Ground) + (52.99*Speed_Air) + (14.71*Height);*/
	/*OUTPUT;
	END;*/
RUN;

/*
PROC PRINT DATA=TESTINGNEW;
RUN;
*/


title 'Box Plot';
proc boxplot data=TESTINGNEW ;
   plot LANDINGDISTANCE*AIRCRAFT;
   inset min mean max stddev /
      header = 'Overall Statistics'
      pos    = tm;
   insetgroup  mean ; 
      
run;

PROC MEANS DATA=TESTINGNEW N MEAN MEDIAN STD RANGE ;
	by  descending coding;
	var LANDINGDISTANCE;
run;