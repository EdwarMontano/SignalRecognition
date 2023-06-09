***********************************************************
***********************************************************
********* BASIC SOURCE SEPARATION CODE, 23 Jan 1996 *******
********* Tony Bell, **************************************
********* CNL, Salk Institute, PO Box 85800, San Diego ****
********* tony@salk.edu, ********************************** 
********* http://www.cnl.salk.edu/~tony/ ******************
***********************************************************
***********************************************************
****************** If you find this useful, ***************
************** I appreciate an acknowledgement! ***********
***********************************************************
***********************************************************

Below are 5 MATLAB files.

1. readsounds.m, for reading the data in
2. sep.m, the code for one learning pass thru the data
3. sepout.m, for optional text output
4. wchange.m, tracks size and direction of weight changes 
5. sep.run, an example script for 2->2 separation

The following variables are used:

sweep:    how many times you've gone thru the data
P:        how many timepoints in the data
N:        how many input (mixed) sources there are
M:        how many outputs you have
L:        learning rate
B:        batch-block size (ie: how many presentations per weight update.)
t:        time index of data
sources:  NxP matrix of the N sources you read in
x:        NxP matrix of mixtures
u:        MxP matrix of hopefully unmixed sources
a:        NxN mixing matrix
w:        MxN unmixing matrix (actually w*wz is the full unmixing matrix
          in this case)
wz:       zero-phase whitening: a matrix used to remove 
          correlations from between the mixtures x. Useful as a 
          preprocessing step.
noblocks: how many blocks in a sweep;
oldw:     value of w before the last sweep
delta:    w-oldw
olddelta: value of delta before the last sweep
angle:    angle in degrees between delta and olddelta
change:   squared length of delta vector 
Id:       an identity matrix
permute:  a vector of length P used to scramble the time order of the
          sources for stationarity during learning.

INITIAL w ADVICE: identity matrix is a good choice, since, for prewhitened
data, there will be no distracting initial correlations, and the output
variances will be nicely scaled so <uu^T>=4I, right size to fit the 
logistic fn (more or less).

LEARNING RATE ADVICE: 
N=2: L=0.01 works
N=8-10: L=0.001 is stable. Run this till the 'change' report settles
down, then anneal a little. L=0.0005,0.0002,0.0001 etc, a few passes
(= a few 10,000's of data vectors) each pass.
N>100: L=0.001 works well on sphered image data.

***********************************************************
*************************readsounds.m**********************
***********************************************************
<<<<<cut here>>>>

% READSOUNDS looks in a directory "sounds/" for sound files  and 
%   returns them in a NxP matrix called "sounds" where N is the number 
%   of sounds specified, and P is the length of the shortest one (the 
%   others are truncated). One caveat: the filenames MUST all have the 
%   same number of characters since they are stored in a matrix (what else?!).
%
%   Example call: 
%         sounds=readsounds(['word2';'word1']);

function sounds=readsounds(files)
  minlen=1e10;
  for fileno=1:size(files,1),
    fprintf('reading %s \n', files(fileno,:));
    temp=auread(['/home/tony/Matlab/sounds/' files(fileno,:)])';
    len=size(temp,2);
    if minlen>len, minlen=len; end;
    sounds(fileno,1:minlen)=temp(1:minlen);
  end;
  sounds=sounds(:,1:minlen);

<<<<<cut here>>>>
***********************************************************
*************************sep.m*****************************
***********************************************************
<<<<<cut here>>>>
% SEP goes once through the scrambled mixed speech signals, x 
% (which is of length P), in batch blocks of size B, adjusting weights,
% w, at the end of each block.
%
% I suggest a learning rate L, of 0.01 at least for 2->2 separation.
% But this will be unstable for higher dimensional data. Test it.
% Use smaller values. After convergence at a value for L, lower
% L and it will fine tune the solution.
%
% NOTE: this rule is the rule in our NC paper, but multiplied by w^T*w,
% as proposed by Amari, Cichocki & Yang at NIPS '95. This `natural
% gradient' method speeds convergence and avoids the matrix inverse in the 
% learning rule.

sweep=sweep+1; t=1;
noblocks=fix(P/B);
BI=B*Id;
for t=t:B:t-1+noblocks*B,
  u=w*x(:,t:t+B-1); 
  w=w+L*(BI+(1-2*(1./(1+exp(-u))))*u')*w;
end;
sepout

<<<<<cut here>>>>
*********************************************************************
**********sepout.m: for various textual output during learning*******
*********************************************************************
<<<<<cut here>>>>

% SEPOUT - put whatever textual output report you want here.
%  Called after each pass through the data.
%  If your data is real, not artificially mixed, you will need
%  to comment out line 4, since you have no idea what the matrix 'a' is.
% 
[change,olddelta,angle]=wchange(oldw,w,olddelta); 
oldw=w;
fprintf('****sweep=%d, change=%.4f angle=%.1f deg., [N%d,M%d,P%d,B%d,L%.5f] \n',...
   sweep,change,180*angle/pi,N,M,P,B,L);
w*wz*a     %should be a permutation matrix for artif. mixed data.

<<<<<cut here>>>>
*********************************************************************
********wchange.m: tracks size and direction of weight changes ******
*********************************************************************
<<<<<cut here>>>>

function [change,delta,angle]=wchange(w,oldw,olddelta)
  [M,N]=size(w); delta=reshape(oldw-w,1,M*N);
  change=delta*delta';
  angle=acos((delta*olddelta')/sqrt((delta*delta')*(olddelta*olddelta')));

<<<<<cut here>>>>
*********************************************************************
*************sep.run: an example script for 2->2 separation *********
*********************************************************************
<<<<<cut here>>>>

%*************** setup sources **********
format compact

%**** if you are mixing the sources yourself:

sources=readsounds(['word2';'word1']); % see "help readsounds"
sources=readsounds(['word2';'word1';'whdru';'whis1';'whis2';'wittg';'whdr2';'whdr3']); % see "help readsounds"
  % write your own code here, since readsounds looks for audiofiles.
  % All you want is a NxP matrix (N=no of mixtures/sources, P=no. of data points)
[N,P]=size(sources);                 % P=17408, N=2, for example
permute=randperm(P);                 % generate a permutation vector
s=sources(:,permute);                % time-scrambled inputs for stationarity

a=[1 2; 1 1]                         % mixing matrix, or:  a=rand(N);
x=a*s;                               % mix input signals (permuted)
mixes=a*sources;                     % make mixed sources (not permuted)

%**** if you are loading already-mixed sources:

mixes=readsounds(['mix2';'mix1']);  % see "help readsounds"

%**** sphere the data
mx=mean(mixes'); c=cov(mixes');
x=x-mx'*ones(1,P);                   % subtract means from mixes
wz=2*inv(sqrtm(c));                  % get decorrelating matrix
x=wz*x;                              % decorrelate mixes so cov(x')=4*eye(N);

%**** 
%w=[1 1; 1 2];                       % init. unmixing matrix, or w=rand(M,N);
w=eye(N);                            % init. unmixing matrix, or w=rand(M,N);
M=size(w,2);                            % M=N usually
sweep=0; oldw=w; olddelta=ones(1,N*N);
Id=eye(M);

%************* this learns: "help sep" explains all 

L=0.01; B=30; sep    % should converge on 1 pass for 2->2 net
L=0.001; B=30; sep   % but annealing will improve soln even more 
L=0.0001; B=30; sep  % and so on

%for multiple sweeps:
L=0.005; B=30; for I=1:10000, sep; end;
%***************************************

mixes=a*sources;       % make mixed sources
sound(mixes(1,:))      % play the first one (if it is audio)
plot(mixes(1,:))       % plot the first one (if it is another signal)
uu=w*wz*mixes;            % make unmixed sources
sound(uu(1,:))         % play the first one (if it is audio)
plot(uu(1,:))          % plot the first one (if it is another signal)