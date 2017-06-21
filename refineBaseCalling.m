% Load transcripts and ROIs
loadParameters;
save_type = 'fig';

load(fullfile(params.transcriptResultsDir,sprintf('%s_transcriptsv9.mat',params.FILE_BASENAME)));

if ~exist('puncta_set','var')
    load(fullfile(params.punctaSubvolumeDir,sprintf('%s_puncta_rois.mat',params.FILE_BASENAME)));
end

%%
%Create vectors in a cell array that will take all raw pixels from which we
%will create the distributions
raw_pixels = cell(params.NUM_ROUNDS,params.NUM_CHANNELS,2);
%Note that the third index is as follows:
%1 = background
%2 = signal
IDX_BACKGROUND =1;
IDX_SIGNAL = 2;
%Initialize each entry as a list
for chan_idx = 1:params.NUM_CHANNELS
    for exp_idx = 1:params.NUM_ROUNDS
        raw_pixels{exp_idx,chan_idx,1} = [];
        raw_pixels{exp_idx,chan_idx,2} = [];
    end
end

%Create mean and min values for each channel and each round
min_values = zeros(params.NUM_ROUNDS,params.NUM_CHANNELS);
mean_values = zeros(params.NUM_ROUNDS,params.NUM_CHANNELS);
for exp_idx = 1:params.NUM_ROUNDS
    clear chan_col
    
    for c = params.COLOR_VEC
        chan_col(:,c) = reshape(puncta_set(:,:,:,exp_idx,c,:),[],1);
    end
  
    min_values(exp_idx,:) = min(chan_col,[],1);
    %Take the mean after subtracting the min
    mean_values(exp_idx,:) = mean(chan_col - repmat(min_values(exp_idx,:),size(chan_col,1),1),1);
    
end

%Now loop through all puncta (non-normalized) and, depending on which was
%called by the normalized comparison (in normalizePunctaVector.m) put the
%center 5x6x6 pixels into the vectors that will create the distirbution
% central_puncta_indices = ...
%     ceil(params.PUNCTA_SIZE/2 - params.DISTANCE_FROM_CENTER):ceil(params.PUNCTA_SIZE/2 + params.DISTANCE_FROM_CENTER);
central_puncta_indices= 5:6;
for puncta_idx = 1:size(puncta_set,6)
    for exp_idx = 1:params.NUM_ROUNDS
        %Get which channel was called for a puncta and round
        winning_index = transcripts(puncta_idx,exp_idx);
        background_indices = setdiff(params.COLOR_VEC,winning_index);
        
        % For the winner, get the central 2x2x2 volume, linearize it
        % and add into the vector
        subvolume = puncta_set(central_puncta_indices,...
            central_puncta_indices,...
            central_puncta_indices,...
            exp_idx,...
            winning_index, puncta_idx);
        %process the subvolume to subtract the mean and divi
        subvolume = (subvolume(:) - min_values(exp_idx,winning_index))...
           /mean_values(exp_idx,winning_index);
%         subvolume = subvolume(:); %testing without normalization 
        raw_pixels{exp_idx,winning_index,IDX_SIGNAL} = ...
            [raw_pixels{exp_idx,winning_index,IDX_SIGNAL}; subvolume];
        
        %For the other background rounds, add the linearized subvolume
        %to the respective vecotrs
        for other_index = background_indices
            subvolume = puncta_set(central_puncta_indices,...
                central_puncta_indices,...
                central_puncta_indices,...
                exp_idx,...
                other_index, puncta_idx);
            subvolume = (subvolume(:) - min_values(exp_idx,other_index))...
               /mean_values(exp_idx,other_index);
%             subvolume = subvolume(:); %testing without normalization 
            
            raw_pixels{exp_idx,other_index,IDX_BACKGROUND} = ...
                [raw_pixels{exp_idx,other_index,IDX_BACKGROUND}; subvolume];
        end
    end
    if mod(puncta_idx,100)==0
        fprintf('Processed puncta %i/%i\n',puncta_idx,size(puncta_set,6));
    end
end

%% Let's look at some histograms!

for exp_idx = 1:params.NUM_ROUNDS
    figure('Visible','off');
    
    subplot(params.NUM_CHANNELS,1,1);
    for chan_idx = params.COLOR_VEC
        subplot(params.NUM_CHANNELS,1,chan_idx);
        %Load all the raw pixels
        chanvec_bg = raw_pixels{exp_idx,chan_idx,IDX_BACKGROUND};
        chanvec_sig = raw_pixels{exp_idx,chan_idx,IDX_SIGNAL};
        
        %Remove the top 1% of data so we can visualize cleaner histograms
        percentiles_bg  = prctile(chanvec_bg,[0,99]);
        percentiles_sig = prctile(chanvec_sig,[0,99]);
        %Instead of deleting we'll instead just cap the value to the 99%
        outlierIndex_bg = chanvec_bg > percentiles_bg(2);
        chanvec_bg(outlierIndex_bg) = percentiles_bg(2);
        outlierIndex_sig = chanvec_sig > percentiles_sig(2);
        chanvec_sig(outlierIndex_sig) = percentiles_sig(2);
        
        fprintf('Removed %.03f and %.03f outliers for bg and sig, respectively\n',...
               sum(outlierIndex_bg)/length(raw_pixels{exp_idx,chan_idx,IDX_BACKGROUND}),...
               sum(outlierIndex_sig)/length(raw_pixels{exp_idx,chan_idx,IDX_SIGNAL}));
        
        
        %Concatenate the two so we can get proper bucket edges
        [values,binedges] = histcounts([chanvec_bg; chanvec_sig],params.NUM_BUCKETS);
        
        [values_bg,binedges_bg] = histcounts(chanvec_bg,binedges);
        [values_sig,binedges_sig] = histcounts(chanvec_sig,binedges);
        
        
        b = bar(binedges(1:params.NUM_BUCKETS),values_bg,'b');
        b.FaceAlpha = 0.3;
        hold on;
        b = bar(binedges(1:params.NUM_BUCKETS),values_sig,'r');
        b.FaceAlpha = 0.3;
        hold off;
        title(sprintf('Non-normalized histograms of puncta intensities. Experiment %i, Color %i',exp_idx, chan_idx));
        legend('Background','Signal');
       
        figfilename = fullfile(params.reportingDir,...
             sprintf('%s-distributionsOfSigVsBg-round%i.%s','basecalling',exp_idx,save_type)); 
        saveas(gcf,figfilename,save_type)
    end
end


%% Making a distribution for every color, round

%Each probability will be an Nx2 vector, containing both the center of the
%histogram edges and the probability
%so it's a 5D vector...
probabilities = zeros(params.NUM_ROUNDS,params.NUM_CHANNELS,params.NUM_BUCKETS,2,2);
IDX_HIST_VALUES = 1;
IDX_HIST_BINS = 2;
for exp_idx = 1:params.NUM_ROUNDS
    
    for chan_idx = params.COLOR_VEC
        %Load all the raw pixels
        chanvec_bg = raw_pixels{exp_idx,chan_idx,IDX_BACKGROUND};
        chanvec_sig = raw_pixels{exp_idx,chan_idx,IDX_SIGNAL};
        
        %Make the binedges by concaneating both distributions from this
        %channel
        [values,binedges] = histcounts([chanvec_bg; chanvec_sig],params.NUM_BUCKETS);
        
        %Then use our createEmpDistributionFromVector function to make the
        %distributions
        [p,b] = createEmpDistributionFromVector(chanvec_bg,binedges);
        probabilities(exp_idx,chan_idx,:,IDX_BACKGROUND,IDX_HIST_VALUES) = p;
        probabilities(exp_idx,chan_idx,:,IDX_BACKGROUND,IDX_HIST_BINS) = b;
        [p,b] = createEmpDistributionFromVector(chanvec_sig,binedges);
        probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_VALUES) = p;
        probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_BINS) = b;
    end
end

%% Plot all probabilities for a sanity check
figure('Visible','off');
subplot(params.NUM_ROUNDS,length(params.COLOR_VEC),1);
ctr = 1;
for exp_idx = 1:params.NUM_ROUNDS
    for chan_idx = params.COLOR_VEC
        subplot(params.NUM_ROUNDS,length(params.COLOR_VEC),ctr);
        plot(squeeze(probabilities(exp_idx,chan_idx,:,IDX_BACKGROUND,IDX_HIST_BINS)),squeeze(probabilities(exp_idx,chan_idx,:,IDX_BACKGROUND,IDX_HIST_VALUES)),'LineWidth',2);
        hold on;
        plot(squeeze(probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_BINS)),squeeze(probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_VALUES)),'LineWidth',2)
        hold off;
        ctr = ctr +1;
        
        title(sprintf('Exp%i, Chan%i',exp_idx,chan_idx))
    end
end

figfilename = fullfile(params.reportingDir,...
sprintf('%s-probabilities.%s','basecalling',save_type));
saveas(gcf,figfilename,save_type)
%% Correct way of calculating probabilistic transcripts
% Need the comparative transcripts too for this
central_puncta_indices= 5:6;

%Do this for one experiment
prob_transcripts = zeros(size(puncta_set,6),params.NUM_ROUNDS, params.NUM_CHANNELS);
for exp_idx = 1:params.NUM_ROUNDS
    % Make color priors for the channels per experiment
    color_prior = zeros(1,params.NUM_CHANNELS);
    for chan_idx = params.COLOR_VEC
        color_prior(chan_idx) = sum(transcripts(:,exp_idx)==chan_idx)/...
            size(transcripts,1);
    end
    fprintf('Color prior for round%i %.2f %.2f %.2f %.2f\n',exp_idx,color_prior)
    for puncta_idx = 1:size(puncta_set,6)
        for chan_idx = params.COLOR_VEC
            
            % Get the central pixels to query the joint distribution of their
            % occurance
            subvolume = puncta_set(central_puncta_indices,...
                central_puncta_indices,...
                central_puncta_indices,...
                exp_idx,...
                chan_idx, puncta_idx);
            % Use the pre-calcualated min and mean values to normalize the
            % puncta
            subvolume = (subvolume(:) - min_values(exp_idx,chan_idx))...
                /mean_values(exp_idx,chan_idx);
            
            p_sig = squeeze(probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_VALUES));
            b_sig = squeeze(probabilities(exp_idx,chan_idx,:,IDX_SIGNAL,IDX_HIST_BINS));
            
            %calculateJointProbability creates sum of log probabilities
            jprob_sig = calculateJointProbability(max(subvolume),p_sig,b_sig);
            
            other_indices = setdiff(params.COLOR_VEC,chan_idx);
            probabilities_of_backgrounds = zeros(1,length(other_indices));
            ctr = 1;
            for other_index = other_indices
                subvolume = puncta_set(central_puncta_indices,...
                    central_puncta_indices,...
                    central_puncta_indices,...
                    exp_idx,...
                    other_index, puncta_idx);
                % Use the pre-calcualated min and mean values to normalize the
                % puncta
                subvolume = (subvolume(:) - min_values(exp_idx,other_index))...
                    /mean_values(exp_idx,other_index);
                
                p_bg = squeeze(probabilities(exp_idx,other_index,:,IDX_BACKGROUND,IDX_HIST_VALUES));
                b_bg = squeeze(probabilities(exp_idx,other_index,:,IDX_BACKGROUND,IDX_HIST_BINS));
                
                probabilities_of_backgrounds(ctr) = calculateJointProbability(max(subvolume),p_bg,b_bg);
                ctr = ctr +1;
            end
            
            prob_transcripts(puncta_idx,exp_idx,chan_idx) = ...
                log(color_prior(chan_idx)) + sum(probabilities_of_backgrounds)...
                + sum(jprob_sig);
        end
        
        if mod(puncta_idx,100)==0
            fprintf('Processed puncta %i for exp %i \n',puncta_idx, exp_idx)
        end
    end
    
end

%% Comparing to other transcript
%prob_transcripts is just for experiment 1, so transcripts(:,1)
agreements = zeros(size(puncta_set,6),params.NUM_ROUNDS);

%Looping over all minimum numbers of agreements between the probabilty and
%intensity methods to get a sense of agreement level
for THRESHOLD_AGREEMENT = 1:params.NUM_ROUNDS
    calls_total_prob = zeros(params.NUM_ROUNDS,params.NUM_CHANNELS);
    calls_total_intensity = zeros(params.NUM_ROUNDS,params.NUM_CHANNELS);
    
    for exp_idx = 1:params.NUM_ROUNDS
        [~,prob_calls] = max(squeeze(prob_transcripts(:,exp_idx,:)),[],2);
        
        %Agreements is the number of roundagreements between the probability
        %and intensity methods
        agreements(:,exp_idx) = prob_calls == transcripts(:,exp_idx);
        
        transcripts_probsolo(:,exp_idx) = prob_calls;
        
        %Confidence here will simply be the raw probability value
        for puncta_idx = 1:size(puncta_set,6)
            transcripts_probsolo_confidence(puncta_idx,exp_idx) = ...
                squeeze(prob_transcripts(puncta_idx,exp_idx,prob_calls(puncta_idx)));
        end
        
        for c = params.COLOR_VEC
            calls_total_prob(exp_idx,c) = sum(prob_calls==c);
            calls_total_intensity(exp_idx,c) = sum(transcripts(:,exp_idx)==c);
        end
    end
    
    %How many puncta agree on ALL ROUNDS?
    indices_interAndIntraAgreements = sum(agreements,2)>=THRESHOLD_AGREEMENT;
    threshold_scores(THRESHOLD_AGREEMENT) = sum(indices_interAndIntraAgreements);
end

figure('Visible','off'); 
plot(threshold_scores); 
title('Agreements as a function of threshold');
figfilename = fullfile(params.reportingDir,...
sprintf('%s-agreementsBetweenMethods.%s','basecalling',save_type));
saveas(gcf,figfilename,save_type)


indices_interAndIntraAgreements = sum(agreements,2)>=params.THRESHOLD_AGREEMENT_CHOSEN;

fprintf('Removed %i transcripts that were under params.THRESHOLD_AGREEMENT_CHOSEN=%i\n',...
        size(agreements,1)-length(indices_interAndIntraAgreements),...
        params.THRESHOLD_AGREEMENT_CHOSEN);


transcripts_probfiltered = transcripts(indices_interAndIntraAgreements,:);
transcripts_probfiltered_confidence = transcripts_confidence(indices_interAndIntraAgreements,:);
transcripts_probfiltered_probconfidence = transcripts_probsolo_confidence(indices_interAndIntraAgreements,:);

%Create a list of indices back to the original puncta indices
%Used for later visualization
puncta_indices_probfiltered = 1:length(indices_interAndIntraAgreements);
puncta_indices_probfiltered = puncta_indices_probfiltered(indices_interAndIntraAgreements);

%filter the puncta_set here - it takes a surprising amount of memory to apply the boolean list to the 6D array. On my computer a 4GB puncta_set swells to 30GB, not sure why
puncta_set_filtered = puncta_set(:,:,:,:,:,puncta_indices_probfiltered);

save(fullfile(params.transcriptResultsDir,sprintf('%s_transcripts_probfiltered.mat',params.FILE_BASENAME)),...
    'prob_transcripts',...
    'transcripts_probfiltered',...
    'transcripts_probfiltered_confidence',...
    'transcripts_probfiltered_probconfidence',...
    'puncta_indices_probfiltered',...
    '-v7.3');

save(fullfile(params.transcriptResultsDir,sprintf('%s_puncta_rois_filtered.mat',params.FILE_BASENAME)),...
    'puncta_set_filtered',...
    '-v7.3');

disp('Saved the file in the transcripts directory');