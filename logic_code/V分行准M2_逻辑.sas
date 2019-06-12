/*option compress=yes validvarname=any;*/
/*libname approval "F:\A_offline_zky\kangyi\data_download\ԭ��\approval";*/
/*/*libname repayfin "F:\A_offline_zky\A_offline\daily\�ռ��\��ʷ����\��ʷ��������\201812";*/*/
/*/*��ͬ�·�ʹ�ò�ͬ�ġ�payment_daily��*/*/
/*libname repayfin "F:\A_offline_zky\kangyi\data_download\�м��\repayAnalysis";*/
/**/
/**��2018��08��֮ǰϵͳ��û����ǩ�����9��֮��ź�����8�µ������·�������excel;*/
/*PROC IMPORT OUT= Vfenhang_a*/
/*            DATAFILE= "F:\A_offline_zky\A_offline\daily\V����׼M2\V����ǩԼ�ſ����1705-1808.xlsx" */
/*            DBMS=EXCEL REPLACE;*/
/*     GETNAMES=YES;*/
/*     MIXED=NO;*/
/*     SCANTEXT=YES;*/
/*     USEDATE=YES;*/
/*     SCANTIME=YES;*/
/*RUN;*/
/*libname zq "F:\A_offline_zky\A_offline\daily\�ռ��\finData";*/;
/*libname appfin "F:\A_offline_zky\A_offline\daily\Daily_MTD_Acquisition\dta";*/

data aa;
format dt yymmdd10.;
dt = today() - 1;
call symput("dt", dt);
dtt=put(dt,yymmdd10.);
call symput("dtt", dtt);
week = weekday(dt);
call symput('week',week);
run;


data vfenhang_a_;
set vfenhang_a;
���뵥��1=compress(���뵥��,,"s");
contract_no = tranwrd( ���뵥��1, "PL","C");
keep contract_no ǩԼ�ͷ� ;
run;

data vfenhang_b;
set approval.sign_appointment_record;
contract_no = tranwrd(apply_code, "PL","C");
if APPOINTMENT_TIME>=mdy(9,1,2018);*�м���8�µĵ�������ȫ������8�»��������·�������ǩԼ�ͻ�;
if ASSIGN_USER_LOGIN_NAME="chenwenying" then ǩԼ�ͷ�="����Ө";
else if ASSIGN_USER_LOGIN_NAME="dujuan" then ǩԼ�ͷ�="�ž�";
else if ASSIGN_USER_LOGIN_NAME="fangyanjuan" then ǩԼ�ͷ�="���޾�";
else if ASSIGN_USER_LOGIN_NAME="gupingping" then ǩԼ�ͷ�="��ƼƼ";
else if ASSIGN_USER_LOGIN_NAME="huangxiulin" then ǩԼ�ͷ�="������";
else if ASSIGN_USER_LOGIN_NAME="liuyuan" then ǩԼ�ͷ�="����";
else if ASSIGN_USER_LOGIN_NAME="shaohuihui" then ǩԼ�ͷ�="�ۻԻ�";
else if ASSIGN_USER_LOGIN_NAME="wuyuanting" then ǩԼ�ͷ�="��Է��";
else if ASSIGN_USER_LOGIN_NAME="wuchengchun" then ǩԼ�ͷ�="��ɴ�";
else if ASSIGN_USER_LOGIN_NAME="xiaduoyi" then ǩԼ�ͷ�="�Ķ���";
else if ASSIGN_USER_LOGIN_NAME="xiepeina" then ǩԼ�ͷ�="л����";
else if ASSIGN_USER_LOGIN_NAME="xumaosi" then ǩԼ�ͷ�="��ï˼";
else if ASSIGN_USER_LOGIN_NAME="zhanghui" then ǩԼ�ͷ�="�Ż�";
else ǩԼ�ͷ�=ASSIGN_USER_LOGIN_NAME;
keep  contract_no ǩԼ�ͷ�;
run;

data vfenhang;
set vfenhang_a_ vfenhang_b;
*song��;
if contract_no^="C2018101613583597025048";
*song��;
run;

proc sort data=vfenhang;by ǩԼ�ͷ� contract_no;run;

proc sql;
create table vfenhang1 as
select a.*,b.*
from vfenhang as a
left join repayfin.payment_daily(where=(cut_date=&dt. and Ӫҵ��^="APP")) as b
on a.contract_no=b.contract_no;
quit;
proc sort data =vfenhang1  ;by contract_no;run;
data vfenhang1_;
set vfenhang1;

keep �ͻ����� ǩԼ�ͷ� contract_no Ӫҵ�� �ſ����� �������_2��ǰ_C  ����_M1M2������� od_days;
run;
/*δ�ſ��ſ��������*/
data aa1;
set vfenhang1;
if �ʽ�����="";
keep �ͻ����� ǩԼ�ͷ� contract_no;
run;

*"""
/*Ϊ��ȡ�ѻ�����*/;
data aa2;
set vfenhang1;
if �ʽ�����^="";
format ��ʼ��������   yymmdd10.;
if od_days>0 then do;
��ʼ��������=intnx("day",cut_date,-od_days,"same");
end;
apply_code = tranwrd(contract_no , "C","PL");
keep �ͻ����� ǩԼ�ͷ� apply_code contract_no Ӫҵ�� �ſ����� �������_2��ǰ_C  ����_M1M2������� od_days od_periods ;
run;



/*��ǰ����*/
data aa21;
set zq.bill_main;
if repay_date<=&dt.;
run;
proc sql;
create table aa21_ as
select contract_no,
count(contract_no) as ��ǰ����
from aa21
group by contract_no;
quit;

data aa41;
set repayfin.Tttrepay_plan_js;
if repay_date_js<=&dt.;
run;
proc sql;
create table aa41_ as
select contract_no,
count(contract_no) as ��ǰ����
from aa41
group by contract_no;
quit;
data aa51;
set aa21_  aa41_;
apply_code = tranwrd(contract_no , "C","PL");
run;
proc sort data=aa51 nodupkey out=aa51_;by contract_no;run;



proc sql;
create table aa11 as
select a.*,c.��ǰ����
from aa2 as a
left join appfin.Daily_acquisition_ as b on a.apply_code=b.apply_code
left join aa51 as c on a.apply_code=c.apply_code;
quit;

/*��ĸ��*/
data aa61;
set aa11;
if od_periods="." then od_periods=0;
�ѻ����� = ��ǰ���� - od_periods;
format loan_date yymmdd10.;
loan_date=mdy(scan(�ſ�����,2,"-"), scan(�ſ�����,3,"-"),scan(�ſ�����,1,"-"));
keep �ͻ����� ǩԼ�ͷ� contract_no Ӫҵ�� od_days loan_date �������_2��ǰ_C ����_M1M2������� ��ǰ���� �ѻ�����;
run;
/*���ӱ�*/
data aa61_;
set aa61;
if ����_M1M2�������>0;
run;

*""";

proc sql;
create table vfenhang2 as
select ǩԼ�ͷ�,sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(����_M1M2�������) as ����_M1M2�������,
	   SUM(����_M1M2�������)/SUM(�������_2��ǰ_C) as Ԥ��C_M2 format=percent7.2

from vfenhang1
group by ǩԼ�ͷ�;quit;


proc sql;
create table vfenhang3 as
select sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(����_M1M2�������) as ����_M1M2�������,
	   SUM(����_M1M2�������)/SUM(�������_2��ǰ_C) as Ԥ��C_M2 format=percent7.2
from vfenhang1;quit;

data vfenhang4;
set vfenhang2 vfenhang3;
if ǩԼ�ͷ�="" then ǩԼ�ͷ�="V����";
run;

/*5��3����V���г�����ʱ�䣬��Ҫ�Ƚ�V���г���֮��������
��ΪҪ���ŵ��Ǳߵ�C-M2���������ȫ���ģ�����V���еľ����ŵ��*/
data payment_daily1;
set repayfin.payment_daily;
format loan_date yymmdd10.;
loan_date=mdy(scan(�ſ�����,2,"-"), scan(�ſ�����,3,"-"),scan(�ſ�����,1,"-"));
if loan_date>=mdy(5,3,2017);
run;

proc sql;
create table zong as
select sum(�������_2��ǰ_C) as �������_2��ǰ_C, SUM(����_M1M2�������) as ����_M1M2�������,
	   SUM(����_M1M2�������)/SUM(�������_2��ǰ_C) as Ԥ��C_M2 format=percent7.2
from payment_daily1(where=(cut_date=&dt. and Ӫҵ��^="APP"  ));quit;

data zong1;
set vfenhang4 zong ;
if ǩԼ�ͷ�="" then ǩԼ�ͷ�="ȫ��";
run;



/*PROC EXPORT DATA=zong1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V����׼M2\V����c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="C_M2"; RUN;*/
/*PROC EXPORT DATA=aa61*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V����׼M2\V����c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="��ĸ�ܱ�"; RUN;*/
/*PROC EXPORT DATA=aa61_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V����׼M2\V����c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="׼M2��ϸ��"; RUN;*/
/*PROC EXPORT DATA=aa1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\V����׼M2\V����c_m2_&dtt..xls" DBMS=EXCEL REPLACE;SHEET="δ�ſ��ſ�����ϸ"; RUN;*/

/*��ע ����Ҫ�ֶ���һ���ŵ�Ĵ������_2��ǰ_C������_M1M2�������;
�߼����� ȫ�� - V���� = �ŵ�*/
