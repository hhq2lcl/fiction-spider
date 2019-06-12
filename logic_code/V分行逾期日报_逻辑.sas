/*option compress = yes validvarname = any;*/
/*libname res  'F:\A_offline_zky\kangyi\data_download\ԭ��\res';*/
/*libname csdata 'F:\A_offline_zky\kangyi\data_download\ԭ��\csdata';*/
/*libname account 'F:\A_offline_zky\kangyi\data_download\ԭ��\account';*/
/*libname repayfin 'F:\A_offline_zky\kangyi\data_download\�м��\repayAnalysis';*/
/**/
/*libname cd "F:\A_offline_zky\A_offline\weekly\V���������ձ�\chengdu_data";*/
/*libname ss1 "F:\A_offline_zky\A_offline\daily\�ռ��\��ʷ����\��ʷ��������\201905";*ÿ���޸��������·�;*/


data aa;
format dt db yymmdd10.;
 dt=today()-1;
 db=intnx("month",dt,0,"b");
 nd= dt-db+60;
 week_begin=mdy(06,10,2019);*��עÿ�ܸ�һ��;
 week_end=mdy(06,16,2019);*��עÿ�ܸ�һ��;
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("week_begin",week_begin);
call symput("week_end", week_end);
run;

*ÿ�ܸ���һ��;
%let x1=6; 
%let y1=8;*��3-5��   ��6-8��  ��9-11����12-14����15-17��;

%let x2=22;
%let y2=24;*��19-21����22-24����25-27����28-30����31-33��;

%let x3=38;
%let y3=40;*��35-37����38-40����41-43����44-46����47-49��;


data payment_daily;
set ss1.payment_daily(where=(cut_date^=mdy(5,31,2019) and Ӫҵ��^="APP"))
	repayfin.payment_daily(where=( Ӫҵ��^="APP"));
if  kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"֣��") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"����")
 or kindex(Ӫҵ��,"���") or kindex(Ӫҵ��,"��ͨ") or kindex(Ӫҵ��,"�Ͼ�") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") then �ŵ�="a_"||Ӫҵ��;
else if kindex(Ӫҵ��,"��ɽ") or  kindex(Ӫҵ��,"��������") or  kindex(Ӫҵ��,"����") or  kindex(Ӫҵ��,"տ��") or kindex(Ӫҵ��,"����")
	 or kindex(Ӫҵ��,"�γ�") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"����") or kindex(Ӫҵ��,"�����") or kindex(Ӫҵ��,"�Ϸ�")
	then �ŵ�="b_"||Ӫҵ��;
	else �ŵ�="����";
run;

proc sql;
create table assignment1 as
select a.*,b.userName as ��ʧ������Ա,b.�������� as ��ʧ��������,c.userName as cut_date������Ա,c.�������� as cut_date��������
from payment_daily as a
left join cd.assignment as b on a.contract_no=b.contract_no and a.repay_date=b.cut_date
left join cd.assignment as c on a.contract_no=c.contract_no and a.cut_date=c.cut_date;
quit;

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
run;

*****************************��1-15��߻ء�****************************;
data cuihui_1;
set payment_daily(keep=CONTRACT_NO �ͻ����� Ӫҵ�� �ŵ� ����_��������15�Ӻ�ͬ REPAY_DATE cut_date);
if &db.<=cut_date<=&week_end.;
run;

data cuihui_2;
set payment_daily(keep=CONTRACT_NO ����_���տۿ�ʧ�ܺ�ͬ REPAY_DATE cut_date);
if &db.-16<=cut_date<=&week_end.-16;
format ��ĸcut_date YYmmdd10.;
��ĸcut_date=cut_date+16;
drop cut_date;
run;
proc sql;
create table cuihui_3 as
select a.* ,b.* from cuihui_1 as a
left join cuihui_2 as b on a.contract_no = b.contract_no and cut_date=��ĸcut_date;
quit;

data cuihui_4;
set cuihui_3;
if ����_���տۿ�ʧ�ܺ�ͬ="." and ����_��������15�Ӻ�ͬ=1 then ����_��������15�Ӻ�ͬ=1;
if &db.<=��ĸcut_date<=&week_end.;
run;

********************week�߻���**************************;
proc sql;
create table cuihui_week as
select �ŵ�,sum(����_��������15�Ӻ�ͬ) as ����δ�߻ط���,sum(����_���տۿ�ʧ�ܺ�ͬ) as ���ܴ߻ط�ĸ
from cuihui_4
where ��ĸcut_date>=&week_begin.
group by �ŵ�;
quit;

data cuihui_week;
set cuihui_week;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;
data cuihui_w;
set cuihui_week;
format ����15��߻��� percent7.2;
�߻ط���=���ܴ߻ط�ĸ-����δ�߻ط���;
����15��߻���=1-����δ�߻ط���/���ܴ߻ط�ĸ;
run;

********************MTD�߻���****************************;
proc sql;
create table cuihui_mtd as
select �ŵ�,sum(����_��������15�Ӻ�ͬ) as ����δ�߻ط���,sum(����_���տۿ�ʧ�ܺ�ͬ) as ���ܴ߻ط�ĸ
from cuihui_4
group by �ŵ�;
quit;

data cuihui_mtd;
set cuihui_mtd;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;
data cuihui_m;
set cuihui_mtd;
format ����15��߻��� percent7.2;
�߻ط���=���ܴ߻ط�ĸ-����δ�߻ط���;
����15��߻���=1-����δ�߻ط���/���ܴ߻ط�ĸ;
run;


data cuihui_5;
set cuihui_4;
if ����_��������15�Ӻ�ͬ=1 or ����_���տۿ�ʧ�ܺ�ͬ=1;
if ����_��������15�Ӻ�ͬ=1 then delete;
keep CONTRACT_NO �ͻ����� Ӫҵ�� ��ĸcut_date REPAY_DATE;
rename ��ĸcut_date=cut_date;
run;

******************************�������ʡ�*****************************;
********************week������**************************;
proc sql;
create table liuru_w as 
select �ŵ�,sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment1
where &week_begin.<=cut_date<=&week_end.
group by �ŵ�;
quit;

********************MTD������**************************;
proc sql;
create table liuru_m as 
select �ŵ�,sum(����_����Ӧ�ۿ��ͬ) as ����Ӧ��,sum(����_���տۿ�ʧ�ܺ�ͬ) as ��������,
sum(����_���տۿ�ʧ�ܺ�ͬ)/sum(����_����Ӧ�ۿ��ͬ) as ���������� format percent7.2
from assignment1
where &db.<=cut_date<=&week_end.
group by �ŵ�;
quit;

data liuru_1;
set assignment1;
if ����_����Ӧ�ۿ��ͬ=1 or ����_���տۿ�ʧ�ܺ�ͬ=1;
if &db.<=cut_date<=&week_end.;
if ����_���տۿ�ʧ�ܺ�ͬ=1;
keep CONTRACT_NO �ͻ����� Ӫҵ�� cut_date;
run;

data liuru_2;
set assignment1;
if ����_����Ӧ�ۿ��ͬ=1 or ����_���տۿ�ʧ�ܺ�ͬ=1;
if &db.<=cut_date<=&week_end.;
keep CONTRACT_NO �ͻ����� Ӫҵ�� cut_date;
run;


******************************����ʧ�ʡ�******************************;
********************week��ʧ��**************************;
proc sql;
create table liushi_w as 
select �ŵ�,sum(����_��������15�Ӻ�ͬ) as ������ʧ,sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ������ʧ�� format percent7.2
from assignment1
where &week_begin.<=cut_date<=&week_end.
group by �ŵ�;
quit;

********************MTD��ʧ��**************************;
proc sql;
create table liushi_m as 
select �ŵ�,sum(����_��������15�Ӻ�ͬ) as ������ʧ,sum(����_��������15�Ӻ�ͬ��ĸ) as �ܿۿ���,
sum(����_��������15�Ӻ�ͬ)/sum(����_��������15�Ӻ�ͬ��ĸ) as ������ʧ�� format percent7.2
from assignment1
where &db.<=cut_date<=&week_end.
group by �ŵ�;
quit;


data liushi_1;
set assignment1;
if ����_��������15�Ӻ�ͬ=1 or ����_��������15�Ӻ�ͬ��ĸ=1;
if &db.<=cut_date<=&week_end.;
if ����_��������15�Ӻ�ͬ=1;
keep CONTRACT_NO �ͻ����� Ӫҵ�� cut_date;
run;

data liushi_2;
set assignment1;
if ����_��������15�Ӻ�ͬ=1 or ����_��������15�Ӻ�ͬ��ĸ=1;
if &db.<=cut_date<=&week_end.;
keep CONTRACT_NO  �ͻ����� Ӫҵ�� cut_date;
run;

**************week***************************;
proc sort data=liuru_w;by �ŵ�;run;
proc sort data=liushi_w;by �ŵ�;run;
proc sort data=cuihui_w;by �ŵ�;run;
data benzhou_;
merge liuru_w liushi_w cuihui_w;
by �ŵ�;

drop ����δ�߻ط���;
run;
data benzhou;
set benzhou_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

*****************************MTD*****************************************;
proc sort data=liuru_m;by �ŵ�;run;
proc sort data=liushi_m;by �ŵ�;run;
proc sort data=cuihui_m;by �ŵ�;run;
data mtd_;
merge liuru_m liushi_m cuihui_m;
by �ŵ�;

drop ����δ�߻ط���;
run;
data mtd;
set mtd_;
array num _numeric_;
do over num;
if num=. then num=0;
end;
run;

/**/
/*PROC EXPORT DATA=cuihui_4*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="����1-15��߻�"; RUN;*/
/*PROC EXPORT DATA=liuru_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="��������"; RUN;*/
/*PROC EXPORT DATA=liuru_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="����Ӧ��"; RUN;*/
/*PROC EXPORT DATA=liushi_1*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="������ʧ"; RUN;*/
/*PROC EXPORT DATA=liushi_2*/
/*OUTFILE= "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx" DBMS=EXCEL REPLACE;SHEET="���ܿۿ�"; RUN;*/
/**/
/*x "F:\A_offline_zky\A_offline\weekly\V���������ձ�\V���������ձ�(MTD).xlsx";*/
/**/
/************************��week��******************;*/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]WEEK!r3c&x1.:r25c&y1.";*��3-5����6-8����9-11����12-14��;*/
/*data _null_;set benzhou;file DD;put	����Ӧ��  ��������	����������;run;*/
/**/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]WEEK!r3c&x2.:r25c&y2.";*/
/*data _null_;set benzhou;file DD;put	������ʧ  �ܿۿ���	������ʧ��;run;*/
/**/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]WEEK!r3c&x3.:r25c&y3.";*��35-37����38-40��;*/
/*data _null_;set benzhou;file DD;put	�߻ط���  ���ܴ߻ط�ĸ	����15��߻���;run;*/
/**/
/************************��MTD��******************;*/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]MTD!r3c&x1.:r25c&y1.";*��3-5����6-8����9-11����12-14��;*/
/*data _null_;set mtd;file DD;put	����Ӧ��  ��������	����������;run;*/
/**/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]MTD!r3c&x2.:r25c&y2.";*��19-21����22-24��;*/
/*data _null_;set mtd;file DD;put	������ʧ  �ܿۿ���	������ʧ��;run;*/
/**/
/*filename DD DDE "EXCEL|[V���������ձ�(MTD).xlsx]MTD!r3c&x3.:r25c&y3.";*/
/*data _null_;set mtd;file DD;put	�߻ط���  ���ܴ߻ط�ĸ	����15��߻���;run;*/
