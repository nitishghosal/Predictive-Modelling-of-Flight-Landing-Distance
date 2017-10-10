/*Import Dataset FAA1 */
PROC IMPORT OUT= WORK.FAA1 DATAFILE= "/home/ghosalnh0/statcomputing/FAA1.xls" 
           DBMS=xls REPLACE;
    SHEET="FAA1"; 
    GETNAMES=YES;
RUN;
/*Import Dataset FAA2*/
PROC IMPORT OUT= WORK.FAA2 DATAFILE= "/home/ghosalnh0/statcomputing/FAA2.xls" 
           DBMS=xls REPLACE;
    SHEET="FAA2"; 
    GETNAMES=YES;
RUN;

/*Merge the two datasets*/
DATA WORK.FAA;
SET WORK.FAA1 WORK.FAA2;
RUN;
PROC PRINT DATA = WORK.FAA;
RUN;

/*Summary statistics for the merged uncleaned dataset*/
PROC MEANS DATA = WORK.faa MIN MAX MEAN MEDIAN STD VAR RANGE;

PROC FREQ DATA = WORK.FAA;
TABLES AIRCRAFT/MISSING;

/*Removing duplicates from the combined dataset*/
PROC SORT DATA = WORK.FAA NODUPKEY OUT = WORK.FAA_UNIQUE;
BY AIRCRAFT NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH DISTANCE;
RUN;
PROC PRINT DATA = WORK.FAA_UNIQUE;
RUN;

/*Performing completeness check for the combined dataset*/
PROC MEANS DATA = WORK.faa_unique N NMISS MIN MAX MEAN MEDIAN STD VAR RANGE;

PROC FREQ DATA = WORK.FAA_UNIQUE;
TABLES AIRCRAFT/MISSING;

data FAA;
SET WORK.FAA_UNIQUE;
IF AIRCRAFT="" THEN DELETE;
IF HEIGHT < 0 THEN DELETE ;
PROC PRINT DATA = WORK.FAA_UNIQUE;
RUN;

/*Removing Abnormal Values*/
DATA FAA_NORMAL;
SET FAA;
IF HEIGHT < 6 THEN DELETE;
IF DISTANCE > 6000 THEN DELETE ; 
IF DURATION < 40 AND DURATION ~= . THEN DELETE;
IF SPEED_GROUND < 30 OR SPEED_GROUND > 140 THEN DELETE;
IF (SPEED_AIR < 30 OR SPEED_AIR > 140) AND SPEED_AIR ~= . THEN DELETE ;
 
PROC PRINT DATA = FAA_NORMAL;
RUN;

/*Summarize the statistics for the clean data*/
PROC MEANS DATA = FAA_NORMAL N NMISS MIN MAX MEAN MEDIAN STD VAR RANGE;

PROC FREQ DATA = FAA_NORMAL;
TABLES AIRCRAFT/MISSING;

PROC UNIVARIATE DATA=FAA_NORMAL PLOT;
RUN; 

/*Data Visualization*/

PROC PLOT DATA = FAA_Normal;
plot distance*speed_air='*';
plot distance*duration='&';
plot distance*no_pasg='#';
plot distance*speed_ground='@';
plot distance*height='!';
plot distance*pitch='$';

/*Transformation of speed ground to improve linear relationship with distance*/
DATA FAA_NORMAL1;
set faa_normal;
speed_ground1 = (speed_ground)**2;

PROC PLOT DATA = FAA_NORMAL1;
PLOT DISTANCE*SPEED_GROUND1='%';
plot distance*speed_ground='@';

/*Transfroming categorical column Aircraft from non-numeric to binary*/
DATA FAA_Final;
SET FAA_Normal1;
IF aircraft = 'boeing' then aircraft_make = 1;
ELSE aircraft_make = 0;
PROC PRINT DATA = FAA_Final;
RUN;
 
/* Using scatter plot to identify the relation among different variables */
PROC SGSCATTER DATA=FAA_Final;
MATRIX distance aircraft_make speed_air speed_ground height pitch duration no_pasg speed_ground1 ;
RUN;

/* Using box plot to identify the relation of distance with aircraft make*/
PROC SORT DATA=FAA_Final;
BY AIRCRAFT;
run;

PROC BOXPLOT DATA=FAA_Final;
PLOT DISTANCE*AIRCRAFT/
       nohlabel
       boxstyle      = schematic
       boxwidthscale = 1
       bwslegend;
run;

/*Correlation Coefficient*/

PROC CORR DATA = FAA_Final;
VAR distance duration no_pasg speed_ground speed_air height pitch aircraft_make speed_ground1;
title Correlaiton coefficients matrix;
run;

/*Regression Model*/
proc reg data=FAA_Final;
model distance = duration no_pasg speed_ground speed_air height pitch aircraft_make speed_ground1;
title Regression analysis of the Aircraft Dataset;
run;

proc reg data=FAA_Final;
model distance = speed_ground height aircraft_make;
title Regression analysis of the Aircraft Dataset;
run;

/*Final Model*/
proc reg data=FAA_Final;
model distance = speed_ground1 height aircraft_make;
title Regression analysis of the Aircraft Dataset;
run;

/*GLM test*/
proc glm data = FAA_Final;
class aircraft;
model distance = speed_ground height aircraft_make;

/*T-test*/
proc ttest data = FAA_Final;
class aircraft;
VAR distance;



