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
if 批核月份="&last_month.";
if 拒绝=1;
if 批核状态^="BACK";
keep apply_code product_code check_date NAME 营业部 created_name_final SALES_NAME REFUSE_INFO_NAME_LEVEL2 REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME 批核状态 内部意见;
rename apply_code=申请编码 NAME=客户姓名  product_code=产品 created_name_final=终审姓名 SALES_NAME=销售姓名 REFUSE_INFO_NAME_LEVEL1=拒绝原因一级 REFUSE_INFO_NAME_LEVEL2=拒绝原因二级 REFUSE_INFO_NAME=拒绝原因三级 ;
run;

proc sort data=aaa;by check_date;run;

data aaa;
retain 申请编码 客户姓名 营业部 产品  终审姓名 销售姓名 check_date 批核状态 拒绝原因一级 拒绝原因二级  拒绝原因三级 内部意见;
set aaa;
run;


/*PROC EXPORT DATA=aaa*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\拒绝列表\拒绝列表.xls" DBMS=EXCEL REPLACE;SHEET="拒绝列表"; RUN;*/
