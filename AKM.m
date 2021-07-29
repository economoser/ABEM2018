disp('% =================================================================================')
disp('% AKM.m estimates person and establishment effects in Brazil')
disp('% using the 1988-2012 RAIS data set.')
disp('%')
disp('% INPUTS:')
disp('%        - CONNECTED_WITHHOURS_YYYY1_YYYY2.csv containing an array')
disp('%')
disp('%          [ employer ID lagged employer ID ]')
disp('%')
disp('%        - TOMATLAB_WITHHOURS_YYYY1_YYYY2.csv containing an array')
disp('%          [ earnings personID emplyerID age year ]')
disp('%')
disp('% OUTPUTS:')
disp('%        - TOSTATA_WITHHOURS_YYYY1_YYYY2.txt containing an array')
disp('%')
disp('%          [ personID year personFE firmFE demographics ]')
disp('%')
disp('% MATLAB BGL obtained from http://www.mathworks.com/matlabcentral/fileexchange/10922')
disp('%')
disp('% Thanks: Code is an adopted version of Card, Heining and Kline (2013)')
disp('%')
disp('%')
disp('% Princeton, 11/07/2014')
disp('% ==================================================================================')
tic

disp(['*****     RUNNING PERIOD ' num2str(yyyy1) ' - ' num2str(yyyy2) ' *****'])

% READ DIRECTORY:
r1 = [SAVE_MATLAB '/connected_' num2str(WITHHOURS) '_' num2str(yyyy1) '_' num2str(yyyy2) '.csv'];
r2 = [SAVE_MATLAB '/tomatlab_' num2str(WITHHOURS) '_' num2str(yyyy1) '_' num2str(yyyy2) '.csv'];

% OUTPUT DIRECTORY:
s1 = [SAVE_MATLAB '/tostata_' num2str(WITHAGE) num2str(WITHHOURS) '_' num2str(yyyy1) '_' num2str(yyyy2) '.txt'];



% -----------------------
%
% CONSTRUCT CONNECTED SET
%
% -----------------------
% read in data from stata
fid = fopen(r1);
data = fscanf(fid,'%d %d',[2 inf])';
fclose(fid);
firmid = data(:,1);
lagfirmid = data(:,2);
clear data r1 fid

% Relabel firms
N = length(firmid);
mm = length(lagfirmid);
if N ~= mm
    disp('Not the same number of firmids and lagfirmids')
    exit
end
    
% Unique returns the unique values, column n maps firms into old firm ids ([firmid;lagfirmid]=firms(n))
[firms,~,n] = unique([firmid;lagfirmid]);
firmid = n(1:N);
lagfirmid = n(N + 1:end);
clear n N

% Old firm IDs in rows, new firm IDs in columns
A = sparse(lagfirmid,firmid,1);
clear firmid lagfirmid
[mm,n] = size(A);

% By definition, this is square but check it
if mm>n
    A = [A,sparse(mm, mm - n,0)];
elseif mm<n
    A = [A;sparse(n - mm,n,0)];
end
clear mm n
% Doesn't matter if moving between i and j or j and i, it adds the same
% information for the purpose of the connected set estimation
A = max(A, A');

% This finds the connected sets of A
[sindex, sz] = components(A);

% Find the largest set
idx = find(sz == max(sz));

clear A sz s
% Identify the firms in the largest connected set
firmlst = find(sindex == idx); %firms in connected set
% Return to initial indexing of firms:
%   -   Output from 'unique' satiesfies firms(firmid) = firmidold
%   -   Connected set exercise generates a selection of firmid;
%   -   Hence, to recover original firmids type firms(firm1st).
firmlst = uint32(firms(firmlst));

clear sindex firmid lagfirmid firms idx



% ------------------------------------------------------
%
% RUN AKM ON LARGEST CONNECTED SET
%
% ------------------------------------------------------
fid = fopen(r2,'r');
data = fscanf(fid,'%f %u %u %u %u',[5 inf])';
fclose(fid);
y=data(:,1);
id=data(:,2);
firmid=data(:,3);
age=data(:,4);
year=data(:,5);
clear data r2 fid

disp('% INITIAL DESCRIPTIVE STATISTICS %')
s=['Total number of individual-years: ' int2str(length(y))];
disp(s);
s=['Total number of workers: ' int2str(length(unique(id)))];
disp(s);
s=['Total number of firm-years: ' int2str(length(unique(firmid)))];
disp(s);

% Select individuals in the largest connected set
sel=ismember(firmid,firmlst);
clear firmlst
y = y(sel);         id = id(sel);       firmid = firmid(sel);       
age = age(sel);     year = year(sel);
clear sel

disp(['Connected set number of individual-years: ' int2str(length(y))]);

% relabel workers
idold = id;
[ids,~,id] = unique(id);
disp(['Connected set number of workers: ' int2str(length(ids))]);
clear ids
% relabel firms
[firms,~,firmid] = unique(firmid);
disp(['Connected set number of firm: ' int2str(length(firms))]);
clear firms
fprintf('\n')
% relabel years
yearold = year;
[~,~,year] = unique(year);

% total number of observations
NT = length(y);
N = max(id); % total no. of workers
J = max(firmid); % total no. of firms
nrage = max(age)-min(age)+1;
nryears = max(year)-min(year)+1;

disp(['Number of years: ' int2str(nryears)]);
disp(['Number of age groups: ' int2str(nrage)]);

% include age controls?
if WITHAGE
	A = sparse(1:NT,age',1);
	clear age
	A = A(:,1:end-1);
	Y = sparse(1:NT,year',1);
	for t=3:nryears
		Y(:,t) = Y(:,t)-((t-1)*Y(:,2)-(t-2)*Y(:,1));
	end
	Y = Y(:,3:nryears);
	nryears = nryears-2;
     nrage = nrage-1;    
	clear year
else
	clear age
	Y = sparse(1:NT,year',1);
	clear year
	Y = Y(:,1:end-1);
	nryears=nryears-1;
end
% create sparse matrix of indicator variables for worker IDs
D = sparse(1:NT,id',1);
clear id
% sparse matrix of indicator variables for firm IDs
F = sparse(1:NT,firmid',1);
clear firmid
F = F(:,1:end-1);

if WITHAGE 
	disp(['The size of the matrix to invert is ' num2str(size(D,2)+size(F,2)+size(Y,2)+size(A,2)) ' times ' num2str(size(D,2)+size(F,2)+size(Y,2)+size(A,2))])
	X = [D'*D D'*F D'*Y D'*A; F'*D F'*F F'*Y F'*A; Y'*D Y'*F Y'*Y Y'*A; A'*D A'*F A'*Y A'*A];
else
	disp(['The size of the matrix to invert is ' num2str(size(D,2)+size(F,2)+size(Y,2)) ' times ' num2str(size(D,2)+size(F,2)+size(Y,2))])
	X = [D'*D D'*F D'*Y; F'*D F'*F F'*Y; Y'*D Y'*F Y'*Y];
end
disp('% Generated X %')

disp('% Inverting matrix')
whos
L = ichol(X,struct('type','ict','droptol',1e-2,'diagcomp',.1));
disp('% Completed inverting the matrix')
if WITHAGE
	b = pcg(X,[D'*y;F'*y;Y'*y;A'*y],1e-10,1000,L,L');
else
	b = pcg(X,[D'*y;F'*y;Y'*y],1e-10,1000,L,L');
end
disp('% Found the vector of coefficients')
clear X L

% reconstruct person effects
pe = D*b(1:N);
clear D
% reconstruct firm effects
fe = F*b(N + 1:N + J - 1);
clear F
% year effects
xb_year = Y*b(N + J:N + J + nryears - 1);
clear Y
if WITHAGE
	xb_age = A*b(N + J + nryears:N + J + nryears + nrage-1);
	clear A
else
	xb_age = zeros(NT,1);
end
clear b nrage nryears

fprintf('\n')
disp('% ANALYZE RESULTS %')
disp('Full Covariance Matrix of Components')
disp('    y      pe      fe       xb_year     xb_age')
C = cov([y,pe,fe,xb_year,xb_age]);
C = full(C);
disp(C)
fprintf('\n')

fid = fopen(s1,'w');
fprintf(fid,'%12s\t %12s\t %12s\t %12s\t %12s\t %12s\n','persid','ano','person','firm','xb_year','xb_age');
fprintf(fid,'%12.0f\t %12.0f\t %12.6f\t %12.6f\t %12.6f\t %12.6f\n',[idold';yearold';pe';fe';xb_year';xb_age']);
fclose(fid);

fprintf('\n')
disp('% =========================================================================')
disp('% FINISHED MATLAB')
disp('% =========================================================================')
toc
exit