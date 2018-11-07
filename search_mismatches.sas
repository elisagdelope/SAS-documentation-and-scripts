/* Script that finds observations of table A that are not present in table B. In this example table A=work.allbbddtables and B=work.resumtotal. */
proc sql ;
	create table error as
	select * 
	from work.all_bbddtables as s
	where s.memname not in (select distinct memname from work.resumtotal);
quit;