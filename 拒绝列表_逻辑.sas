/*option validvarname=any;*/
/*option compress=yes;*/
/**/
/*libname appfin  "F:\A_offline_zky\A_offline\daily\Daily_MTD_Acquisition\dta";*/


data a;
format dt yymmdd10.;
dt=today()-1;
dt1=put(dt,yymmdd10.);
last_month=substr(dt1,1,4)||substr(dt1,6,2);
call symput("last_month",last_month);
run;

data aaa;
set appfin.Daily_acquisition_;
if �����·�="&last_month.";
if �ܾ�=1;
if ����״̬^="BACK";
keep apply_code product_code check_date NAME Ӫҵ�� created_name_final SALES_NAME REFUSE_INFO_NAME_LEVEL2 REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME ����״̬ �ڲ����;
rename apply_code=������� NAME=�ͻ�����  product_code=��Ʒ created_name_final=�������� SALES_NAME=�������� REFUSE_INFO_NAME_LEVEL1=�ܾ�ԭ��һ�� REFUSE_INFO_NAME_LEVEL2=�ܾ�ԭ����� REFUSE_INFO_NAME=�ܾ�ԭ������ ;
run;

proc sort data=aaa;by check_date;run;

data aaa;
retain ������� �ͻ����� Ӫҵ�� ��Ʒ  �������� �������� check_date ����״̬ �ܾ�ԭ��һ�� �ܾ�ԭ�����  �ܾ�ԭ������ �ڲ����;
set aaa;
run;


/*PROC EXPORT DATA=aaa*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ܾ��б�\�ܾ��б�.xls" DBMS=EXCEL REPLACE;SHEET="�ܾ��б�"; RUN;*/
