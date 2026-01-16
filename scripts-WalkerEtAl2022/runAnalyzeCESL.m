% Last updated by Bob Kopp, 2018-09-25 14:02:54 -0400

% set up  paths

% rootdir='~/Dropbox/Code/CESL-STEHM-GP';
rootdir='/Users/yg/Documents/GitHub/CESL-STEHM-GP';

% ---- macOS TeX / epstopdf + dependency preflight ----
% MATLAB launched from Finder/Dock often does not inherit your shell PATH.
% Ensure TeX binaries (epstopdf) are available for pdfwrite().
setenv('PATH', [getenv('PATH') ':/Library/TeX/texbin']);

[st_epstopdf, out_epstopdf] = system('command -v epstopdf');
if st_epstopdf~=0
    if exist('/Library/TeX/texbin/epstopdf','file')
        warning('epstopdf not found on PATH, but exists at /Library/TeX/texbin/epstopdf. pdfwrite() will try that path explicitly.');
    else
        warning(['epstopdf not found. PDF conversion from EPS may fail. ' ...
                 'Install MacTeX/TeXLive or add epstopdf to PATH.']);
    end
else
    disp(['epstopdf: ' strtrim(out_epstopdf)]);
end

% Check for required MATLAB toolboxes/functions (fail fast with clear message).
if exist('saoptimset','file')==0 || exist('simulannealbnd','file')==0
    error(['Missing Global Optimization Toolbox (saoptimset/simulannealbnd). ' ...
           'Install/enable it or change training to avoid simulated annealing.']);
end
if exist('fmincon','file')==0
    error('Missing Optimization Toolbox (fmincon). Install/enable it.');
end
if exist('normcdf','file')==0
    warning('normcdf not found (Statistics toolbox). Rate tables may fail; install Statistics and Machine Learning Toolbox.');
end
if exist('geoshow','file')==0 || exist('shaperead','file')==0
    warning(['Mapping functions (geoshow/shaperead) not found. ' ...
             'If mapping fails later, set doMapField=0 or install Mapping Toolbox.']);
end

pd=pwd;
addpath([rootdir '/MFILES']); % add the path with the core MFILES
addpath([rootdir '/scripts-WalkerEtAl2022']); % add the path with the script files
% addpath('/scripts-WalkerEtAl2022'); % add the path with the script files
% IFILES=[rootdir '/IFILES']; % point to the directory with the data files
IFILES=[rootdir '/IFILES-WalkerEtAl2022']; % point to the directory with the data files
IFILES2=[rootdir '/IFILES-working'];
addpath(pd);
savefile='~/tmp/CESL'; % point to the .mat file you want the analysis to be backed up into 

WORKDIR=[pd '/workdir-010621ToE']; % point to the working directory you want your tables and figures dumped from
if ~exist(WORKDIR,'dir')
    mkdir(WORKDIR);
end
cd(WORKDIR);

PXdatafile=fullfile(IFILES,'RSL_All_17Mar2020.tsv');
latlim=[-90 90]; longlim=[-180 180];

runImportCESLDataSets;
runMapSites;

runSetupCESLCovariance;

% set up and run hyperparameter optimization

%trainspecs=1:length(modelspec); % identify the different model specifications (as defined in runSetupCESLCovariance) 
                          % that will be trained
trainspecs=9;
trainsets =ones(size(trainspecs))*1; % identify the different datasets (in the structure datasets created by runImportCESLDataSeta)
                           % that will be used for each specification
trainfirsttime = -2000; % don't use data before trainfirsttime (default: -1000 CE) for training

trainlabels={};
for ii=1:length(trainsets)
    trainlabels = {trainlabels{:}, [datasets{trainsets(ii)}.label '_' modelspec(trainspecs(ii)).label]};
end

cacheLoaded = false;
if exist(savefile,'file')
    try
        cache = load(savefile);
        if isfield(cache,'thetTGG') && isfield(cache,'trainsubsubset')
            thetTGG = cache.thetTGG;
            trainsubsubset = cache.trainsubsubset;
            if isfield(cache,'thethist'); thethist = cache.thethist; end
            if isfield(cache,'logp'); logp = cache.logp; end
            cacheLoaded = true;
            disp(['Loaded trained model cache: ' savefile]);
        else
            warning(['Cache file missing required variables; will retrain: ' savefile]);
        end
    catch ME
        warning(['Failed to load cache (will retrain): ' savefile ' : ' ME.message]);
    end
end

if ~cacheLoaded
    runTrainModels;

    save thetTGG thetTGG trainsubsubset
    save(savefile,'-v7.3');
end

thetTGG0=thetTGG;

% now do a prediction
testt = [0:20:1800 1810:10:2010]; % ages for regression

runSelectPredictionSites;

% select regression parameters

regressparams=1; % which trained hyperparameters to use
regresssets=ones(size(regressparams))*1; % which data set to use with each
clear regresslabels;
for i=1:length(regresssets)
    regresslabels{i} = [datasets{regresssets(i)}.label '_' trainlabels{regressparams(i)}];
end

dosldecomp = 0; % make sldecomp plots for each site
doMapField = 1; % make maps of the field

runPredictCESL;
