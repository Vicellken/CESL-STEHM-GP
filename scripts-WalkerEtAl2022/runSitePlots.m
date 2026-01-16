% For each site, make a plot
%
% Last updated by Robert Kopp, robert-dot-kopp-at-rutgers-dot-edu, 2018-09-25 14:28:34 -0400


figure;
    
maxdistfrom=0.1;
maxerror=1000;
wtestlocs=testlocs{iii};
if ~isstruct(wtestlocs) || ~all(isfield(wtestlocs,{'sites','names','reg','X'}))
    if exist('testsites','var') && exist('testreg','var') && exist('testX','var')
        wtestlocs = struct();
        wtestlocs.sites = testsites;
        wtestlocs.reg = testreg;
        wtestlocs.X = testX;
        if exist('testnames2','var')
            wtestlocs.names = testnames2;
            wtestlocs.names2 = testnames2;
        elseif exist('testnames','var')
            wtestlocs.names = testnames;
            wtestlocs.names2 = testnames;
        else
            wtestlocs.names = arrayfun(@(k) sprintf('site-%d',k), (1:size(testsites,1))', 'UniformOutput', false);
            wtestlocs.names2 = wtestlocs.names;
        end
        warning('runSitePlots: rebuilt testlocs from workspace variables due to invalid testlocs cell content.');
    else
        error('runSitePlots: testlocs{%d} is not a struct with sites/names/reg/X; rerun prediction or clear cached variables.', iii);
    end
end
doNoiseMask=1;
doPlotData=1;

for kkk=1:size(wtestlocs.sites,1)

    disp(wtestlocs.names{kkk});

    clf;
    subplot(2,1,1);

    sub=find(wtestlocs.reg==wtestlocs.sites(kkk,1));
    if wtestlocs.sites(kkk,2)<360
        distfrom=dDist(wtestlocs.sites(kkk,2:3),[wdataset.lat wdataset.long]);
        subD=find(distfrom<maxdistfrom);
    else
        subD=find((wdataset.lat==wtestlocs.sites(kkk,2)).*(wdataset.lat==wtestlocs.sites(kkk,3)));
    end
    subD=intersect(subD,find(wdataset.dY<maxerror));


    plotdat.x=wtestlocs.X(sub,3);
    plotdat.y=f2s{iii}(sub,doNoiseMask);
    plotdat.dy=sd2s{iii}(sub,doNoiseMask)*2;

    PlotWithShadedErrors(plotdat,[0 0 0]);
    if doPlotData
        for uuu=subD(:)'
            plot([wdataset.time1(uuu) wdataset.time2(uuu)],wdataset.Y0(uuu)-2*wdataset.dY(uuu)*[1 1],'r'); hold on;
            plot([wdataset.time1(uuu) wdataset.time2(uuu)],wdataset.Y0(uuu)+2*wdataset.dY(uuu)*[1 1],'r');
            plot([wdataset.time1(uuu) wdataset.time1(uuu)],wdataset.Y0(uuu)+2*wdataset.dY(uuu)*[-1 1],'r');
            plot([wdataset.time2(uuu) wdataset.time2(uuu)],wdataset.Y0(uuu)+2*wdataset.dY(uuu)*[-1 1],'r');
        end
    end
    plot(plotdat.x,plotdat.y,'k','linew',2);
    plot(plotdat.x,plotdat.y-plotdat.dy,'k--','linew',1);
    plot(plotdat.x,plotdat.y+plotdat.dy,'k--','linew',1);

    title([wtestlocs.names{kkk} ' (' num2str(wtestlocs.sites(kkk,1)) ')']);
    xl=get(gca,'xlim');
    xl(2)=2010; xl(1)=max([-2000 xl(1)]);
    xlim(xl);
    ylabel('Sea level (mm)');
    xlabel('Year (CE)');
    pdfwrite(['siteplot-' wtestlocs.names{kkk} labl '_' noiseMasklabels{doNoiseMask}]);

end
