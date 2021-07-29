% -------------------------------------------------------------------------
% Produces 3d residual plot in ABEM (2017)
% -------------------------------------------------------------------------
clear all; close all; clc
% directory where data is stored
DIR = 'U:\Work\P1. AEM\';
r1= [DIR '3dresidual_byperiod_lset.csv'];

% read in data
Data=csvread(r1);
firm_quantil=Data(:,1);
person_quantil=Data(:,2);
resid=Data(:,3);
num_worker_years=Data(:,4);
period=Data(:,6);
N=length(resid);

%rows are persons, columns are firm quantiles (Y(right) is rows)
Z=reshape(resid(1:100),10,10);
figure
bar3(Z)
xlabh = get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
ylabel('Firm effect decile')
xlabel('Worker effect decile')
saveas(gcf,[DIR '3dresid_1988_1992.eps'],'eps');

T=(N-100+1);
Z=reshape(resid(T:N),10,10);
figure
bar3(Z)
xlabh = get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
ylabel('Firm effect decile')
xlabel('Worker effect decile')
saveas(gcf,[DIR '3dresid_2008_2012.eps']);

total=sum(num_worker_years(1:100));
Z=reshape(num_worker_years(1:100)/total,10,10);
figure
bar3(Z)
ylabel('Firm effect decile')
xlabel('Worker effect decile')
xlabh = get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
saveas(gcf,[DIR '3dfreq_1988_1992.eps']);

T=(N-100+1);
total=sum(num_worker_years(T:N));
Z=reshape(num_worker_years(T:N)/total,10,10);
figure
bar3(Z)
ylabel('Firm effect decile')
xlabel('Worker effect decile')
xlabh = get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
saveas(gcf,[DIR '3dfreq_2008_2012.eps']);