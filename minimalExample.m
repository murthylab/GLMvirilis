addpath(genpath('./src'));% add misc helper functions to path
addpath(genpath('./sparseglm'));% add SPARSEGLM package from Mineault et al. to path
cc()

% prepare basis
width = 64;
levels = 4;
step = 1;
FWHM = 2.5;
Bsingle = get1DLaplacianPyramidBasis(width,levels,step,FWHM);
[w, h] = size(Bsingle);
% assemble basis and features with history
% X = zscore(X);
r.n = width;

% !! model stimulus
X = randn(1000,1);
% !! model stimulus

% fit GLM to first feature
SSraw = makeStimRows(X,width);% generate stimulus matrix

% !! model response
filterGaus = gausswin(width,10);% define model filter as a Gaussian bump
filterGaus = filterGaus./norm(filterGaus);% normalize
threshold = 1;
y = double(SSraw*filterGaus>threshold);% filter and threshold to get output
% !! model response

% remove all instances without song in history (all-zeros)
y(all(SSraw==0,2)) = [];
SSraw(all(SSraw==0,2),:) = [];
U = ones(length(y),1);% bias term
%% project stimulus onto basis and whiten
XX = SSraw*Bsingle;% prj all features onto basis
whitener = diag(1./std(XX,[],1));
XX = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
%% estimate filter
fit = cvglmfitsparseprior(y,XX,U,getcvfolds(length(y),2),'modeltype','logisticr','modelextra',1);

relDevRed = 1-fit.deviance./fit.maxdeviance;% model performance
filt = Bsingle*whitener*fit.w;% unwhiten filter weights and project onto basis
% filtered stimulus + bias term FIT.U
linPred = SSraw*filt + fit.u;
% binary prediction
binPred = linPred>0;
%% plot results
clf
subplot(221)
plot([filt./norm(filt) filterGaus])
axis('tight')
legend({'estimated filter', 'true filter'})

% predict linear response
subplot(222)
plot(linPred, y, '.k', 'MarkerSize', 18)
xlabel('linear prediction')
ylabel('response')

% predict binary response
subplot(212)
plot(y)
hold on
plot(binPred,'.')
title(sprintf(' performance = %1.2f', relDevRed))
xlabel('time')
legend({'response', 'prediction'})

