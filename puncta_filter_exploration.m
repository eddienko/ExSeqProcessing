loadParameters;

%This loads puncta_centroids and puncta_voxels (the list of voxel INDICES)
%per puncta
filename_centroids = fullfile(params.punctaSubvolumeDir,sprintf('%s_centroids+pixels.mat',params.FILE_BASENAME));
load(filename_centroids)

%% Make a big matrix of all the rounds being connected to all the other rounds

%make a holder vector of the sizes of all
num_puncta_per_round = zeros(params.NUM_ROUNDS,1);
for rnd_idx = 1:params.NUM_ROUNDS
    num_puncta_per_round(rnd_idx) = size(puncta_centroids{rnd_idx},1);
end


%% Examine the nearest neighbor of every pixel and flag it as a possible
% merge error in another round
MERGE_DISTANCE = 5;

for demerge_iter = 1:2
    
    merge_flags = calculateMergeFlags(puncta_centroids,MERGE_DISTANCE);
    
    
    %--------Collect all possible puncta paths from the perfect matching
    
    % REF_ROUND = 6;
    THRESHOLD_DISTANCE = 10;
    % punctaA = puncta_centroids{REF_ROUND};
    
    % master_row = sparse(num_puncta_per_round(REF_ROUND),sum(num_puncta_per_round));
    %possible_options_round = ones(size(punctaA,1),1);
    all_possible_punctapaths = zeros(sum(num_puncta_per_round),params.NUM_ROUNDS);
    
    %The row is the reference round, the col is the moving round
    %A is row
    demerge_indices = cell(params.NUM_ROUNDS,1);
    delete_indices = cell(params.NUM_ROUNDS,1);
    for rnd_idx_A = 1:params.NUM_ROUNDS
        
        fprintf('Finding puncta paths for ref_round=%i\n',rnd_idx_A);
        row_offset = sum(num_puncta_per_round(1:(rnd_idx_A-1)));
        
        punctaA = puncta_centroids{rnd_idx_A};
        demerge_indices_per_round = zeros(size(punctaA,1),1);
        %B is column
        for rnd_idx_B = 1:params.NUM_ROUNDS
            %When the moving = ref, it's just the identity
            if rnd_idx_B == rnd_idx_A
                for rndA_puncta_idx = 1:size(punctaA,1)
                    all_possible_punctapaths(row_offset+rndA_puncta_idx,rnd_idx_B)=rndA_puncta_idx;
                end
                continue;
            end
            punctaB = puncta_centroids{rnd_idx_B};
            
            %Output of matchPuncta is the size of punctaA. If there are no
            %matches, the index is zero. There is also no distance filtering,
            %so that has to be done here.
            [matches_AB,distances_AB] = matchPuncta(punctaA,punctaB);
            
            for match_idx = 1:length(matches_AB) %which is also size of (punctaA,1)
                if (matches_AB(match_idx)==0) || (distances_AB(match_idx)>THRESHOLD_DISTANCE)
                    %Leave that entry blank if the perfect matching came back
                    %with nothing, or if the distances to a match is too far
                    all_possible_punctapaths(row_offset+match_idx,rnd_idx_B) = -1;
                else
                    all_possible_punctapaths(row_offset+match_idx,rnd_idx_B)=matches_AB(match_idx);
                end
            end
        end
        
        fprintf('\tSearching for possible merge errors...');
        %Question: For all the punctaB we just matched with punctaA as the reference,
        %How many punctaA centroids are less than the mode of the merge
        %flag?
        
        %Get the list of all the punctapaths we just generated
        possible_puncta_path_subset = all_possible_punctapaths((row_offset+1):(row_offset+length(matches_AB)),:);
        
        %Get rid of any puncta path with a missing puncta in it.
        possible_puncta_path_subset_filtered = possible_puncta_path_subset(...
            sum(possible_puncta_path_subset==-1,2)==0,:);
        
        %Now, for the rnd_idx A reference location, check for any case where the
        %merge flag of rnd_idx A is less than the mode of its matches
        merge_flag_rndA = merge_flags{rnd_idx_A};
        
        for pp_idx = 1:size(possible_puncta_path_subset_filtered,1)
            puncta_indices_per_round = possible_puncta_path_subset_filtered(pp_idx,:);
            
            merge_flags_for_puncta_path = zeros(params.NUM_ROUNDS,1);
            for rnd_idx =1:params.NUM_ROUNDS
                merge_flags_for_puncta_path(rnd_idx) = merge_flags{rnd_idx}(puncta_indices_per_round(rnd_idx));
            end
            merge_flag_rndA = merge_flags_for_puncta_path(rnd_idx_A);
            
            %If the merge flag for rndA is less than the mode of the merge
            %flags in the other rounds connected to rndAs puncta, then it's
            %likely rndA is a merge problem and is flagged for duplication.
            if merge_flag_rndA < mode(merge_flags_for_puncta_path)
                demerge_indices_per_round(puncta_indices_per_round(rnd_idx_A))=1;
            end
        end
        
        fprintf('Found %i\n',sum(demerge_indices_per_round));
        demerge_indices{rnd_idx_A} = demerge_indices_per_round;
        
        %Maybe later we could also create a list of puncta to remove from
        %consideration if they are very clearly extraneous. In this case, if
        %the mode of the puncta path is -1.
    end
    
    % ----- For all the de-merged indices, duplicate them!
    
    for rnd_idx = 1:params.NUM_ROUNDS
        current_round_centroids = puncta_centroids{rnd_idx};
        current_round_centroids_baseguess = puncta_baseguess{rnd_idx};
        current_round_demerge_flags = demerge_indices{rnd_idx};
        extra_centroids = [];new_centroids_ctr = 1;
        extra_centroids_baseguess = [];
        for p_idx = 1:size(current_round_centroids,1)
            if logical(current_round_demerge_flags(p_idx))
                extra_centroids(new_centroids_ctr,:) = current_round_centroids(p_idx,:);
                extra_centroids_baseguess(new_centroids_ctr) = current_round_centroids_baseguess(p_idx);
                new_centroids_ctr = new_centroids_ctr+1;
            end
        end
        fprintf('Generated %i duplicates into round %i\n',new_centroids_ctr-1,rnd_idx);
        
        %Concatenate the additional puncta to the end of puncta_centroids!
        puncta_centroids{rnd_idx} = [current_round_centroids;extra_centroids]; 
        puncta_baseguess{rnd_idx} = [current_round_centroids_baseguess;extra_centroids_baseguess'];
    end
    
end %end demerge iterations
%% Find the paths that match to all rounds, then check merge flags

filtered_paths = all_possible_punctapaths(sum(all_possible_punctapaths==-1,2)<1,:);

%First we re-map all the duplicated puncta to handle the merge errors back
%into the original indieces
all_possible_punctapaths_demerged = filtered_paths;

% Actually skipping the de-merge step, because we want the different traces
% to be treated seperately 
% num_possible_paths = size(all_possible_punctapaths_demerged,1);
% 
% for rnd_idx = 1:params.NUM_ROUNDS
%     rnd_idx
%     puncta_rndA = puncta_centroids{rnd_idx};
%     
%     %For each puncta, find its nearest neighbor in the same round
%     [IDX,D] = knnsearch(puncta_rndA,puncta_rndA,'K',5); %getting four other options
%    
%     %For each puncta, get all distances == 0 and find the lowest indexed
%     %value. Then store a mapping of puncta_idx -> lowest index match
%     mergefix_punca_mapping = 1:size(puncta_rndA,1);
%     for puncta_idx = 1:size(puncta_rndA,1)
%         %Find the indices where D=0, then get the minimum value of IDX()
%         zero_distance_options = D(puncta_idx,:)==0;
%         %We get the minimum because the duplicates are added to the end of
%         %the puncta list per round, so we can assume the smallest number is
%         %the original
%         mergefix_punca_mapping(puncta_idx) = min(IDX(puncta_idx,zero_distance_options));
%     end
%     
%     %Then loop over every entry in the all_possible_punctapaths_demerged
%     %vector for that round and apply the mergefix vector
%     for path_idx = 1:num_possible_paths
%         all_possible_punctapaths_demerged(path_idx,rnd_idx) = ...
%             mergefix_punca_mapping(all_possible_punctapaths_demerged(path_idx,rnd_idx));
%     end
% end


%% Analyze how well these transcripts align!

%To save time of matching identical transcripts, first find all the unique
%puncta paths throughout the data
[unique_paths, ia, ic] = unique(all_possible_punctapaths_demerged,'rows');

%Now let's get all the transcripts across all unique/possible paths
all_possible_transcripts = zeros(size(unique_paths));

%Convert unique paths to transcripts
for path_idx = 1:size(unique_paths)
    
    for rnd_idx = 1:params.NUM_ROUNDS
        %The punctafeinder also does a rudimentary base calling, which can
        %be substitued later but for is an easy way of converting puncta
        %indices in a round to a transcript
        rnd_base_guesses = puncta_baseguess{rnd_idx};
        
        %Unique path is a collection of indices from that round, so we can
        %use that index to get the base from rnd_base_gueses
        puncta_idx_for_rnd = unique_paths(path_idx,rnd_idx);

        all_possible_transcripts(path_idx,rnd_idx) = rnd_base_guesses(puncta_idx_for_rnd);
    end
end

%The final transcripts have no missing puncta:

hammingscores_uniquepaths = zeros(size(all_possible_transcripts,1),1);

consideration_mask = logical([0 0 0 ones(1,17)]);
max_hits = sum(consideration_mask);
for t_idx = 1:size(all_possible_transcripts,1)
    %Search for a perfect match in the ground truth codes
    hits = (groundtruth_codes==all_possible_transcripts(t_idx,consideration_mask));
    
    %Calculate the hamming distance
    scores = max_hits- sum(hits,2);
    
    hammingscores_uniquepaths(t_idx) = min(scores);
end

figure
histogram(hammingscores_uniquepaths)




%% Tally the score of how many times we got the same path that aligns well

%Create a mask of all the transcripts (from all unique paths) that match to
%one error of the ground rtuth
acceptable_transcripts_mask = hammingscores_uniquepaths<=1;

%Filter the unique paths to only keep the ones whos transcripts matched
acceptable_unique_paths = unique_paths(acceptable_transcripts_mask,:);

%Filter the transcripts from all the unique_paths
acceptable_transcripts = all_possible_transcripts(acceptable_transcripts_mask,:);

%See how many times each unique path is present in the original set of all
%possible possible paths
acceptable_unique_paths_votes = zeros(size(acceptable_unique_paths,1),1);
for path_idx = 1: size(acceptable_unique_paths,1)
    
    %Find out how many times each puncta index in each rond matches the
    %unique
    hits = (all_possible_punctapaths_demerged==acceptable_unique_paths(path_idx,:));
    %Logical array of matches, then sum the rows to find the mefect match
    votes = sum(hits,2)==params.NUM_ROUNDS;
    acceptable_unique_paths_votes(path_idx) = sum(votes);
end

figure;
histogram(acceptable_unique_paths_votes);
title('Histogram of votes for all the 0 or 1 score paths (incl. primer round)');
%% Of the punctapaths that we know align with 0 or 1 accuracy, what is the average position?

filtered_positions = zeros(size(acceptable_unique_paths,1),3);
for t_idx = 1:size(acceptable_unique_paths,1)
    
    positions_across_rounds = zeros(params.NUM_ROUNDS,3);
    
    for rnd_idx = 1:params.NUM_ROUNDS
        %Puncta_centroids is the output of the punctafeinder
        %filtered_unique_paths is a row vector where each round is the
        %index of that puncta in a round
        pos = puncta_centroids{rnd_idx}(acceptable_unique_paths(t_idx,rnd_idx),:);
        positions_across_rounds(rnd_idx,:) = pos;

    end
    
    filtered_positions(t_idx,:) = mean(positions_across_rounds,1);    
    
end

figure;
scatter3(filtered_positions(:,1),filtered_positions(:,2),filtered_positions(:,3),'b.')


%% Collect all puncta into spatial regions

%Create a hierarchical tree of all the positions
%We'll use this to calculate clusters once we get an estimate of how many
%clusters there should be
Z = linkage(filtered_positions);

%calculate average number of puncta per round: 
%(re-runnign num_puncta_per_round because of duplicates now)
num_puncta_per_round = zeros(params.NUM_ROUNDS,1);
for rnd_idx = 1:params.NUM_ROUNDS
    num_puncta_per_round(rnd_idx) = size(puncta_centroids{rnd_idx},1);
end

average_number_of_puncta_per_round = ceil(mean(num_puncta_per_round(consideration_mask)));

%Cluster all the positions into k= the average number of puncta per round
c = cluster(Z,'maxclust',average_number_of_puncta_per_round);

%For each spatial cluster, 

final_positions = [];
final_transcripts=[];
final_confidence=[];
% tie_count = 0;

%Loop over all spatial clusters, which we then map to puncta paths which we
%then map to transcripts
for cluster_idx = 1:max(c)
    
    %Get the indices for this spatial cluster
    %Indices is relative to filtered_positions, which the same size as 
    %acceptable_unique_paths,acceptable_unique_paths_votes
    indices = find(c==cluster_idx);
    
    %Get the unique_paths associated with this
    paths_per_puncta = acceptable_unique_paths(indices,:);
    
    %Get the votes for the different paths
    votes_per_puncta = acceptable_unique_paths_votes(indices);
    
    [~,maxIdx] = max(votes_per_puncta);
    transcripts_per_puncta = acceptable_transcripts(indices,:);
    
%     %How many ties are there for the highest voted path?
%     if sum(max(votes_per_puncta)==votes_per_puncta)>1 |...
%         (max(votes_per_puncta)<=.5*sum(votes_per_puncta))
%         votes_per_puncta
%         tie_count = tie_count+1;
%     end
    
    weighted_indices = [];
    for idx = 1:length(indices)
        weighted_indices = [weighted_indices; repmat(indices(idx),votes_per_puncta(idx),1)];
    end
    
    %Create a set of transcripts that is replicated to use the votes
    weighted_transcripts_per_puncta = all_possible_transcripts(weighted_indices,:);
  
    
    %The transcript is the top voted by base (V1)
%     transcript_per_puncta = mode(weighted_transcripts_per_puncta,1);
    %Take the top vote transcript.
    %In the case of a tie, the first one will be chosen, and then the
    %confidence metric will keep track of where it is different
    %transcript_per_puncta = mode(weighted_transcripts_per_puncta,1);
    
    %V2: Just take the maxvoted
    transcript_per_puncta = transcripts_per_puncta(maxIdx,:);
    
    %The confidence is the percentage that agree per rond
    confidence_per_puncta = sum(weighted_transcripts_per_puncta==transcript_per_puncta,1)/size(weighted_transcripts_per_puncta,1);

    
    final_positions(cluster_idx,:) = mean(filtered_positions(indices,:),1);
    final_transcripts(cluster_idx,:) = transcript_per_puncta;
    final_confidence(cluster_idx,:) = confidence_per_puncta;
end


