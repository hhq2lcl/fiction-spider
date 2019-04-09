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
/*libname cd "F:\A_offline_zky\A_offline\weekly\V���������ձ�\chengdu_data";*/

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
if username not in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") and ��һ����������=�������� and status="-2" then delete;
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
data assignment;
set cd.assignment;
/*if contract_no in ('C151540474038803000002803','C152420717831703000000163','C152880258869303000000943','C152886448582203000001121','C153959059889403000000112','C154051732322903000000393','C154519924103203000000624','C2016040813524772791580','C2016041917145792051552','C2017072017015513426199','C2017082214165506075235','C2017082513430833201030','C2017091118162572452473','C2017091517345523906292','C2017092610572829147242','C2017101918084929769159','C2017112014415896422549','C2017122010564324395929','C2017122217383694791945','C2018042017262518501269','C2018051415033324144130','',''*/
/*) then userName="����";*/
run;

***************payment_daily��payment_daily_nt�޸�******************;
data repayfin.payment_daily;
set repayfin.payment_daily;
run;


data repayfin.payment_daily_nt;
set repayfin.payment_daily_nt;
run;




proc sql;
create table assignment1 as
select a.*,b.userName as ��ʧ������Ա,b.�������� as ��ʧ��������,c.userName as cut_date������Ա,c.�������� as cut_date��������,
d.userName as v��ʧ������Ա,d.�������� as v��ʧ��������,
e.userName as e��ʧ������Ա,e.�������� as e��ʧ��������
from repayfin.payment_daily(where=(Ӫҵ��^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date
left join assignment as d on a.contract_no=d.contract_no and a.cut_date=d.cut_date+1
left join assignment as e on a.contract_no=e.contract_no and a.cut_date=e.cut_date-15;
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

if kindex(Ӫҵ��,"����") and cut_date<mdy(04,03,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;*������18�Ž��ֵģ���ʧ������4��3�ղ���-5��ɾ��;
if (kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��")) and cut_date<mdy(03,22,2019) then do;
����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;

run;
*********************����ȥ��������������********************;


*������ԱΪ���Ǹշſ�ģ�û�з��������Ա;
data aa;
set assignment1;
if ������Ա="" and cut_date<&month_begin.;
run;
*��Ϊ�⼸����ֻ�ܳ�塢֣�ݡ����ݡ����������š����ڡ���ӣ����������⼸����֮ǰ�ܵ�Ӫҵ����������Щ�˵�������ʧ��;
data assignment2;
set assignment1;
if  cut_date^=&last_month_end.;
if  cut_date������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then  cut_date������Ա="_����";
if  ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") then  ��ʧ������Ա="_����";
if  v��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") then  v��ʧ������Ա="_����";
if  e��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then  e��ʧ������Ա="_����";

if  kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"֣��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"����")
 or kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"��ͨ") or kindex(Ӫҵ��,"�Ͼ�") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="11���ѹ��ŵ�";
else if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="5���ѹ��ŵ�";

if cut_date������Ա  in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") and ���Ϸ�Χ="" then cut_date������Ա="_����";
if ��ʧ������Ա  in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") and ���Ϸ�Χ="" then ��ʧ������Ա="_����";
if v��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") and ���Ϸ�Χ="" then  v��ʧ������Ա="_����";
if e��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") and ���Ϸ�Χ="" then  e��ʧ������Ա="_����";

if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ=1 then ��ʧ������Ա=v��ʧ������Ա;
if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ��ĸ=1 then ��ʧ������Ա=v��ʧ������Ա;
if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ��ĸ=1 then ��ʧ������Ա=e��ʧ������Ա;

if ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")  then ��ʧ������Ա="_����";
if ��ʧ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then V�ۿ���=1;
	else V�ۿ���=0;
if ��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") and ���Ϸ�Χ="5���ѹ��ŵ�" then ����ɶ�=1;
	else ����ɶ�=0;

if cut_date<mdy(03,22,2019) and ����_��������15�Ӻ�ͬ=1 and ���Ϸ�Χ="5���ѹ��ŵ�" then ����_��������15�Ӻ�ͬ=0;*�޳�V����3��22��֮ǰ����ʧ;


if cut_date<mdy(03,22,2019) and ���Ϸ�Χ="5���ѹ��ŵ�" 
and ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") then ��ʧ������Ա="_����";/*�³�ɾ��*/
run;

*************************11Ӫҵ��+4Ӫҵ��******************************;
data branch_chengdu;
input BRANCH_NAME $45.;
cards;
����е�һӪҵ��
����е�һӪҵ��
�����е�һӪҵ��
������ҵ������
�Ͼ��е�һӪҵ��
�Ͼ���ҵ������
��ͨ��ҵ������
�����е�һӪҵ��
�����е�һӪҵ��
֣���е�һӪҵ��
�����е�һӪҵ��
��ɽ�е�һӪҵ��
��������·Ӫҵ��
�����е�һӪҵ��
տ���е�һӪҵ��
�����е�һӪҵ��
;
run;
*************************11Ӫҵ��+4Ӫҵ��*******************************;



*************���ͷ���Ա���顿***************;
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
select ��ʧ������Ա  as ������Ա, sum(����_��������15�Ӻ�ͬ) as ������ʧ
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


*********************************�ܿۿ������ӡ���V���пͷ������˻�*************************;
proc sql;
create table aa_vv1 as
select ����ɶ� as ������,sum(����_��������15�Ӻ�ͬ��ĸ) as ����ɶ��ͻ��� from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. group by ����ɶ�;
quit;

proc sql;
create table aa_vv2 as
select V�ۿ��� as ������,sum(����_��������15�Ӻ�ͬ��ĸ) as V���пۿ��� from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. group by V�ۿ���;
quit;

data aa_vv;
merge aa_vv1 aa_vv2;
by ������;
if ������=1;
run;

proc sql;
create table aa_cd1 as 
select ����ɶ� as ������,��ʧ������Ա as ������Ա,sum(����_��������15�Ӻ�ͬ��ĸ) as V�ۿ���
from assignment2
where mdy(03,22,2019)<=cut_date<=&dt. and ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����")
group by ������,��ʧ������Ա;
quit;

proc sql;
create table aa_cd2(drop=������) as
select a.*,b.* from aa_cd1 as a
left join aa_vv as b on a.������=b.������;
quit;
proc sql;
create table assignment4_2_ as 
select ��ʧ������Ա  as ������Ա,sum(����_��������15�Ӻ�ͬ) as ������ʧ,sum(����_��������15�Ӻ�ͬ��ĸ) as cd�ۿ��� from assignment2
where cut_date<=&dt. group by ��ʧ������Ա;
quit;

proc sql;
create table assignment4_2 as
select a.*,b.* from assignment4_2_ as a
left join aa_cd2 as b on a.������Ա=b.������Ա;
run;

data assignment4_2_;
set assignment4_2;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

data assignment4_2;
set assignment4_2_;
format �ܿۿ��� 10. ��ʧ��  percent7.2;
if ������Ա^="_����" then do;
�ܿۿ���=cd�ۿ���+V�ۿ���/����ɶ��ͻ���*V���пۿ���;
��ʧ��=������ʧ/(cd�ۿ���+V�ۿ���/����ɶ��ͻ���*V���пۿ���);
end;
if ������Ա="_����" then do;�ܿۿ���=cd�ۿ���;��ʧ��=������ʧ/cd�ۿ���;end;

drop cd�ۿ��� V�ۿ��� ����ɶ��ͻ��� V���пۿ���;
run;

*********************************�ܿۿ������ӡ���V���пͷ������˻�*************************;


proc sql;
create table assignment4 as 
select a.*,b.*
from assignment4_1 as a 
left join assignment4_2 as b on a.������Ա=b.������Ա;
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

*************��Ӫҵ�����顿***************;
proc sql;
create table assignment3_1a as 
select Ӫҵ��,sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date=&dt. and cut_date������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;

proc sql;
create table assignment3_2a as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ) as ������ʧ from assignment2
where cut_date=&dt. and ��ʧ������Ա^="_����"
group by Ӫҵ��;
quit;
proc sql;
create table assignment4_1a as 
select Ӫҵ��,sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment2
where cut_date<=&dt. and cut_date������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;

**********************������ʧ���ӷ�ĸ********************;
proc sql;
create table assignment4_2a1 as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2
where mdy(03,22,2019)<=cut_date<=&nt. and ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա^="_����"
group by Ӫҵ��;
quit;

*Ӫҵ�����ܿۿ��������ˡ��ɶ��ͷ���V���С�;
proc sql;
create table assignment4_2a2 as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���
from assignment2
where mdy(03,22,2019)<=cut_date<=&nt. and ���Ϸ�Χ="5���ѹ��ŵ�" and cut_date������Ա^="_����"
group by Ӫҵ��;
quit;
data assignment4_2a;
merge assignment4_2a1 assignment4_2a2;
by Ӫҵ��;
format ��ʧ�� percent7.2;
��ʧ��=������ʧ/�ܿۿ���;
run;
**********************������ʧ���ӷ�ĸ********************;

proc sql;
create table assignment5a(drop=Ӫҵ��) as
select a.*,b.*,c.*,d.*,e.* from branch_chengdu as a
left join assignment3_1a as b on a.BRANCH_NAME=b.Ӫҵ��
left join assignment3_2a as c on a.BRANCH_NAME=c.Ӫҵ��
left join assignment4_1a as d on a.BRANCH_NAME=d.Ӫҵ��
left join assignment4_2a as e on a.BRANCH_NAME=e.Ӫҵ��;
quit;

data assignment6a;
retain BRANCH_NAME ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ��;
set assignment5a;
rename BRANCH_NAME=Ӫҵ��;
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
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/**/
/*data assignment2_7;*/
/*set assignment2;*/
/*if ����_��������15�Ӻ�ͬ��ĸ=1 ; */
/*keep contract_no Ӫҵ�� �ͻ����� ��ʧ������Ա repay_date ;*/
/*run;*/
/*proc sort data=assignment2_7;by repay_date;run;*/
/**/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�����ܿۿ�����ϸ"; RUN;*/


/*filename DD DDE "EXCEL|[�ɶ����ձ���.xlsx]Sheet1!r4c1:r11c11";*/
/*data _null_;set assignment6;file DD;put ������Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� ;run;*/

proc sql;
create table assignment1_nt as
select a.*,b.userName as ��ʧ������Ա,b.�������� as ��ʧ��������,c.userName as cut_date������Ա,c.�������� as cut_date��������,
d.userName as v��ʧ������Ա,d.�������� as v��ʧ��������,
e.userName as e��ʧ������Ա,e.�������� as e��ʧ��������
from repayfin.payment_daily_nt(where=(Ӫҵ��^="APP" )) as a
left join assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date
left join assignment as d on a.contract_no=d.contract_no and a.cut_date=d.cut_date+1
left join assignment as e on a.contract_no=e.contract_no and a.cut_date=e.cut_date-15;
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

if kindex(Ӫҵ��,"����") and cut_date<mdy(04,03,2019) then do;����_��������15�Ӻ�ͬ��ĸ=0;����_��������15�Ӻ�ͬ=0;end;*������18�Ž��ֵģ���ʧ������4��3�ղ���-5��ɾ��;

run;
data cd.assignment1_nt;
set assignment1_nt;
run;
*******ȥ����������**********;

*��Ϊ�⼸����ֻ�ܳ�塢֣�ݡ����ݡ����������š����ڡ���ӣ����������⼸����֮ǰ�ܵ�Ӫҵ����������Щ�˵�������ʧ��;
data assignment2_nt;
set assignment1_nt;
if  cut_date^=&last_month_end.  ;
if  cut_date������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then  cut_date������Ա="_����";
if  ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") then  ��ʧ������Ա="_����";
if  v��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") then  v��ʧ������Ա="_����";
if  e��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then  e��ʧ������Ա="_����";

if  kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"֣��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"����")
 or kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"��ͨ") or kindex(Ӫҵ��,"�Ͼ�") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="11���ѹ��ŵ�";
else if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����") then ���Ϸ�Χ="5���ѹ��ŵ�";

if cut_date������Ա  in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") and ���Ϸ�Χ="" then cut_date������Ա="_����";
if ��ʧ������Ա  in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") and ���Ϸ�Χ="" then ��ʧ������Ա="_����";
if v��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") and ���Ϸ�Χ="" then  v��ʧ������Ա="_����";
if e��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") and ���Ϸ�Χ="" then  e��ʧ������Ա="_����";

if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ=1 then ��ʧ������Ա=v��ʧ������Ա;
if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ��ĸ=1 then ��ʧ������Ա=v��ʧ������Ա;
if ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա="_����" and ����_��������15�Ӻ�ͬ��ĸ=1 then ��ʧ������Ա=e��ʧ������Ա;

if ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")  then ��ʧ������Ա="_����";
if ��ʧ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then V�ۿ���=1;
	else V�ۿ���=0;
if ��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","�Ķ���1111","Ԭ����","����") and ���Ϸ�Χ="5���ѹ��ŵ�" then ����ɶ�=1;
	else ����ɶ�=0;

if cut_date<mdy(03,22,2019) and ����_��������15�Ӻ�ͬ=1 and ���Ϸ�Χ="5���ѹ��ŵ�" then ����_��������15�Ӻ�ͬ=0;*�޳�V����3��22��֮ǰ����ʧ;

if cut_date<mdy(03,22,2019) and ���Ϸ�Χ="5���ѹ��ŵ�" 
and ��ʧ������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����") then ��ʧ������Ա="_����";/*�³�ɾ��*/

run;

*************���ͷ���Ա���顿***************;
proc sql;
create table nt_account as 
select cut_date������Ա as ������Ա,count(*) as Ŀǰ�˻��� from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled')
group by cut_date������Ա;
quit;
proc sql;
create table nt_daikou as 
select cut_date������Ա as ������Ա,count(*) as ��������ܸ��� from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1
group by cut_date������Ա;
quit;

*************��Ӫҵ�����顿***************;
proc sql;
create table nt_account_a as 
select Ӫҵ��,count(*) as Ŀǰ�˻��� from assignment2_nt
where cut_date=&nt.  and pre_1m_status not in('09_ES','11_Settled') and cut_date������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;
proc sql;
create table nt_daikou_a as 
select Ӫҵ��,count(*) as ��������ܸ��� from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1 and cut_date������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;


proc sql;
create table nt_daikou_ as 
select contract_no,�ͻ�����,cut_date������Ա,repay_date
from assignment2_nt
where cut_date=&nt. and ����_����Ӧ�ۿ��ͬ=1;
quit;


data cc;
set account.bill_main(where=(repay_date=&nt. and bill_status not in ("0000","0003")));*��0000:�Ѿ����壬0001:����,0002:���ڣ�0003:��ǰ���塿;
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
select a.*,b.cut_date������Ա as ������Ա,b.���Ϸ�Χ,c.es
from  cc3_1 as a
left join assignment2_nt as b on a.contract_no=b.contract_no and a.repay_date=b.cut_Date
left join repayfin.payment_daily as c on a.contract_no=c.contract_no and a.repay_date=c.cut_Date;
quit;

*************���ͷ���Ա���顿***************;
proc sql;
create table nt_daikou1 as
select ������Ա,count(*) from cc3_1_(where=(repay_date=&nt.))
where es^=1
group by ������Ա;
quit;

*************��Ӫҵ�����顿***************;
proc sql;
create table nt_daikou1a as
select Ӫҵ��,count(*) from cc3_1_(where=(repay_date=&nt.))
where es^=1 and ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;


proc sql;
create table nt_daikou1_ as
select contract_no,������Ա,repay_date from cc3_1_(where=(repay_date=&nt.)) 
where es^=1;
quit;

*************���ͷ���Ա���顿***************;
proc sql;
create table yuqi17 as 
select cut_date������Ա as ������Ա,count(*) as yuqi17 from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7 and cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����")
group by ������Ա;
quit;

proc sql;
create table yuqi815 as 
select cut_date������Ա as ������Ա,count(*) as yuqi815 from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15 and cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����")
group by ������Ա;
quit;

*************��Ӫҵ�����顿***************;
proc sql;
create table yuqi17a as 
select Ӫҵ��,count(*) as yuqi17 from assignment2_nt
where cut_date=&nt. and 1<=od_days<=7 and cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����")
group by Ӫҵ��;
quit;
proc sql;
create table yuqi815a as 
select Ӫҵ��,count(*) as yuqi815 from assignment2_nt
where cut_date=&nt. and 8<=od_days<=15 and cut_date������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����")
group by Ӫҵ��;
quit;

/*proc sql;*/
/*create table yuqi115_ as */
/*select contract_no,�ͻ�����,cut_date������Ա as ������Ա,repay_date,od_days as ��������*/
/*from assignment2_nt*/
/*where cut_date=&nt. and 1<=od_days<=15;*/
/*quit;*/
data yuqi115_;
set assignment2_nt;
if cut_date=&nt. and 1<=od_days<=15;
if cut_date������Ա not in ("�����","��ǨӢ","�ߺ�","Ԭ����","����","_����") then cut_date������Ա="_����";
keep contract_no �ͻ����� cut_date������Ա repay_date od_days;
rename cut_date������Ա=������Ա od_days=��������;
run;

*************���ͷ���Ա���顿***************;
proc sql;
create table assignment4_2_a as 
select ��ʧ������Ա  as ������Ա,
sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2_nt
where cut_date=&nt.
group by ��ʧ������Ա;
quit;


*********************************�ܿۿ������ӡ���V���пͷ������˻�*************************;
proc sql;
create table aa_vv1_nt as
select ����ɶ� as ������,sum(����_��������15�Ӻ�ͬ��ĸ) as ����ɶ��ͻ��� from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. group by ����ɶ�;
quit;

proc sql;
create table aa_vv2_nt as
select V�ۿ��� as ������,sum(����_��������15�Ӻ�ͬ��ĸ) as V���пۿ��� from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. group by V�ۿ���;
quit;

data aa_vv_nt;
merge aa_vv1_nt aa_vv2_nt;
by ������;
if ������=1;
run;

proc sql;
create table aa_cd1_nt as 
select ����ɶ� as ������,��ʧ������Ա as ������Ա,sum(����_��������15�Ӻ�ͬ��ĸ) as V�ۿ���
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա in ("�����","��ǨӢ","�ߺ�","Ԭ����","����")
group by ������,��ʧ������Ա;
quit;

proc sql;
create table aa_cd2_nt(drop=������) as
select a.*,b.* from aa_cd1_nt as a
left join aa_vv_nt as b on a.������=b.������;
quit;
proc sql;
create table assignment4_2_b_ as 
select ��ʧ������Ա  as ������Ա,sum(����_��������15�Ӻ�ͬ) as ������ʧ_nt,sum(����_��������15�Ӻ�ͬ��ĸ) as cd�ۿ��� from assignment2_nt
where cut_date<=&nt. group by ��ʧ������Ա;
quit;

proc sql;
create table assignment4_2_b as
select a.*,b.* from assignment4_2_b_ as a
left join aa_cd2_nt as b on a.������Ա=b.������Ա;
run;

data assignment4_2_b_;
set assignment4_2_b;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

data assignment4_2_b;
set assignment4_2_b_;

if ������Ա^="_����" then do;
�ܿۿ���_nt=round(cd�ۿ���+V�ۿ���/����ɶ��ͻ���*V���пۿ���,1);
��ʧ��_nt=������ʧ_nt/(cd�ۿ���+V�ۿ���/����ɶ��ͻ���*V���пۿ���);end;

if ������Ա="_����" then do;�ܿۿ���_nt=cd�ۿ���;��ʧ��_nt=������ʧ_nt/cd�ۿ���;end;

drop cd�ۿ��� V�ۿ��� ����ɶ��ͻ��� V���пۿ���;
run;

*********************************�ܿۿ������ӡ���V���пͷ������˻�*************************;

*************��Ӫҵ�����顿***************;
proc sql;
create table assignment4_2_aa as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ) as ������ʧ
from assignment2_nt
where cut_date=&nt. and ��ʧ������Ա^="_����" and ���Ϸ�Χ="5���ѹ��ŵ�"
group by Ӫҵ��;
quit;

**********************������ʧ���ӷ�ĸ********************;
proc sql;
create table assignment4_2_bb1 as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ) as ������ʧ_nt
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and ���Ϸ�Χ="5���ѹ��ŵ�" and ��ʧ������Ա^="_����"
group by Ӫҵ��;
quit;
proc sql;
create table assignment4_2_bb2 as 
select Ӫҵ��,sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���_nt
from assignment2_nt
where mdy(03,22,2019)<=cut_date<=&nt. and ���Ϸ�Χ="5���ѹ��ŵ�" and cut_date������Ա^="_����"
group by Ӫҵ��;
quit;
data assignment4_2_bb;
merge assignment4_2_bb1 assignment4_2_bb2;
by Ӫҵ��;
format ��ʧ��_nt percent7.2;
��ʧ��_nt=������ʧ_nt/�ܿۿ���_nt;
run;
**********************������ʧ���ӷ�ĸ********************;


**********************������ʧ���ӷ�ĸ********************;
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
select a.*,b.cut_date������Ա as ������Ա,b.�ͻ�����,b.���Ϸ�Χ,b.Ӫҵ��
from test_all as a 
left join assignment2_nt(where=(cut_Date=&nt.)) as b 
on a.contract_no=b.contract_no;
quit;

*************���ͷ���Ա���顿***************;
proc sql;
create table Tjia5 as 
select ������Ա,count(*) as T5 from tjia
group by ������Ա;
quit;
*************��Ӫҵ�����顿***************;
proc sql;
create table Tjia5a as 
select Ӫҵ��,count(*) as T5 from tjia
where ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111")
group by Ӫҵ��;
quit;

proc sql;
create table Tjia5_ as 
select contract_no,�ͻ�����,������Ա,repay_Date
from tjia;
quit;

*************���ͷ���Ա���顿***************;
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

*************��Ӫҵ�����顿***************;
proc sort data=yuqi17a;by Ӫҵ��;run;
proc sort data=yuqi815a;by Ӫҵ��;run;
proc sort data=Tjia5a;by Ӫҵ��;run;
proc sort data=nt_daikou1a;by Ӫҵ��;run;
proc sort data=nt_daikou_a;by Ӫҵ��;run;
proc sort data=nt_account_a;by Ӫҵ��;run;
proc sort data=assignment4_2_aa;by Ӫҵ��;run;
proc sort data=assignment4_2_bb;by Ӫҵ��;run;

data dangtian_a;
merge assignment6a  nt_account_a nt_daikou_a nt_daikou1a yuqi17a yuqi815a assignment4_2_aa assignment4_2_bb Tjia5a ;
by Ӫҵ��;

if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����");
run;

*************���ͷ���Ա���顿***************;
data dangtian1;
set dangtian;
format ��Ա $40.;
if ������Ա in ("�����","��ǨӢ","����","Ԭ����") then ��Ա="a_"||������Ա;
if ������Ա in ("�ߺ�","�Ķ���1111") then ��Ա="b_"||������Ա;
if ������Ա in ("�ۻԻ�111","�Ķ���111","л����111","�Ż�111","�ž�111","������111","��ï˼111") then ��Ա="c_"||������Ա;
if ������Ա in ("_����") then ��Ա="d_"||"��������";
drop ������Ա;
run;
proc sort data=dangtian1;by ��Ա;run;
data dangtian1_;
retain ��Ա;
set dangtian1;
if ��Ա="" then delete;
run;

data dangtian1_;
set dangtian1_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;



/*data assignment6;*/
/*set assignment6;*/
/*format ��Ա $40.;*/
/*if ������Ա in ("�����","�����","��ǨӢ") then ��Ա="a_"||������Ա;*/
/*if ������Ա in ("�ߺ�","�Ķ���111","����","Ԭ����") then ��Ա="b_"||������Ա;*/
/*if ������Ա in ("_����") then ��Ա="c_"||"��������";*/
/*drop ������Ա;*/
/*run;*/
/*proc sort data=assignment6;by ��Ա;run;*/
/*data assignment6;retain ��Ա;set assignment6;run;*/
/**/
/*filename DD DDE "EXCEL|[�ɶ����ձ���.xlsx]Sheet1!r4c1:r11c11";*/
/*data _null_;set assignment6;file DD;put  ��Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ��  ;run;*/


*************��Ӫҵ�����顿***************;
data dangtian_a1;
set dangtian_a;
format �ŵ� $40.;
if kindex(Ӫҵ��,"��ɽ") or kindex(Ӫҵ��,"��������") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����") then �ŵ�="v_"||Ӫҵ��;
drop Ӫҵ��;
run;
proc sort data=dangtian_a1;by �ŵ�;run;
data dangtian_a1_;retain �ŵ�;set dangtian_a1;run;

data dangtian_a1_;
set dangtian_a1_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;


/**/
/**/
/*PROC EXPORT DATA=assignment2_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����Ӧ����ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����������ϸ1"; RUN;*/
/**/
/**/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_4*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����Ӧ����ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_5*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����������ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=nt_daikou_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�ܴ�����ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=nt_daikou1_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="��ʣ�������ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=yuqi115_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="����1-15����ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_3*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_6*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ��ϸ"; RUN;*/
/**/
/*PROC EXPORT DATA=assignment2_7*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="�ܿۿ�����ϸ"; RUN;*/
/**/
/**/
/*PROC EXPORT DATA=Tjia5_*/
/*OUTFILE= "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx" DBMS=EXCEL REPLACE;SHEET="T��5������ϸ"; RUN;*/
/**/
/**/
/*x "F:\A_offline_zky\A_offline\daily\�ɶ�Ӫҵ�������������\�����޸�\�ɶ����ձ���.xlsx";*/
/**/
/*filename DD DDE "EXCEL|[�ɶ����ձ���.xlsx]Sheet1!r4c1:r17c21";*/
/*data _null_;set dangtian1_;file DD;put  ��Ա ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� Ŀǰ�˻��� ��������ܸ���  _TEMG001  yuqi17 yuqi815 ������ʧ ������ʧ_nt �ܿۿ���_nt ��ʧ��_nt T5 ;run;*/
/**/
/**/
/*filename DD DDE "EXCEL|[�ɶ����ձ���.xlsx]Sheet1!r17c1:r21c21";*/
/*data _null_;set dangtian_a1_;file DD;put  �ŵ� ����Ӧ�� �������� ���������� ����Ӧ�� �������� ���������� ������ʧ ������ʧ �ܿۿ��� ��ʧ�� Ŀǰ�˻��� ��������ܸ���  _TEMG001  yuqi17 yuqi815 ������ʧ ������ʧ_nt �ܿۿ���_nt ��ʧ��_nt T5 ;run;*/
