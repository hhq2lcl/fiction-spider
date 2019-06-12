*Ctl_task_assign�е�status;
*0��δ����
*1��ÿ���°���
*2�������е�����
*3�����������
*-1��������������Ѿ��ر�
*-2:�����Ѿ��رգ������ѱ�����;


/*option compress = yes validvarname = any;*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\ԭ��\res';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\ԭ��\csdata';*/
/*libname account 'F:\A_offline_zky\kangyi\data_download\ԭ��\account';*/
/*libname repayfin 'F:\A_offline_zky\kangyi\data_download\�м��\repayAnalysis';*/
/*libname zq "F:\A_offline_zky\A_offline\daily\�ռ��\finData";*/
/*libname cd "F:\A_offline_zky\A_offline\weekly\V���������ձ�\chengdu_data";*v��������һ����Ҫ;*/


data _null_;
format date  start_date  fk_month_begin month_begin  end_date last_month_end last_month_begin month_end yymmdd10.;*����ʱ�������ʽ;
if day(today())=1 then date=intnx("month",today(),-1,"end");
else date=today()-1;
/*date = mdy(12,31,2017);*/
call symput("tabledate",date);*����һ����;
start_date = intnx("month",date,-2,"b");
call symput("start_date",start_date);
month_begin=intnx("month",date,0,"b");
call symput("month_begin",month_begin);
month_end=intnx("month",date,1,"b")-1;
call symput("month_end",month_end);
last_month_end=intnx("month",date,0,"b")-1;
call symput("last_month_end",last_month_end);
last_month_begin=intnx("month",date,-1,"b");
call symput("last_month_begin",last_month_begin);
if day(date)>25 then do; fk_month_begin = mdy(month(date),26,year(date));*����26-����25��ѭ��;
end_date = mdy(month(date)+1,25,year(date));end;
else do;fk_month_begin = mdy(month(date)-1,26,year(date));
end_date = mdy(month(date),25,year(date));end;
/*����һ��12�µ׸��µ�һ��1�³����������Ȼ��������µ׻���ֿ�ֵ*/
if month(date)=12 and day(date)>25 then do; fk_month_begin = mdy(month(date),26,year(date));*����26-����25��ѭ��;
end_date = mdy(month(date)-11,25,year(date)+1);end;
else if month(date)=1 and day(date)<=25 then do;fk_month_begin = mdy(month(date)+11,26,year(date)-1);
end_date = mdy(month(date),25,year(date));end;
call symput("fk_month_begin",fk_month_begin);
call symput("end_date",end_date);
week = weekday(date);
call symput('week',week);

format dt yymmdd10.;
 dt = today() - 1;
 nt = today();
 db=intnx("month",dt,0,"b");
/* dt=mdy(9,30,2017);*/
/* db=mdy(9,1,2017);*/
 nd = dt-db+60;
 *nd������Ϊ������ʧ��ĸ;
lastweekf=intnx('week',dt,-1);
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("nt", nt);
call symput("lastweekf",lastweekf);
run;

data Ctl_task_assign;
set csdata.Ctl_task_assign(keep=emp_id OVERDUE_LOAN_ID ASSIGN_TIME ASSIGN_EMP_ID status);
/*if status^="-2";*/
format �������� yymmdd10.;
��������=datepart(ASSIGN_TIME);
run;

data ca_staff;
set res.ca_staff;
id1=compress(put(id,$20.));
run;
proc sql;
create table kanr( drop=EMP_ID   ) as
select a.*,b.userName,d.contract_no  from Ctl_task_assign as a
left join ca_staff as b on a.emp_id=b.id1
left join csdata.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sort data=kanr;by contract_no �������� descending status;run;
data kanr_;
set kanr;
format ��һ���������� yymmdd10.;
��һ����������=lag(��������);
by contract_no �������� descending status;
if first.contract_no then do;��һ����������="";end;
run;
data kanr;
set kanr_;
if username not in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111")  and ��һ����������=�������� and status="-2" then delete;
if ASSIGN_EMP_ID^="CS_SYS";
run;

data kanr_;
set kanr;
if username not in ('�ν�ΰ','����Ƽ','����Ƽ');
if kindex(contract_no,"C");
run;

proc sort data=kanr_;by contract_no descending assign_time;run;
proc delete data=assignment;run;
%macro get_payment;
%do i = -61 %to &nd.;
data _null_;
cut_dt = intnx("day", &db., &i.);
call symput("cut_dt", cut_dt);
run;
data macro;
set kanr_(where=(��������<=&cut_dt.));
format cut_date yymmdd10.;
cut_date=&cut_dt.;
run;
proc sort data=macro ;by contract_no descending  assign_time;run;
proc sort data=macro nodupkey;by contract_no;run;
proc append data=macro base=assignment;run;
%end;
%mend;
%get_payment;
proc sort data=assignment;by contract_no cut_date;run;

data cd.assignment;
set assignment;
run;

*�ɶ�V�����޳���ϸ;
data repayfin.payment_daily;
set repayfin.payment_daily;
if contract_no="C2017082215330882762031" and cut_date=mdy(05,28,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C152707489842302300000028" and cut_date=mdy(04,30,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

if contract_no="C2017092218030277297782" and cut_date=mdy(05,14,2019) then ����_��������15�Ӻ�ͬ=0;

if contract_no="C152695711574103000001492" and cut_date=mdy(05,28,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017061613312880918847" and cut_date=mdy(05,22,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017062015444274576521" and cut_date=mdy(05,26,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017071914360094515002" and cut_date=mdy(05,26,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017101609561060204180" and cut_date=mdy(05,20,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017101614480047815595" and cut_date=mdy(05,01,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2018041610570575358936" and cut_date=mdy(05,27,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

*******;
if contract_no="C2017072613194002808112" and cut_date=mdy(06,01,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C151451316038603000001871" and cut_date=mdy(06,03,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

if contract_no="C2018020116463328259218" and cut_date=mdy(06,08,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C152523930887803000001310" and cut_date=mdy(06,08,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017110411172360640132" and cut_date=mdy(06,09,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;


if contract_no="C2016051116201495311550" and cut_date=mdy(06,01,2019) then ����_��������15�Ӻ�ͬ=0;
if contract_no="C2018010315215300009612" and cut_date=mdy(06,04,2019) then ����_��������15�Ӻ�ͬ=0;

if contract_no="C2017122218332782283924" and cut_date=mdy(06,10,2019) then ����_��������15�Ӻ�ͬ=0;
if contract_no="C2018070614030230281756" and cut_date=mdy(06,11,2019) then ����_��������15�Ӻ�ͬ=0;
run;

data repayfin.payment_daily_nt;
set repayfin.payment_daily_nt;
if contract_no="C2017082215330882762031" and cut_date=mdy(05,28,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C152707489842302300000028" and cut_date=mdy(04,30,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

if contract_no="C2017092218030277297782" and cut_date=mdy(05,14,2019) then ����_��������15�Ӻ�ͬ=0;

if contract_no="C152695711574103000001492" and cut_date=mdy(05,28,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017061613312880918847" and cut_date=mdy(05,22,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017062015444274576521" and cut_date=mdy(05,26,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017071914360094515002" and cut_date=mdy(05,26,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017101609561060204180" and cut_date=mdy(05,20,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2017101614480047815595" and cut_date=mdy(05,01,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C2018041610570575358936" and cut_date=mdy(05,27,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

*******;
if contract_no="C2017072613194002808112" and cut_date=mdy(06,01,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C151451316038603000001871" and cut_date=mdy(06,03,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

if contract_no="C2018020116463328259218" and cut_date=mdy(06,08,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;
if contract_no="C152523930887803000001310" and cut_date=mdy(06,08,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;

if contract_no="C2017110411172360640132" and cut_date=mdy(06,09,2019) then ����_���տۿ�ʧ�ܺ�ͬ=0;


if contract_no="C2016051116201495311550" and cut_date=mdy(06,01,2019) then ����_��������15�Ӻ�ͬ=0;
if contract_no="C2018010315215300009612" and cut_date=mdy(06,04,2019) then ����_��������15�Ӻ�ͬ=0;

if contract_no="C2017122218332782283924" and cut_date=mdy(06,10,2019) then ����_��������15�Ӻ�ͬ=0;
if contract_no="C2018070614030230281756" and cut_date=mdy(06,11,2019) then ����_��������15�Ӻ�ͬ=0;


run;


proc sql;
create table assignment1 as
select a.*,b.userName as ��ʧ������Ա,b.�������� as ��ʧ��������,c.userName as cut_date������Ա,c.�������� as cut_date��������
from repayfin.payment_daily(where=(Ӫҵ��^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date;
quit;

*********************����ȥ��������������********************;
proc sql;
create table apple as 
select a.*,b.CURR_PERIOD from assignment1 as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.repay_date=b.repay_date;
quit;
proc sort data=apple;by contract_no cut_date CURR_PERIOD;run;
proc sort data=apple nodupkey;by contract_no cut_date;run;
proc sql;
create table apple1 as
select a.*,b.clear_date as l_clear_date  from apple as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.CURR_PERIOD-1=b.CURR_PERIOD;
quit;
*�����ظ������ǻ���������µ�һ��,���Դֱ���ȥ��;
proc sort data=apple1 nodupkey;by contract_no cut_date;run;
data assignment1;
set apple1;
if ����_��������15�Ӻ�ͬ=1 and repay_date<=l_clear_date then do;����_��������15�Ӻ�ͬ=.;����_��������15�Ӻ�ͬ��ĸ=.;end;

*�������ݼ���;
if kindex(Ӫҵ��,"����") and cut_date<mdy(05,10,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�γ�") and cut_date<mdy(06,01,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,04,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,05,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�����") and cut_date<mdy(06,06,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�Ϸ�") and cut_date<mdy(06,11,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;

*��ʧ���ݿ�ʼ����ʱ��Ҫ�Ӻ�16��;
if kindex(Ӫҵ��,"����") and cut_date<mdy(05,26,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�γ�") and cut_date<mdy(06,17,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,20,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,21,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�����") and cut_date<mdy(06,22,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�Ϸ�") and cut_date<mdy(06,27,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;

run;
*********************����ȥ��������������********************;


*��������ԱΪ���Ǹշſ�ģ�û�з��������Ա��;
data aa;
set assignment1;
if ������Ա="" and cut_date<&month_begin.;
run;

*��Ϊ�⼸����ֻ�ܳ�塢֣�ݡ����ݡ����������š����ڡ���ӡ����졢�Ͼ�����ͨ�����������⼸����֮ǰ�ܵ�Ӫҵ����������Щ�˵�������ʧ��;
data assignment2;
set assignment1;
if  cut_date^=&last_month_end.;
if  cut_date������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
							"��÷��111","������111","��··111","����ܿ111") then  cut_date������Ա="_����";
if  ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
						"��÷��111","������111","��··111","����ܿ111") then  ��ʧ������Ա="_����";

if  kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"֣��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"����")
 or kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"��ͨ") or kindex(Ӫҵ��,"�Ͼ�") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="11���ѹ��ŵ�";
else if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"�γ�")
 or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"�����") or kindex(Ӫҵ��,"�Ϸ�") then ���Ϸ�Χ="5���ѹ��ŵ�";

if cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
						"��÷��111","������111","��··111","����ܿ111") and ���Ϸ�Χ="" then cut_date������Ա="_����";
if ��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
					"��÷��111","������111","��··111","����ܿ111") and ���Ϸ�Χ="" then ��ʧ������Ա="_����";
run;

*����ǰ����ͻ������Ѿ����䵽V�������С�;
data assignment2;
set assignment2;
if ���Ϸ�Χ="5���ѹ��ŵ�" and cut_date=es_date and cut_date��������>=&db. then ����_����Ӧ�ۿ��ͬ=1;
if -15<=repay_date-clear_date<=10 and repay_date+16=cut_date and ����_��������15�Ӻ�ͬ��ĸ^=1 then ����_��������15�Ӻ�ͬ��ĸ=1;

run;

proc sql;
create table assignment3_1 as 
select cut_date������Ա as ������Ա,
sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,
sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date=&dt.
group by cut_date������Ա;
quit;
proc sql;
create table assignment3_2 as 
select ��ʧ������Ա  as ������Ա,
sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2
where cut_date=&dt.
group by ��ʧ������Ա;
quit;
proc sql;
create table assignment3 as 
select a.*,b.*
from assignment3_1 as a 
left join assignment3_2 as b 
on a.������Ա=b.������Ա;
quit;

proc sql;
create table assignment4_1 as 
select cut_date������Ա as ������Ա,
sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,
sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date<=&dt.
group by cut_date������Ա;
quit;

proc sql;
create table assignment4_2 as 
select ��ʧ������Ա  as ������Ա,
sum(����_��������15�Ӻ�ͬ) as ������ʧ,
sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ��ʧ�� format percent7.2
from assignment2
where cut_date<=&dt.
group by ��ʧ������Ա;
quit;
proc sql;
create table assignment4 as 
select a.*,b.*
from assignment4_1 as a 
left join assignment4_2 as b 
on a.������Ա=b.������Ա;
quit;

proc sql;
create table assignment5 as 
select a.*,b.*
from assignment3 as a
left join assignment4 as b
on a.������Ա=b.������Ա;
quit;

data assignment6;
retain ������Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ��;
set assignment5;
run;


data assignment2_1;
set assignment2(where=(cut_date=&dt.));
if ����_����Ӧ�ۿ��ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� cut_date������Ա;
run;


data assignment2_2;
set assignment2(where=(cut_date=&dt.));
if ����_���տۿ�ʧ�ܺ�ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� cut_date������Ա cut_Date;
rename cut_Date=��������;
run;


data assignment2_3;
set assignment2(where=(cut_date=&dt.));
if ����_��������15�Ӻ�ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա cut_Date;
rename cut_Date=��ʧ����;
run;


data assignment2_4;
set assignment2;
if ����_����Ӧ�ۿ��ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� cut_date������Ա;
run;


data assignment2_5;
set assignment2;
if ����_���տۿ�ʧ�ܺ�ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� cut_date������Ա cut_Date;
rename cut_Date=��������;
run;


/**�³���;*/
/*data assignment2_6;*/
/*set assignment2;*/
/*if ����_��������15�Ӻ�ͬ=1;*/
/*keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա repay_date cut_Date;*/
/*rename cut_Date=��ʧ����;*/
/*run;*/
/**/
/*PROC EXPORT DATA=assignment2_6*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/**/
/*data assignment2_7;*/
/*set assignment2;*/
/*if ����_��������15�Ӻ�ͬ��ĸ=1 ; */
/*keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա repay_date ;*/
/*run;*/
/*proc sort data=assignment2_7;by repay_date;run;*/
/**/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�����ܿۿ�����ϸ"; RUN;*/


/*filename DD DDE "EXCEL|[�ɶ��ͷ������ձ���.xlsx]Sheet1!r4c1:r11c11";*/
/*data _null_;set assignment6;file DD;put ������Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� ;run;*/

proc sql;
create table assignment1_nt as
select a.*,b.userName as ��ʧ������Ա,b.�������� as ��ʧ��������,c.userName as cut_date������Ա,c.�������� as cut_date��������

from repayfin.payment_daily_nt(where=(Ӫҵ��^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date;
quit;

*******ȥ����������**********;

proc sql;
create table apple_nt as 
select a.*,b.CURR_PERIOD from assignment1_nt as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.repay_date=b.repay_date;
quit;
proc sort data=apple_nt;by contract_no cut_date CURR_PERIOD;run;
proc sort data=apple_nt nodupkey;by contract_no cut_date;run;
proc sql;
create table apple_nt1 as
select a.*,b.clear_date as l_clear_date  from apple_nt as a
left join account.bill_main as b on a.contract_no=b.contract_no and a.CURR_PERIOD-1=b.CURR_PERIOD;
quit;
*�����ظ������ǻ���������µ�һ��,���Դֱ���ȥ��;
proc sort data=apple_nt1 nodupkey;by contract_no cut_date;run;
data assignment1_nt;
set apple_nt1;
if ����_��������15�Ӻ�ͬ=1 and repay_date<=l_clear_date then do;����_��������15�Ӻ�ͬ=.;����_��������15�Ӻ�ͬ��ĸ=.;end;

*�������ݼ��㰴����ʱ�����;
if kindex(Ӫҵ��,"����") and cut_date<mdy(05,10,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�γ�") and cut_date<mdy(06,01,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,04,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,05,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�����") and cut_date<mdy(06,06,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;
if kindex(Ӫҵ��,"�Ϸ�") and cut_date<mdy(06,11,2019) then do;����_���տۿ�ʧ�ܺ�ͬ=0;����_����Ӧ�ۿ��ͬ=0;end;

*��ʧ���ݿ�ʼ����ʱ��Ҫ�Ӻ�16��;
if kindex(Ӫҵ��,"����") and cut_date<mdy(05,26,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�γ�") and cut_date<mdy(06,17,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,20,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"����") and cut_date<mdy(06,21,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�����") and cut_date<mdy(06,22,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;
if kindex(Ӫҵ��,"�Ϸ�") and cut_date<mdy(06,27,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;

run;
*******ȥ����������**********;

*��Ϊ�⼸����ֻ�ܳ�塢֣�ݡ����ݡ����������š����ڡ���ӣ����������⼸����֮ǰ�ܵ�Ӫҵ����������Щ�˵�������ʧ��;
data assignment2_nt;
set assignment1_nt;
if cut_date^=&last_month_end.;
if cut_date������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
							"��÷��111","������111","��··111","����ܿ111") then  cut_date������Ա="_����";

if ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
						"��÷��111","������111","��··111","����ܿ111") then ��ʧ������Ա="_����";

if kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"֣��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"����")
 or kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"��ͨ") or kindex(Ӫҵ��,"�Ͼ�") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="11���ѹ��ŵ�";
else if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"�γ�")
 or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"�����") or kindex(Ӫҵ��,"�Ϸ�") then ���Ϸ�Χ="5���ѹ��ŵ�";

if cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
						"��÷��111","������111","��··111","����ܿ111")
and ���Ϸ�Χ="" then cut_date������Ա="_����";

if ��ʧ������Ա  in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��ï˼111",
					"��÷��111","������111","��··111","����ܿ111") and ���Ϸ�Χ="" then ��ʧ������Ա="_����";
run;

data assignment2_nt;
set assignment2_nt;
if ���Ϸ�Χ="5���ѹ��ŵ�" and cut_date=es_date and cut_date��������>=&db. then ����_����Ӧ�ۿ��ͬ=1;
if -15<=repay_date-clear_date<=10 and repay_date+16=cut_date and ����_��������15�Ӻ�ͬ��ĸ^=1 then ����_��������15�Ӻ�ͬ��ĸ=1;

run;


proc sql;
create table nt_account as 
select 
cut_date������Ա as ������Ա,
count(*) as Ŀǰ�˻���
from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled')
group by cut_date������Ա;
quit;


proc sql;
create table nt_daikou as 
select 
cut_date������Ա as ������Ա,
count(*) as ��������ܸ���
from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1
group by cut_date������Ա;
quit;

proc sql;
create table nt_daikou_ as 
select contract_no, �ͻ�����,cut_date������Ա,repay_date
from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1;
quit;

data cc;
set account.bill_main(where=(repay_date=&nt. and bill_status not in ("0000","0003")));
run;
proc sql;
create table cc1 as
select b.* from cc as a
left join account.Bill_fee_dtl as b on a.contract_no=b.contract_no;
quit;
proc sql;
create table cc2 as 
select contract_no,sum(CURR_RECEIPT_AMT) as �ѻ�������Ϣ 
from account.Bill_fee_dtl(where=(fee_name in ("����","��Ϣ") and OFFSET_DATE=&nt. )) where contract_no in (select contract_no from cc1)
group by contract_no;quit;
proc sql;
create table cc3(where=(not od_days>0)) as
select a.contract_no,a.repay_date,b.�ѻ�������Ϣ,a.CURR_RECEIVE_AMT,c.Ӫҵ��,d.od_days,d.�ʽ�����  from cc as a
left join cc2 as b on a.contract_no=b.contract_no
left join zq.Account_info as c on a.contract_no=c.contract_no 
left join repayFin.payment_daily(where=(cut_date=&dt.)) as d on a.contract_no=d.contract_no ;
quit;
data cc3_1;
set cc3;
if CURR_RECEIVE_AMT>�ѻ�������Ϣ and sum(CURR_RECEIVE_AMT,-�ѻ�������Ϣ)>1 and �ѻ�������Ϣ<100;
if �ʽ����� not in ("jsxj1");
run;
*����;
data tttrepay_plan_js;
set account.repay_plan_js;
run;
proc sort data = tttrepay_plan_js; by contract_no psperdno descending SETLPRCP; run;
proc sort data = tttrepay_plan_js nodupkey; by contract_no psperdno; run;
data  tttrepay_plan_js;
set tttrepay_plan_js;
format repay_date_js  clear_date_js yymmdd10.;
repay_date_js=mdy(scan(psduedt,2,"-"), scan(psduedt,3,"-"),scan(psduedt,1,"-"));
if SETLPRCP=PSPRCPAMT and SETLNORMINT=PSNORMINTAMT then  clear_date_js=datepart(CREATED_TIME)-1;
if repay_date_js<=mdy(10,25,2016) then clear_date_js=repay_date_js;
run;

data cc3_1_js;*����;
set tttrepay_plan_js;
if repay_date_js=&nt.;
if SETLPRCP^=PSPRCPAMT or SETLNORMINT^=PSNORMINTAMT;
rename repay_date_js=repay_date;
run;


data cc3_1;
set cc3_1 cc3_1_js ;
if Ӫҵ��^="APP";
if contract_no="C2018101613583597025048" then delete;/*����ͻ�ɾ��*/
run;
proc sort data=cc3_1  nodupkey;by contract_no;run;

proc sql;
create table cc3_1_ as
select a.*,b.cut_date������Ա as ������Ա,c.es
from  cc3_1 as a
left join assignment2_nt as b on a.contract_no=b.contract_no and a.repay_date=b.cut_Date
left join repayfin.payment_daily as c on a.contract_no=c.contract_no and a.repay_date=c.cut_Date
;
quit;

proc sql;
create table nt_daikou1 as
select ������Ա,
count(*)
from cc3_1_(where=(repay_date=&nt.))
where es^=1
group by ������Ա;
quit;
proc sql;
create table nt_daikou1_ as
select contract_no,������Ա,repay_date
from cc3_1_(where=(repay_date=&nt.)) 
where es^=1;
quit;


proc sql;
create table yuqi17 as 
select cut_date������Ա as ������Ա,
count(*) as yuqi17
from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7
group by ������Ա;
quit;

proc sql;
create table yuqi815 as 
select cut_date������Ա as ������Ա,
count(*) as yuqi815
from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15
group by ������Ա;
quit;

proc sql;
create table yuqi115_ as 
select contract_no,�ͻ�����,cut_date������Ա as ������Ա,repay_date,od_days as ��������
from assignment2_nt
where cut_date=&nt. and 1<=od_days<=15;
quit;


proc sql;
create table assignment4_2_a as 
select ��ʧ������Ա  as ������Ա,
sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2_nt
where cut_date=&nt.
group by ��ʧ������Ա;
quit;

proc sql;
create table assignment4_2_b as 
select ��ʧ������Ա  as ������Ա,
sum(����_��������15�Ӻ�ͬ) as ������ʧ_nt,
sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���_nt,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ��ʧ��_nt format percent7.2
from assignment2_nt
where cut_date<=&nt.
group by ��ʧ������Ա;
quit;


data assignment2_3;
set assignment2_nt(where=(cut_date=&nt.));
if ����_��������15�Ӻ�ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա cut_Date;
rename cut_Date=��ʧ����;
run;

data assignment2_6;
set assignment2_nt;
if ����_��������15�Ӻ�ͬ=1;
keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա repay_date cut_Date;
rename cut_Date=��ʧ����;
run;


data assignment2_7;
set assignment2_nt;
if ����_��������15�Ӻ�ͬ��ĸ=1 ; 
keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա repay_date ;
run;
proc sort data=assignment2_7;by repay_date;run;



data test;
set account.bill_main;
if bill_status^="0003";
if CLEAR_DATE>=&dt. or CLEAR_DATE="" ;*��Ϊ���޳�С�������;
if &nt.+1<=repay_date<=&nt.+5;
keep contract_no repay_date;
if contract_no="C2018101613583597025048" then delete;/*����ͻ�ɾ��*/
run;
proc sort data=test;by contract_no repay_date;run;
proc sort data=test nodupkey;by contract_no;run;
/**����;*/
data test_js;
set repayfin.tttrepay_plan_js;
if &nt.+1<=repay_date_js<=&nt.+5;
keep contract_no repay_date_js;
rename repay_date_js=repay_date;
run;
proc sort data=test_js;by contract_no repay_date;run;
proc sort data=test_js nodupkey;by contract_no;run;

data test_all;
set test test_js ;
run;
proc sort data=test_all nodupkey;by contract_no repay_date;run;

proc sql;
create table tjia as
select a.*,b.cut_date������Ա as ������Ա,b.�ͻ�����,b.Ӫҵ��
from test_all as a 
left join assignment2_nt(where=(cut_Date=&nt.)) as b 
on a.contract_no=b.contract_no;
quit;


proc sql;
create table Tjia5 as 
select ������Ա,
count(*) as T5
from tjia
group by ������Ա;
quit;

proc sql;
create table Tjia5_ as 
select contract_no,�ͻ�����,������Ա,repay_Date
from tjia;
quit;


proc sort data=yuqi17;by ������Ա;run;
proc sort data=yuqi815;by ������Ա;run;
proc sort data=Tjia5;by ������Ա;run;
proc sort data=nt_daikou1;by ������Ա;run;
proc sort data=nt_daikou;by ������Ա;run;
proc sort data=nt_account;by ������Ա;run;
proc sort data=assignment6;by ������Ա;run;
proc sort data=assignment4_2_a;by ������Ա;run;
proc sort data=assignment4_2_b;by ������Ա;run;

data dangtian;
merge assignment6  nt_account nt_daikou nt_daikou1 yuqi17 yuqi815 assignment4_2_a assignment4_2_b Tjia5 ;
by ������Ա;
run;

*************��ʱ����ֿ�ֵ(�Ժ�ɾ��)*******;
/*data dangtian;*/
/*set dangtian;*/
/*if ������Ա^="";*/
/*run;*/
*************��ʱ����ֿ�ֵ*******;

data dangtian1;
set dangtian;
format ��Ա $40.;
if ������Ա in ("�����","����","Ԭ����") then ��Ա="a_"||������Ա;
if ������Ա in ("�ߺ�") then ��Ա="b_"||������Ա;
if ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111") then ��Ա="c_"||������Ա;
if ������Ա in ("��÷��111","������111","��··111","����ܿ111") then ��Ա="d_"||������Ա;
if ������Ա in ("_����") then ��Ա="e_"||"��������";
drop ������Ա;
run;
proc sort data=dangtian1;by ��Ա;run;
data dangtian1_;
retain ��Ա;
set dangtian1;
if ��Ա^=""; 
run;

data dangtian1_;
set dangtian1_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;



********************************��V����Ӫҵ����**************************************;
**********����������+������ʧ��***********;
data branch_vfenhang;
input Ӫҵ�� $45.;
cards;
��ɽ�е�һӪҵ��
��������·Ӫҵ��
�����е�һӪҵ��
տ���е�һӪҵ��
�����е�һӪҵ��
�γ��е�һӪҵ��
�����е�һӪҵ��
������е�һӪҵ��
�����е�һӪҵ��
�Ϸ�վǰ·Ӫҵ��
;
run;

proc sql;
create table assignment3_1a as 
select Ӫҵ��,
sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,
sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date=&dt.
group by Ӫҵ��;
quit;
proc sql;
create table assignment3_2a as 
select Ӫҵ��, sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2
where cut_date=&dt.
group by Ӫҵ��;
quit;

proc sql;
create table assignment4_1a as 
select Ӫҵ��,
sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,
sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date<=&dt.
group by Ӫҵ��;
quit;

*V���пۿ���+��ʧ;
proc sql;
create table assignment4_2a as 
select Ӫҵ��,
sum(����_��������15�Ӻ�ͬ) as ������ʧ,
sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ��ʧ�� format percent7.2
from assignment2
where mdy(05,17,2019)<=cut_date<=&dt. and ��ʧ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��÷��111","������111","��··111","����ܿ111")
group by Ӫҵ��;
quit;

proc sql;
create table assignment5a as 
select a.*,b.*,c.*,d.*,e.*
from branch_vfenhang as a
left join assignment3_1a as b on a.Ӫҵ��=b.Ӫҵ��
left join assignment3_2a as c on a.Ӫҵ��=c.Ӫҵ��
left join assignment4_1a as d on a.Ӫҵ��=d.Ӫҵ��
left join assignment4_2a as e on a.Ӫҵ��=e.Ӫҵ��;
quit;

data assignment6a;
retain Ӫҵ�� ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ��;
set assignment5a;
run;
**********��������ʧ��***********;
proc sql;
create table nt_account_a as 
select Ӫҵ��,count(*) as Ŀǰ�˻��� from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled') and
cut_date������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","��ï˼111","ղӳ��111","��÷��111","������111","��··111","����ܿ111")
group by Ӫҵ��;
quit;
proc sql;
create table nt_daikou_a as 
select Ӫҵ��,count(*) as ��������ܸ��� from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1
group by Ӫҵ��;
quit;

proc sql;
create table nt_daikou1_a as
select Ӫҵ��,count(*) from cc3_1_(where=(repay_date=&nt.))
where es^=1
group by Ӫҵ��;
quit;

proc sql;
create table yuqi17a as 
select Ӫҵ��,count(*) as yuqi17 from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7
group by Ӫҵ��;
quit;

proc sql;
create table yuqi815a as 
select Ӫҵ��,count(*) as yuqi815 from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15
group by Ӫҵ��;
quit;

proc sql;
create table assignment4_2_aa as 
select Ӫҵ��,
sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2_nt
where cut_date=&nt.
group by Ӫҵ��;
quit;

proc sql;
create table assignment4_2_ba as 
select Ӫҵ��,
sum(����_��������15�Ӻ�ͬ) as ������ʧ_nt,
sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���_nt,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ��ʧ��_nt format percent7.2
from assignment2_nt
where mdy(05,17,2019)<=cut_date<=&nt. and ��ʧ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��÷��111","������111","��··111","����ܿ111")
group by Ӫҵ��;
quit;

proc sql;
create table Tjia5_a as 
select Ӫҵ��,count(*) as T5 from tjia
where ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","ղӳ��111","��÷��111","������111","��··111","����ܿ111")
group by Ӫҵ��;
quit;

proc sort data=yuqi17a;by Ӫҵ��;run;
proc sort data=yuqi815a;by Ӫҵ��;run;
proc sort data=Tjia5_a;by Ӫҵ��;run;
proc sort data=nt_daikou1_a;by Ӫҵ��;run;
proc sort data=nt_daikou_a;by Ӫҵ��;run;
proc sort data=nt_account_a;by Ӫҵ��;run;
proc sort data=assignment6a;by Ӫҵ��;run;
proc sort data=assignment4_2_aa;by Ӫҵ��;run;
proc sort data=assignment4_2_ba;by Ӫҵ��;run;

data dangtian_a;
merge assignment6a(in=a)  nt_account_a nt_daikou_a nt_daikou1_a yuqi17a yuqi815a assignment4_2_aa assignment4_2_ba Tjia5_a ;
by Ӫҵ��;
if a;
run;
data dangtian_a_;
set dangtian_a;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

/**/
/*PROC EXPORT DATA=assignment2_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����Ӧ����ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL ;SHEET="����������ϸ1"; RUN;*/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_4*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����Ӧ����ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_5*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����������ϸ"; RUN;*/
/*PROC EXPORT DATA=nt_daikou_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�ܴ�����ϸ"; RUN;*/
/*PROC EXPORT DATA=nt_daikou1_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="��ʣ�������ϸ"; RUN;*/
/*PROC EXPORT DATA=yuqi115_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����1-15����ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_6*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�ܿۿ�����ϸ"; RUN;*/
/*PROC EXPORT DATA=Tjia5_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="T��5������ϸ"; RUN;*/
/**/
/*x "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�ɶ��ͷ������ձ���.xlsx";*/
/*filename DD DDE "EXCEL|[�ɶ��ͷ������ձ���.xlsx]Sheet1!r4c1:r18c21";*/
/*data _null_;set dangtian1_;file DD;put  ��Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� Ŀǰ�˻��� ��������ܸ���  _TEMG001  yuqi17 yuqi815 ������ʧ ������ʧ_nt �ܿۿ���_nt ��ʧ��_nt T5 ;run;*/
/*filename DD DDE "EXCEL|[�ɶ��ͷ������ձ���.xlsx]Sheet1!r19c1:r28c21";*/
/*data _null_;set dangtian_a_;file DD;put  Ӫҵ�� ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� Ŀǰ�˻��� ��������ܸ���  _TEMG001  yuqi17 yuqi815 ������ʧ ������ʧ_nt �ܿۿ���_nt ��ʧ��_nt T5 ;run;*/
