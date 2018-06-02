PROC IMPORT OUT= WORK.event 
            DATAFILE= "F:\rumor\eventstudy.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
