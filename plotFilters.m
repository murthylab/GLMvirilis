addpath(genpath('./src'));% add misc helper functions to path
cc()
pairLabel = {'MF','MM'};
difLabel = {'ONS','SNG'};
% prepare basis
% width = 64;
% levels = 4;
% step = 1;
% FWHM = 2.5;
% [w, h] = size(Bsingle);
% 
runs = 1000; % number of cross-validation runs
fps = 60;

%%
for pair = 1:2
   dat = load(['dat/' pairLabel{pair} 'corr.mat']) %#ok<NOPTS>
   if pair == 1
      sexLabel = {'female', 'male'};
   else
      sexLabel = {'maleA', 'maleB'};
   end
   %%
   for dif = 1:2
      for sex = 1:2;
         clear r;
         % select correct response and covariates and label for current sex
         if sex == 1
            y = dat.GESTURES(:,1);
            yLabel = dat.GESTURESlabels(1);
            X = dat.GESTURES(:,[2:end]);
            XLabel = dat.GESTURESlabels(2:end);
         else
            y = dat.GESTURES(:,2);%[0; diff(dat.GESTURESCopy(:,1))]>0;
            yLabel = dat.GESTURESlabels(2);
            X = dat.GESTURES(:,[1 3:end]);
            XLabel = dat.GESTURESlabels([1 3:end]);
         end
         % differentiate (or not)
         if dif==1
            y = [0; diff(y)]>0;
         end
         disp(['loading res/fitFilters_' pairLabel{pair} '_' sexLabel{sex} '_' difLabel{dif}])
         load(['res/fitFilters_' pairLabel{pair} '_' sexLabel{sex} '_' difLabel{dif}],'r')
         
         % define colors to match other figs in paper
         if sex==1
            cols = [ 0 0 0.7; 0.5 0.5 0.5 ; 0 0 0; 0.5 0 0.5 ];
         else
            cols = [0.8 0 0 ;0.5 0.5 0.5 ; 0 0 0; 0.5 0 0.5 ];
         end
         clf
         % plot single-var fits
         subplot(2,3,1)
         for ii = 1:4
            hold on
            hb(ii) = barwitherr(std(r.relDevRed1(:,ii),1), ii, mean(r.relDevRed1(:,ii),1), 'FaceColor',cols(ii,:));
         end
         hline(mean(r.relDevRedFull));
         legend(hb, XLabel,'Location','NorthWest')
         set(gca,'XTick',1:4,'XTickLabel', XLabel,'XTickLabelRotation',60,'YLim',[0 1])
         ylabel('rel. dev. red.')
         title('single var model')
         subplot(2,3,2:3)
         
         % ???
         x = (-r.n:-1)/fps*1000;% time scale
         y = squeeze(mean(r.filt1,2));% mean over bootstrap runs
         e = squeeze(std(r.filt1,[],2));% errorbar is std over bootstrap runs
         
         hold on
         for ii = 1:4
            [hl(ii,:),he(ii,:)] = confplot(x,  y(:,ii)',e(:,ii)');
            set(hl(ii,:), 'Color', cols(ii,:))
            set(he(ii,:), 'FaceColor', cols(ii,:), 'FaceAlpha',0.2)
         end
         set(hl,'LineWidth',2)
         axis('tight')
         hline(0)
         ylabel(['p(' sexLabel{sex} ' song)'])
         legend(hl, XLabel,'Location','NorthWest')
         drawnow
         % plot two-var fits
         subplot(2,3,4)
         for ii = 1:4
            hold on
            hb(ii) = barwitherr(std(r.relDevRed2(:,ii),1), ii, mean(r.relDevRed2(:,ii),1), 'FaceColor',cols(ii,:));
         end
         hline(mean(r.relDevRedFull))
         hline(max(mean(r.relDevRed1,1)))
         set(gca,'XTick',1:4,'XTickLabel', XLabel,'XTickLabelRotation',60,'YLim',[0 1])
         ylabel('rel. dev. red.')
         title('two var model')
         
         subplot(2,3,5:6)
         x = (-r.n:-1)/fps*1000;% time scale
         y = squeeze(mean(r.filt2,2));% mean over bootstrap runs
         e = squeeze(std(r.filt2,[],2));% errorbar is std over bootstrap runs
         
         hold on
         for ii = 1:4
            [hl(ii,:),he(ii,:)] = confplot(x,  y(:,ii)',e(:,ii)');
            set(hl(ii,:), 'Color', cols(ii,:))
            set(he(ii,:), 'FaceColor', cols(ii,:), 'FaceAlpha',0.2)
         end
         set(hl,'LineWidth',2)
         axis('tight')
         hline(0)
         ylabel(['p(' sexLabel{sex} ' song)'])
         legend(hl, XLabel,'Location','NorthWest')
         xlabel(['time rel. to ' sexLabel{sex} ' song [ms]'])
         %%
         set(gcas,'Color','none','box','off')
         if mfilename()
            figexp(['fig/' mfilename() '_' pairLabel{pair} '_' sexLabel{sex} '_' difLabel{dif}],.8,.8)
         end
      end
   end
end