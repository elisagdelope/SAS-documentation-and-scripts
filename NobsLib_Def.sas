/*  Number of variables and observations of the tables of a library  */

OPTIONS SYMBOLGEN MLOGIC MPRINT;

*  DDBB object of study;
%LET BBDD=DSCQ;

*  Macro to compare table by table of the DDBB;
%MACRO OBSTAB(TABLA, NVAR, TYPE);

	%if &TYPE. EQ VIEW && %substr(&tabla., 4, 1) in (Q,H,Z) %then %do;
		* Si se trata de una vista diaria o histórica, sacamos los datos completos;
		proc sql noprint;
		select count(*) into :nobs
		from &bbdd..&tabla.;
	  	QUIT;
  	%end;
	%else %if &TYPE. EQ VIEW && not(%substr(&tabla., 4, 1) in (Q,H,Z)) %then %do;
		* Para vistas mensuales cogemos solo los datos del último período;
		proc sql noprint;
			select count(*) into :nobs
			from &bbdd..&tabla.
			where IDT_PDE_MES = &IPMCIVCLO.;
		QUIT;
	%END;
  	%else %do;
		* En el caso de ser una tabla SAS;
	  	* Abrimos las características de la tabla;
	  	%LOCAL DSID=%SYSFUNC(OPEN(&bbdd..&tabla.,IN));
	  	* Guardamos el número de observaciones;
	  	%LOCAL NOBS=%SYSFUNC(ATTRN(&DSID,NOBS));
		* Cerramos;
	  	%LOCAL RC=%SYSFUNC(CLOSE(&DSID));  
  	%end;

	DATA RESUMEN;
 		LENGTH TABLA $40.;
    	TABLA="&bbdd..&TABLA.";
		VARIABLES=&NVAR.;
		OBSERVACIONES=&NOBS.;
  	RUN;

  	PROC APPEND BASE=RESUM_TOT DATA=RESUMEN;
  	RUN;

%MEND;

/*  Macro to loop over all tables existing in the DDBB  */
%MACRO LIST_TABLAS;

	%DO X = 1 %TO &NUMTABS.;
		%OBSTAB(&&TABLA&X., &&NVARS&X., &&TYPE&X.);
  	%END;

%MEND;

* Delete data in appending table so that it is clean by the script start;
PROC DELETE DATA=RESUM_TOT;
RUN;


/********************  Program starts  *********************/

PROC SQL noprint;
  CREATE TABLE TABLAS AS
    SELECT LIBNAME, MEMNAME, NVAR, TYPEMEM
	FROM SASHELP.VTABLE
	WHERE LIBNAME = "&BBDD." AND SUBSTR(MEMNAME, length(memname)-4, 5) NE '_CPAR';
QUIT;

DATA _NULL_;
  	SET TABLAS NOBS=Z; 
	CALL SYMPUT('NUMTABS', COMPRESS(Z));
  	*  Recogemos los nombres de las tablas que necesitamos;
  	CALL SYMPUT(COMPRESS('TABLA'||_N_),MEMNAME);
  	CALL SYMPUT(COMPRESS('NVARS'||_N_),NVAR);
	CALL SYMPUT(COMPRESS('TYPE'||_N_),TYPEMEM);
RUN;

* List of tables;
%LIST_TABLAS;

title Number of variables and observations of the tables in library &&BBDD.;
PROC PRINT DATA=RESUM_TOT;
RUN;

title;