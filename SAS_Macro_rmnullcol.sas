/*----------------------------------------------------------
Institution: Department of Epidemiology, 
			 School of Public Health, 
			 the Key Laboratory on Public Health Safety, 
			 Ministry of Education, 
			 Fudan University, 
			 Shanghai, China

Author: Wei Fan

Creation Date: 2018/08/04

Test System: Windows 8 64 bit

Required Packages/Modules: None

SAS Edition: SAS University Edition

Program Propeties: SAS Macro (Macro name: rmnullcol)

Program Description: This Program aims to eliminate all the
	null columns with nothing from a given dataset.
	The processed data will be renamed as
	<Original name of the dataset>_final and kept in WORK.

Function of the parameters in this macro:
	(1) templib: To specify a temporary library to store the
		dataset from a given path.
	(2) location: To specify the exact path of the dataset. 
		The value should be enclosed in double quotes. 
		For example, "D:\Documents\Workshop\SAS Temp".
	(3) dataset: To specify the name of the dataset that 
		needs to be processed.
----------------------------------------------------------*/

/*dm "output;clear;log;clear";*/

option nomprint;
option nospool;

%macro rmnullcol(templib=temp,location="D:\Documents\Workshop\SAS Temp",dataset=);

	libname &templib. &location.;

	data &dataset.;
		set &templib.&dataset.;
	run;

	proc sql noprint;
		select distinct NAME into: char_var separated by " "
			from dictionary.columns
			where LIBNAME='WORK' and MEMNAME=upcase("&datset.") and upcase(TYPE)='CHAR';
		select distinct NAME into: num_var separated by " "
			from dictionary.columns
			where LIBNAME='WORK' and MEMNAME=upcase("&datset.") and upcase(TYPE)='NUM';
		select distinct NAME into: varlist separated by " "
			from dictionary.columns
			where LIBNAME='WORK' and MEMNAME=upcase("&datset.");
	quit;

	%put &char_var;
	%put &num_var;
	%put &varlist;

	%let n_char=%sysfunc(countw(&char_var));
	%let n_num=%sysfunc(countw(&num_var));
	%let n_all=%sysfunc(countw(&varlist));

	%put &n_char.;
	%put &n_num.;
	%put &n_all.;

	data &dataset._temp;
		set &dataset.;
		do i=1 to _N_;
			%do j=1 %to &n_char.;
				%let char&j=%scan(&char_var.,&j.);
				length &&char&j.._CATS $200.;
				&&char&j.._CATS=cats(&&char&j.._CATS,&&char&j);
			%end;
			%do k=1 %to &n_num.;
				%let num&k=%scan(&num_var.,&k.);
				length &&num&k.._CATS $200.;
				&&num&k.._CATS=compress(cats(&&num&k.._CATS,&&num&k),".");
			%end;
		end;
	run;
	data &dataset._out;
		set &dataset._temp end=eof;
		if eof then output;
	run;
	proc sql noprint;
		select NAME into: cats_var separated by " "
		from dictionary.columns
		where LIBNAME='WORK' and MEMNAME=upcase("&dataset._out") and prxmatch("/_CATS$/i",cats(NAME));
	quit;
	%put &cats_var.;
	
	
	data &dataset._temp2;
		set &dataset._out;
		length VARNAME $200.;
		%do p=1 %to &n_all.;
			%let cat&p.=%scan(&cats_var.,&p.);
			if missing(&&cat&p) then do;
				VARNAME=upcase("&&cat&p");
				VARNAME_RAW=prxchange("s/_CATS//",-1,VARNAME);
				output;
			end;
		%end;
		keep VARNAME VARNAME_RAW;
	run;

	proc sql noprint;
		select distinct VARNAME_RAW into: drop_var separated by ' '
		from &dataset._temp2;
	quit;

	data &dataset._final;
		set &dataset.;
		drop &drop_var.;
	run;
%mend rmnullcol;

*%rmnullcol(dataset=che);
