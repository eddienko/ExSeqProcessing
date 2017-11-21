loadParameters;

filename_paths = fullfile(params.punctaSubvolumeDir,sprintf('%s_finalmatches.mat',params.FILE_BASENAME));
load(filename_paths,'final_punctapaths');

filename_centroids = fullfile(params.punctaSubvolumeDir,sprintf('%s_centroids+pixels_demerged.mat',params.FILE_BASENAME));
load(filename_centroids,'puncta_baseguess','puncta_centroids','puncta_voxels')
%% Make the 10x10x10 subvolumes we started this with, but now only with the pixels from the puncta!

%Load
filename_in = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,1,'ch00'));
sample_img = load3DTif_uint16(filename_in);
data_height = size(sample_img,1);
data_width = size(sample_img,2);
data_depth = size(sample_img,3);


num_insitu_transcripts = size(final_punctapaths,1);

%Define a puncta_set object that can be parallelized
puncta_set_cell = cell(params.NUM_ROUNDS,1);
pos_cell = cell(params.NUM_ROUNDS,1);


for exp_idx = 1:params.NUM_ROUNDS
    disp(['round=',num2str(exp_idx)])
    
    %Load all channels of data into memory for one experiment
    experiment_set = zeros(data_height,data_width,data_depth, params.NUM_CHANNELS);
    disp(['[',num2str(exp_idx),'] loading files'])
    
    
    for c_idx = params.COLOR_VEC
        filename_in = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,exp_idx,params.CHAN_STRS{c_idx}));
        experiment_set(:,:,:,c_idx) = load3DTif_uint16(filename_in);
    end
    
    disp(['[',num2str(exp_idx),'] processing puncta in parallel'])
    
    puncta_set_cell{exp_idx} = cell(params.NUM_CHANNELS,num_insitu_transcripts);
    
    pos_per_round = zeros(3,num_insitu_transcripts);
    %the puncta indices are here in linear form for a specific round
    punctafeinder_indices = puncta_voxels{exp_idx};
    
    
    puncta_mov = puncta_centroids{exp_idx};
    
    subvolume_ctr = 1;
    
    %To avoid any nasty issues with puncta near the edge of the FOV, we pad
    %everythig by half the size of the punctasize, leaving everythign zero
    %that wasn't in the original data
    padwidth = ceil(params.PUNCTA_SIZE/2);
    
    experiment_set_padded = padarray(experiment_set,[padwidth padwidth padwidth 0],0);
    experiment_set_padded_masked = zeros(size(experiment_set_padded));
    
    for puncta_idx = 1:num_insitu_transcripts
        
        %Get the puncta_idx in the context of this experimental round
        moving_puncta_idx = final_punctapaths(puncta_idx,exp_idx);
        
        %If this round did not have a match for this puncta, just return
        %all -1s
        if moving_puncta_idx==0
            for c_idx = params.COLOR_VEC
                puncta_set_cell{exp_idx}{c_idx,subvolume_ctr} = zeros(params.PUNCTA_SIZE,params.PUNCTA_SIZE,params.PUNCTA_SIZE)-1;
            end
            subvolume_ctr = subvolume_ctr+1;
            fprintf('No matching puncta for puncta_idx=%i in round %i\n',puncta_idx,exp_idx)
            continue;
        end
        
        this_centroid = puncta_centroids{exp_idx}(moving_puncta_idx,:);
        
        %Get the centroid's Y X Z
        %NOTE: The centroid position come from the regionprops() call in
        %punctafeinder.m and have the XY coords flipped relative to what
        %we're used to, so Y and X are switched
        Y = round(this_centroid(2))+padwidth; 
        X = round(this_centroid(1))+padwidth;
        Z = round(this_centroid(3))+padwidth;
        
        %If we were just drawing a 10x10x10 subregion around the
        %puncta, we'd do this
        y_indices = Y - params.PUNCTA_SIZE/2 + 1: Y + params.PUNCTA_SIZE/2;
        x_indices = X - params.PUNCTA_SIZE/2 + 1: X + params.PUNCTA_SIZE/2;
        z_indices = Z - params.PUNCTA_SIZE/2 + 1: Z + params.PUNCTA_SIZE/2;
        
        %These are the indices for the puncta in question
        punctafeinder_indices_for_puncta = punctafeinder_indices{moving_puncta_idx};
        %now converted to 3D in the original coordinate space 
        [i1, i2, i3] = ind2sub(size(experiment_set),punctafeinder_indices_for_puncta);
        %shift the conversions with the padwidth
        i1 = i1+padwidth; i2 = i2+padwidth; i3 = i3+padwidth;
        
        for c_idx = params.COLOR_VEC
            %This makes a volume that is all zeros except for the punctafeinder_indices_for_puncta
            for i_idx = 1:length(i1)
                experiment_set_padded_masked(i1(i_idx),i2(i_idx),i3(i_idx)) = experiment_set_padded(i1(i_idx),i2(i_idx),i3(i_idx),c_idx);
            end
            pixels_for_puncta_set = experiment_set_padded_masked(y_indices,x_indices,z_indices);
            
            if max(pixels_for_puncta_set(:))==0
               fprintf('Ok we have found an issue with puncta_idx=%i\n',puncta_idx);
%                barf()
            end
            %Then we take the PUNCTA_SIZE region around those pixels only
            puncta_set_cell{exp_idx}{c_idx,subvolume_ctr} = pixels_for_puncta_set;
            
            %Reset the specific pixels of the mask
            for i_idx = 1:length(i1)
                experiment_set_padded_masked(i1(i_idx),i2(i_idx),i3(i_idx)) = 0;
            end
            
        end
        
        
       pos_per_round(:,subvolume_ctr) = [Y X Z]-padwidth;
        
        subvolume_ctr = subvolume_ctr+1;
        if mod(subvolume_ctr,400)==0
            fprintf('Rnd %i, Puncta %i processed\n',exp_idx,subvolume_ctr);
        end
    end
    pos_cell{exp_idx} =pos_per_round;
end

disp('reducing processed puncta')
puncta_set = zeros(params.PUNCTA_SIZE,params.PUNCTA_SIZE,params.PUNCTA_SIZE,params.NUM_ROUNDS,params.NUM_CHANNELS,num_insitu_transcripts);

% reduction of parfor
for exp_idx = 1:params.NUM_ROUNDS
    for puncta_idx = 1:num_insitu_transcripts
        for c_idx = params.COLOR_VEC            
            puncta_set(:,:,:,exp_idx,c_idx,puncta_idx) = puncta_set_cell{exp_idx}{c_idx,puncta_idx};
        end
    end
end
pos= zeros(3,params.NUM_ROUNDS,num_insitu_transcripts);
for exp_idx = 1:params.NUM_ROUNDS
    pos_per_round = pos_cell{exp_idx};
    for puncta_idx = 1:num_insitu_transcripts
        pos(:,exp_idx,puncta_idx) = pos_per_round(:,puncta_idx);
    end
end


disp('saving files from makePunctaVolumes')
%just save puncta_set
save(fullfile(params.punctaSubvolumeDir,sprintf('%s_puncta_rois.mat',params.FILE_BASENAME)),...
    'puncta_set','pos','-v7.3');
