addpath(genpath('./src'));% add misc helper functions to path
addpath(genpath('./sparseglm'));% add SPARSEGLM package from Mineault et al. to path
cc()
pairLabel = {'MF','MM'};% male-female (MF) or male-male (MM) data
difLabel = {'ONS','SNG'};% predict bout onsets (ONS) or full song (SNG)

% prepare basis
width = 64;
levels = 4;
step = 1;
FWHM = 2.5;
Bsingle = get1DLaplacianPyramidBasis(width,levels,step,FWHM);
[w, h] = size(Bsingle);

runs = 10; % number of cross-validation runs - we used *1000* in the paper - reduced here to speed up calc's
fps = 60; % frame-rate of videos and hence sampling rate of annotated data

%%
for pair = 1:2% either MF (male-female) or MM (male-male)
   dat = load(['dat/' pairLabel{pair} 'corr.mat']) %#ok<NOPTS>
   if pair == 1 % male-female
      sexLabel = {'female', 'male'};
   else         % male-male
      sexLabel = {'maleA', 'maleB'};
   end
   %%
   for dif = 1:2 % fit GLM to onsets of bouts ( diff(song) ) or full song
      for sex = 1:2 % either first or second fly (in MF - first is female? second is male?)
         clear r;
         % select correct responses and covariates and label for current sex
         if sex == 1
            y = dat.GESTURES(:,1);
            yLabel = dat.GESTURESlabels(1);
            X = dat.GESTURES(:,[2:end]);
            XLabel = dat.GESTURESlabels(2:end);
         else
            y = dat.GESTURES(:,2);
            yLabel = dat.GESTURESlabels(2);
            X = dat.GESTURES(:,[1 3:end]);
            XLabel = dat.GESTURESlabels([1 3:end]);
         end
         % differentiate (or not)
         if dif==1
            y = [0; diff(y)]>0;
         end
         
         disp(['Predicting ' yLabel{1} ', ' pairLabel{pair} ', ' sexLabel{sex} ', ' difLabel{dif}])
         % assemble basis and features with history
         X = zscore(X);
         U = ones(length(y),1);% bias term
         r.n = width;
         %  B = [];
         run = 1;
         while run<runs%for run =1:runs
            disp(['   run ' int2str(run)])
            try
               % 0. full model as target
               SSraw = [];
               B = zeros(size(X,2)*w, size(X,2)*h);
               for dim = 1:size(X,2);
                  SSraw = [SSraw makeStimRows(X(:,dim),width)];
                  % assemble the basis into one huge base
                  B((dim-1)*w+(1:w), (dim-1)*h+(1:h)) = Bsingle;
               end
               
               % remove all instances without song in history (all-zeros)
               y(all(SSraw==0,2)) = [];
               SSraw(all(SSraw==0,2),:) = [];
               
               % select random subset for each run
               oneIdx = find(y==1);
               r.N = floor(0.75*length(oneIdx));
               oneIdx = oneIdx(randperm(length(oneIdx),r.N));
               
               nulIdx = find(y==0);
               nulIdx = nulIdx(randperm(length(nulIdx),r.N));
               thisIdx = [oneIdx; nulIdx];
               
               XX = SSraw*B;% prj all features onto basis
               whitener = diag(1./std(XX,[],1));
               XX = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
               
               % fit GLM to all features
               fit = cvglmfitsparseprior(y(thisIdx),XX(thisIdx,:),U(thisIdx),getcvfolds(length(thisIdx),5),'modeltype','logisticr','modelextra',1);
               r.relDevRedFull(run) = 1-fit.deviance./fit.maxdeviance;
               r.filtFull(:,run) = B*whitener*fit.w;% unwhiten and project onto basis
               
               % 1. find best single feature
               for dim = 1:size(X,2);
                  SSraw = makeStimRows(X(:,dim),width);% this is not efficient - should use parts of SSraw generated in line 59
                  XX = SSraw*Bsingle;% prj features onto basis
                  whitener = diag(1./std(XX,[],1));
                  XX = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
                  fit = cvglmfitsparseprior(y(thisIdx),XX(thisIdx,:),U(thisIdx,:),getcvfolds(length(thisIdx),5),'modeltype','logisticr','modelextra',1);
                  r.relDevRed1(run,dim) = 1-fit.deviance./fit.maxdeviance;
                  r.filt1(:,run,dim) = Bsingle*whitener*fit.w;
               end
               
               % 2. find next best feature given the first best one
               % first, get the covariate associated with the best feature:
               SSraw = makeStimRows(X(:,argmax(r.relDevRed1(run,:))), width);
               XX = SSraw*Bsingle;% prj features onto basis
               whitener = diag(1./std(XX,[],1));
               XX0 = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
               
               for dim = 1:size(X,2)
                  SSraw = makeStimRows(X(:,dim),width);% this is not efficient - should use parts of SSraw generated in line 59
                  XX = SSraw*Bsingle;% prj features onto basis
                  whitener = diag(1./std(XX,[],1));
                  XX1 = XX*whitener; %Whiten to standard deviation = 1 (X*B*D)
                  fit = cvglmfitsparseprior(y(thisIdx), [XX0(thisIdx,:) XX1(thisIdx,:)], U(thisIdx), getcvfolds(length(thisIdx),5), 'modeltype', 'logisticr', 'modelextra', 1);
                  r.relDevRed2(run,dim) = 1-fit.deviance./fit.maxdeviance;
                  r.filt2(:,run,dim) = Bsingle*whitener*fit.w(size(Bsingle,2)+1:end);
               end
               run = run+1;
            catch ME
               disp(ME.getReport())
            end
         end
         if mfilename()
            save(['res/' mfilename() '_' pairLabel{pair} '_' sexLabel{sex} '_' difLabel{dif}],'r')
         end
      end
   end
end
