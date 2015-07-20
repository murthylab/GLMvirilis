addpath(genpath('./src'));% add misc helper functions to path
addpath(genpath('./sparseglm'));% add SPARSEGLM package from Mineault et al. to path
cc()

% prepare basis - see help for get1DLaplacianPyramidBasis
width = 32;
levels = 4;% 
step = 1;% 
FWHM = 2.5;% 
Bsingle = get1DLaplacianPyramidBasis(width,levels,step,FWHM);
[w, h] = size(Bsingle);


dat = load('dat/MFcorr.mat'); % load data

% get responses Y and data X from structure
y = dat.GESTURES(:,1);% T x 1
yLabel = dat.GESTURESlabels(1);
X = dat.GESTURES(:,[2:end]);% T x nFeature
XLabel = dat.GESTURESlabels(2:end);

X = zscore(X);% zscore each feature so that filter norm corresponds to importance of feature
U = ones(length(y),1);% bias term - all ones

% select random subset for each run - balance data such that
% each event type has the same frequency in training data
oneIdx = find(y==1);% '1' events
N = floor(0.75*length(oneIdx));
oneIdx = oneIdx(randperm(length(oneIdx),N));

nulIdx = find(y==0);% '0' events
nulIdx = nulIdx(randperm(length(nulIdx),N));
thisIdx = [oneIdx; nulIdx];

% 1. find best single feature - fit one model for each feature
for dim = 1:size(X,2);
   SSraw = makeStimRows(X(:,dim),width);% this is not efficient - should use parts of SSraw generated in line 59
   XX = SSraw*Bsingle;% prj features onto basis
   whitener = diag(1./std(XX,[],1));
   XX = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
   % This is doing the actual fitting - performs crossvalidation
   % (see GETCVFOLDS) to select optimal regularization parameter.
   % Since we predict binary responses [0, 1], we us a binomial GLM with a
   % logsitic link function (output NL)
   fit = cvglmfitsparseprior(y(thisIdx),XX(thisIdx,:),U(thisIdx,:),getcvfolds(length(thisIdx),5),'modeltype','logisticr','modelextra',1);
   relDevRed1(dim) = 1-fit.deviance./fit.maxdeviance;% model performance - varies between 0 and 1, comparable to r2 for binary data
   filt1(:,dim) = Bsingle*whitener*fit.w;% recover filter - unwhiten and project back into original stimulus space
end
%% plot results
subplot(1,3,1:2)
plot(-32:-1,filt1 )
legend(XLabel)
title('filters')

subplot(1,3,3)
bar(relDevRed1 )
title('model performance')
set(gca,'XTickLabel',XLabel)
ylabel('rel. deviance reduction')
xlabel('feature')