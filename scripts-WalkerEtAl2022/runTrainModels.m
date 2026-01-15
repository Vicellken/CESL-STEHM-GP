% Optimize hyperparameters for different model structures.
%
% Last updated by Robert Kopp, robert-dot-kopp-at-rutgers-dot-edu, 2018-06-15 19:09:51 -0400

trainrange=[100 100 100]; % optimize only using data with age errors < 100 yrs

% ---- checkpoint/resume support ----
% Training can take many hours. We checkpoint after each major optimization step,
% and resume from the checkpoint on rerun to avoid restarting from scratch.
checkpointFile = fullfile(pwd,'checkpoint_train.mat');

clear thetTGG thethist trainsubsubset logp;

if exist(checkpointFile,'file')
    try
        ck = load(checkpointFile);
        if isfield(ck,'trainspecs') && isequal(ck.trainspecs,trainspecs) && isfield(ck,'trainsets') && isequal(ck.trainsets,trainsets)
            if isfield(ck,'thetTGG'); thetTGG = ck.thetTGG; end
            if isfield(ck,'thethist'); thethist = ck.thethist; end
            if isfield(ck,'trainsubsubset'); trainsubsubset = ck.trainsubsubset; end
            if isfield(ck,'logp'); logp = ck.logp; end
            disp(['Loaded training checkpoint: ' checkpointFile]);
        else
            warning(['Checkpoint exists but does not match current trainspecs/trainsets; ignoring: ' checkpointFile]);
        end
    catch ME
        warning(['Failed to load checkpoint (will start fresh): ' checkpointFile ' : ' ME.message]);
    end
end

% Write a fresh snapshot file each time (avoid duplicated lines on resume).
thetTGG_tsv = fullfile(pwd,'thetTGG.tsv');

for ii=1:length(trainspecs)

    disp(trainlabels{ii});
    ms = modelspec(trainspecs(ii));

    % If resuming and this entry already has results, skip it.
    if exist('thetTGG','var') && length(thetTGG)>=ii && ~isempty(thetTGG{ii})
        disp(['Skipping trainspec index ' num2str(ii) ' (already in checkpoint).']);
        continue;
    end
    
    try
        % first only fit ones without a compaction correction
        [thetTGG{ii},trainsubsubset{ii},logp(ii),thethist{ii}]= ...
            OptimizeHoloceneCovariance(datasets{trainsets(ii)}, ...
                                       ms,[3.4 3.0],trainfirsttime,trainrange,.01);

        checkpointTimestamp = datestr(now); checkpointStage = 'post_first_opt';
        save(checkpointFile,'thetTGG','thethist','trainsubsubset','logp', ...
             'trainspecs','trainsets','trainfirsttime','trainrange', ...
             'checkpointTimestamp','checkpointStage','ii','-v7.3');

    % now add compaction correction factor
%    ms = modelspec(trainspecs(ii));
%    ms.thet0 = thetTGG{ii}(1:end-1);
%    ms.subfixed = 1:length(ms.thet0);
%    [thetTGG{ii},trainsubsubset{ii},logp(ii),thist]= ...
%        OptimizeHoloceneCovariance(datasets{trainsets(ii)}, ...
%                                   ms,[3.4 3.0],trainfirsttime(end),trainrange(end),1e6);   
%    thethist{ii}=[thethist{ii}; thist];

    
    % now final local optimization
        ms = modelspec(trainspecs(ii));
        ms.thet0 = thetTGG{ii}(1:end-1);
        startcompact = thetTGG{ii}(end);
        [thetTGG{ii},trainsubsubset{ii},logp(ii),thist]= ...
            OptimizeHoloceneCovariance(datasets{trainsets(ii)}, ...
                                       ms,[3.0],trainfirsttime(end),trainrange(end),1e6,startcompact);   
        thethist{ii}=[thethist{ii}; thist];

        checkpointTimestamp = datestr(now); checkpointStage = 'post_final_local_opt';
        save(checkpointFile,'thetTGG','thethist','trainsubsubset','logp', ...
             'trainspecs','trainsets','trainfirsttime','trainrange', ...
             'checkpointTimestamp','checkpointStage','ii','-v7.3');
    catch ME
        % Save what we have so far, then rethrow.
        checkpointTimestamp = datestr(now); checkpointStage = 'error';
        try
            save(checkpointFile,'thetTGG','thethist','trainsubsubset','logp', ...
                 'trainspecs','trainsets','trainfirsttime','trainrange', ...
                 'checkpointTimestamp','checkpointStage','ii','ME','-v7.3');
        catch
            % ignore secondary failures
        end
        rethrow(ME);
    end

    
    % Write a snapshot table of completed results (overwrite).
    fid=fopen(thetTGG_tsv,'w');
    fprintf(fid,'set\ttraining data\tmodel\tlogp\tN\n');
    for iii=1:length(trainspecs)
        if exist('thetTGG','var') && length(thetTGG)>=iii && ~isempty(thetTGG{iii})
            fprintf(fid,[trainlabels{iii} '\t' datasets{trainsets(iii)}.label '\t' ...
                         modelspec(trainspecs(iii)).label]);
            fprintf(fid,['\t(%0.2f)'],logp(iii));
            fprintf(fid,'\t%0.0f',length(trainsubsubset{iii}));
            fprintf(fid,'\t%0.3f',thetTGG{iii});
            fprintf(fid,'\n');
        end
    end
    fclose(fid);
end

