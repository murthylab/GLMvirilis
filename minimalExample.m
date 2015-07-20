addpath(genpath('./src'));% add misc helper functions to path
addpath(genpath('./sparseglm'));% add SPARSEGLM package from Mineault et al. to path
cc()
pairLabel = {'MF','MM'};% male-female (MF) or male-male (MM) data
difLabel = {'ONS','SNG'};% predict bout onsets (ONS) or full song (SNG)

%%
pair = 1% either MF (male-female) or MM (male-male)
dat = load(['dat/' pairLabel{pair} 'corr.mat']) %#ok<NOPTS>
if pair == 1 % male-female
   sexLabel = {'female', 'male'};
else         % male-male
   sexLabel = {'maleA', 'maleB'};
end
%%
sex = 1;
dif = 2
clear r;
% select correct responses and covariates and label for current sex
y = dat.GESTURES(:,1);
yLabel = dat.GESTURESlabels(1);
X = dat.GESTURES(:,[end]);
XLabel = dat.GESTURESlabels(end);

disp(['Predicting ' yLabel{1} ', ' pairLabel{pair} ', ' sexLabel{sex} ', ' difLabel{dif}])

% prepare basis
width = 64;
levels = 4;
step = 1;
FWHM = 2.5;
Bsingle = get1DLaplacianPyramidBasis(width,levels,step,FWHM);
[w, h] = size(Bsingle);
% assemble basis and features with history
% X = zscore(X);
U = ones(length(y),1);% bias term
r.n = width;


% fit GLM to first feature
dim = 3;
SSraw = makeStimRows(X,width);% generate stimulus matrix
% remove all instances without song in history (all-zeros)
y(all(SSraw==0,2)) = [];
SSraw(all(SSraw==0,2),:) = [];
%% project stimulus onto basis and whiten
XX = SSraw*Bsingle;% prj all features onto basis
whitener = diag(1./std(XX,[],1));
XX = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
%%
fit = cvglmfitsparseprior(y,XX(:,dim),U,getcvfolds(length(y),2),'modeltype','logisticr','modelextra',1);
relDevRed = 1-fit.deviance./fit.maxdeviance;
filt = Bsingle*whitener*fit.w;% unwhiten and project onto basis
