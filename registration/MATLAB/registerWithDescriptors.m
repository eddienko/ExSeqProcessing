
% Step 4-6: Calculating Correspondences
% This is the code that calculates the keypoints and descriptors at
% varying scale levels
%
% INPUTS:
% moving_run: which expeirment do you want to warp accordingly?
% OUTPUTS:
% no variables. All outputs saved to params.OUTPUTDIR
%
% Author: Daniel Goodwin dgoodwin208@gmail.com
% Date: August 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function registerWithDescriptors(moving_run)

profile on;

loadExperimentParams;

params.MOVING_RUN = moving_run;

disp(['RUNNING ON MOVING: ' num2str(params.MOVING_RUN) ', FIXED: ' num2str(params.FIXED_RUN)])

filename = fullfile(params.INPUTDIR,sprintf('%sround%03d_%s.tif',...
    params.SAMPLE_NAME,params.FIXED_RUN,params.CHANNELS{1} ));

imgFixed_total = load3DTif_uint16(filename);


filename = fullfile(params.INPUTDIR,sprintf('%sround%03d_%s.tif',...
    params.SAMPLE_NAME,params.MOVING_RUN,params.CHANNELS{1}));

try
    imgMoving_total = load3DTif_uint16(filename);
catch
    fprintf('ERROR: Cannot load file. TODO: add skippable rounds\n');
    return;
end
%LOAD FILES WITH CROP INFORMATION, CROP LOADED FILES
cropfilename = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_cropbounds.mat',params.SAMPLE_NAME,params.FIXED_RUN));
if exist(cropfilename,'file')==2
    load(cropfilename,'bounds'); bounds_fixed = floor(bounds); clear bounds;
    imgFixed_total = imgFixed_total(bounds_fixed(1):bounds_fixed(2),bounds_fixed(3):bounds_fixed(4),:);
end

cropfilename = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_cropbounds.mat',params.SAMPLE_NAME,params.MOVING_RUN));
if exist(cropfilename,'file')==2
    load(cropfilename,'bounds'); bounds_moving = floor(bounds); clear bounds;
    imgMoving_total = imgMoving_total(bounds_moving(1):bounds_moving(2),bounds_moving(3):bounds_moving(4),:);
end

%------------------------------Load Descriptors -------------------------%
%Load all descriptors for the MOVING channel
%tic;
%keys_moving_total = {}; keys_ctr=1;
%for register_channel = [params.REGISTERCHANNELS_SIFT,params.REGISTERCHANNELS_SC]
%    descriptor_output_dir_moving = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
%        params.MOVING_RUN,register_channel{1}));
%    
%    files = dir(fullfile(descriptor_output_dir_moving,'*.mat'));
%    
%    for file_idx= 1:length(files)
%        filename = files(file_idx).name;
%        
%        %The data for each tile is keys, xmin, xmax, ymin, ymax
%        data = load(fullfile(descriptor_output_dir_moving,filename));
%
%        for idx=1:length(data.keys)
%            %copy all the keys into one large vector of cells
%            %if keys_ctr>1111
%            %   fprintf('test'); 
%            %end
%            keys_moving_total{keys_ctr} = data.keys{idx};
%            keys_moving_total{keys_ctr}.x = data.keys{idx}.x + data.xmin-1;
%            keys_moving_total{keys_ctr}.y = data.keys{idx}.y + data.ymin-1;
%            keys_moving_total{keys_ctr}.channel = register_channel;
%            keys_ctr = keys_ctr+ 1;
%        end
%    end
%end
%fprintf('load keys of moving round%03d (orig). ',params.MOVING_RUN);toc;

tic;
keys_moving_total_sift.pos = [];
keys_moving_total_sift.ivec = [];
for register_channel = [params.REGISTERCHANNELS_SIFT]
    descriptor_output_dir_moving = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
        params.MOVING_RUN,register_channel{1}));
    
    files = dir(fullfile(descriptor_output_dir_moving,'*.mat'));
    
    for file_idx= 1:length(files)
        filename = files(file_idx).name;
        
        %The data for each tile is keys, xmin, xmax, ymin, ymax
        data = load(fullfile(descriptor_output_dir_moving,filename));
        keys = vertcat(data.keys{:});
        pos = [[keys(:).y]'+data.ymin-1,[keys(:).x]'+data.xmin-1,[keys(:).z]'];
        ivec = vertcat(keys(:).ivec);

        keys_moving_total_sift.pos  = vertcat(keys_moving_total_sift.pos,pos);
        keys_moving_total_sift.ivec = vertcat(keys_moving_total_sift.ivec,ivec);
    end
end
fprintf('load sift keys of moving round%03d (mod). ',params.MOVING_RUN);toc;

tic;
keys_moving_total_sc.pos = [];
for register_channel = [params.REGISTERCHANNELS_SC]
    descriptor_output_dir_moving = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
        params.MOVING_RUN,register_channel{1}));
    
    files = dir(fullfile(descriptor_output_dir_moving,'*.mat'));
    
    for file_idx= 1:length(files)
        filename = files(file_idx).name;
        
        %The data for each tile is keys, xmin, xmax, ymin, ymax
        data = load(fullfile(descriptor_output_dir_moving,filename));
        keys = vertcat(data.keys{:});
        pos = [[keys(:).y]'+data.ymin-1,[keys(:).x]'+data.xmin-1,[keys(:).z]'];

        keys_moving_total_sc.pos = vertcat(keys_moving_total_sc.pos,pos);
    end
end
fprintf('load sc keys of moving round%03d (mod). ',params.MOVING_RUN);toc;

%Load all descriptors for the FIXED channel
%tic;
%keys_fixed_total = {}; keys_ctr=1;
%for register_channel = [params.REGISTERCHANNELS_SIFT,params.REGISTERCHANNELS_SC]
%    descriptor_output_dir_fixed = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
%        params.FIXED_RUN,register_channel{1}));
%    
%    files = dir(fullfile(descriptor_output_dir_fixed,'*.mat'));
%    
%    for file_idx= 1:length(files)
%        filename = files(file_idx).name;
%        %All results from CalculateDescriptorsforTilesAtIndeices saves the
%        %descriptors in the coords of the tile
%        
%        data = load(fullfile(descriptor_output_dir_fixed,filename));
%        for idx=1:length(data.keys)
%            %copy all the keys into one large vector of cells
%            keys_fixed_total{keys_ctr} = data.keys{idx};        %#ok<*AGROW>
%            keys_fixed_total{keys_ctr}.x = data.keys{idx}.x + data.xmin-1;
%            keys_fixed_total{keys_ctr}.y = data.keys{idx}.y + data.ymin-1;
%            keys_fixed_total{keys_ctr}.channel = register_channel;
%            
%            keys_ctr = keys_ctr+ 1;
%        end
%    end
%end
%fprintf('load keys of fixed round%03d (orig). ',params.FIXED_RUN);toc;

tic;
keys_fixed_total_sift.pos = [];
keys_fixed_total_sift.ivec = [];
for register_channel = [params.REGISTERCHANNELS_SIFT]
    descriptor_output_dir_fixed = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
        params.FIXED_RUN,register_channel{1}));
    
    files = dir(fullfile(descriptor_output_dir_fixed,'*.mat'));
    
    for file_idx= 1:length(files)
        filename = files(file_idx).name;
        
        %The data for each tile is keys, xmin, xmax, ymin, ymax
        data = load(fullfile(descriptor_output_dir_fixed,filename));
        keys = vertcat(data.keys{:});
        pos = [[keys(:).y]'+data.ymin-1,[keys(:).x]'+data.xmin-1,[keys(:).z]'];
        ivec = vertcat(keys(:).ivec);

        keys_fixed_total_sift.pos  = vertcat(keys_fixed_total_sift.pos,pos);
        keys_fixed_total_sift.ivec = vertcat(keys_fixed_total_sift.ivec,ivec);
    end
end
fprintf('load sift keys of fixed round%03d (mod). ',params.MOVING_RUN);toc;

tic;
keys_fixed_total_sc.pos = [];
for register_channel = [params.REGISTERCHANNELS_SC]
    descriptor_output_dir_fixed = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s/',params.SAMPLE_NAME, ...
        params.FIXED_RUN,register_channel{1}));
    
    files = dir(fullfile(descriptor_output_dir_fixed,'*.mat'));
    
    for file_idx= 1:length(files)
        filename = files(file_idx).name;
        
        %The data for each tile is keys, xmin, xmax, ymin, ymax
        data = load(fullfile(descriptor_output_dir_fixed,filename));
        keys = vertcat(data.keys{:});
        pos = [[keys(:).y]'+data.ymin-1,[keys(:).x]'+data.xmin-1,[keys(:).z]'];

        keys_fixed_total_sc.pos = vertcat(keys_fixed_total_sc.pos,pos);
    end
end
fprintf('load sc keys of fixed round%03d (mod). ',params.MOVING_RUN);toc;
%------------All descriptors are now loaded as keys_*_total -------------%



%chop the image up into grid
tile_upperleft_y_moving = floor(linspace(1,size(imgMoving_total,1),params.ROWS_TFORM+1));
tile_upperleft_x_moving = floor(linspace(1,size(imgMoving_total,2),params.COLS_TFORM+1));

%don't need to worry about padding because these tiles are close enough in
%(x,y) origins
tile_upperleft_y_fixed = floor(linspace(1,size(imgFixed_total,1),params.ROWS_TFORM+1));
tile_upperleft_x_fixed = floor(linspace(1,size(imgFixed_total,2),params.COLS_TFORM+1));

%loop over all the subsections desired for the piecewise affine, finding
%all relevant keypoints then calculating the transform from there
keyM_total = [];
keyF_total = [];

%Because it takes up to hours to generate the global list of vetted
%keys, after we generate them we now save them in the output_keys_filename
%if it's aready been generated, we can skip directly to the TPS calculation
output_keys_filename = fullfile(params.OUTPUTDIR,sprintf('globalkeys_%sround%03d.mat',params.SAMPLE_NAME,params.MOVING_RUN));

%If we need to run the robust model checking to identify correct
%correspondences
if ~exist(output_keys_filename,'file')
    
    for x_idx=1:params.COLS_TFORM
        for y_idx=1:params.ROWS_TFORM
            
            disp(['Running on row ' num2str(y_idx) ' and col ' num2str(x_idx) ]);
            
%            tic;
            %the moving code is defined the linspace layout of dimensions above
            ymin_moving = tile_upperleft_y_moving(y_idx);
            ymax_moving = tile_upperleft_y_moving(y_idx+1);
            xmin_moving = tile_upperleft_x_moving(x_idx);
            xmax_moving = tile_upperleft_x_moving(x_idx+1);
            
            tile_img_moving = imgMoving_total(ymin_moving:ymax_moving, xmin_moving:xmax_moving,:);
            
            %Before calculating any features, make sure the tile is not empty
            if checkIfTileEmpty(tile_img_moving,params.EMPTY_TILE_THRESHOLD)
                disp('Sees the moving tile to be empty');
                continue
            end
            
            %FindRelevant keys not only finds the total keypoints, but converts
            %those keypoints to the scope of the specific tile, not the global
            %position
%            keys_moving = findRelevantKeys(keys_moving_total, ymin_moving, ymax_moving,xmin_moving,xmax_moving);
%            fprintf('findRelevantKeys. keys_moving(orig) ');toc;

            tic;
            keys_moving_sift_index = find(keys_moving_total_sift.pos(:,1)>=ymin_moving & keys_moving_total_sift.pos(:,1)<=ymax_moving & ...
                keys_moving_total_sift.pos(:,2)>=xmin_moving & keys_moving_total_sift.pos(:,2)<=xmax_moving);
            keys_moving_sift.pos = keys_moving_total_sift.pos(keys_moving_sift_index,:)-[ymin_moving-1,xmin_moving-1,0];
            keys_moving_sift.ivec = keys_moving_total_sift.ivec(keys_moving_sift_index,:);
            keys_moving_sc_index = find(keys_moving_total_sc.pos(:,1)>=ymin_moving & keys_moving_total_sc.pos(:,1)<=ymax_moving & ...
                keys_moving_total_sc.pos(:,2)>=xmin_moving & keys_moving_total_sc.pos(:,2)<=xmax_moving);
            keys_moving_sc.pos = keys_moving_total_sc.pos(keys_moving_sc_index,:)-[ymin_moving-1,xmin_moving-1,0];
            fprintf('findRelevantKeys. keys_moving(mod) ');toc;
            
%            tic;
            %Loading the fixed tiles is detemined by some extra overlap between
            %the tiles (may not be necessary)
            tile_img_fixed_nopadding = imgFixed_total(tile_upperleft_y_fixed(y_idx):tile_upperleft_y_fixed(y_idx+1), ...
                tile_upperleft_x_fixed(x_idx):tile_upperleft_x_fixed(x_idx+1), ...
                :);
            tilesize_fixed = size(tile_img_fixed_nopadding);
            
            ymin_fixed = tile_upperleft_y_fixed(y_idx);
            ymax_fixed = tile_upperleft_y_fixed(y_idx+1);
            xmin_fixed = tile_upperleft_x_fixed(x_idx);
            xmax_fixed = tile_upperleft_x_fixed(x_idx+1);
            
            ymin_fixed_overlap = floor(max(tile_upperleft_y_fixed(y_idx)-(params.OVERLAP/2)*tilesize_fixed(1),1));
            ymax_fixed_overlap = floor(min(tile_upperleft_y_fixed(y_idx+1)+(params.OVERLAP/2)*tilesize_fixed(1),size(imgFixed_total,1)));
            xmin_fixed_overlap = floor(max(tile_upperleft_x_fixed(x_idx)-(params.OVERLAP/2)*tilesize_fixed(2),1));
            xmax_fixed_overlap = floor(min(tile_upperleft_x_fixed(x_idx+1)+(params.OVERLAP/2)*tilesize_fixed(2),size(imgFixed_total,2)));
            
            clear tile_img_fixed_nopadding;
            
            tile_img_fixed = imgFixed_total(ymin_fixed_overlap:ymax_fixed_overlap, xmin_fixed_overlap:xmax_fixed_overlap,:);
            
            if checkIfTileEmpty(tile_img_fixed,params.EMPTY_TILE_THRESHOLD)
                disp('Sees the moving tile to be empty');
                continue
            end
            
            %FindRelevant keys not only finds the total keypoints, but converts
            %those keypoints to the scope of the specific tile, not the global
            %position
%            keys_fixed = findRelevantKeys(keys_fixed_total, ymin_fixed, ymax_fixed,xmin_fixed,xmax_fixed);
%            fprintf('findRelevantKeys. keys_fixed(orig) ');toc;

            tic;
            keys_fixed_sift_index = find(keys_fixed_total_sift.pos(:,1)>=ymin_fixed & keys_fixed_total_sift.pos(:,1)<=ymax_fixed & ...
                keys_fixed_total_sift.pos(:,2)>=xmin_fixed & keys_fixed_total_sift.pos(:,2)<=xmax_fixed);
            keys_fixed_sift.pos = keys_fixed_total_sift.pos(keys_fixed_sift_index,:)-[ymin_fixed-1,xmin_fixed-1,0];
            keys_fixed_sift.ivec = keys_fixed_total_sift.ivec(keys_fixed_sift_index,:);
            keys_fixed_sc_index = find(keys_fixed_total_sc.pos(:,1)>=ymin_fixed & keys_fixed_total_sc.pos(:,1)<=ymax_fixed & ...
                keys_fixed_total_sc.pos(:,2)>=xmin_fixed & keys_fixed_total_sc.pos(:,2)<=xmax_fixed);
            keys_fixed_sc.pos = keys_fixed_total_sc.pos(keys_fixed_sc_index,:)-[ymin_fixed-1,xmin_fixed-1,0];
            fprintf('findRelevantKeys. keys_fixed(mod) ');toc;
            
            num_keys_fixed = length(keys_fixed_sift)+length(keys_fixed_sc);
            num_keys_moving = length(keys_moving_sift)+length(keys_moving_sc);
            disp(['Sees ' num2str(num_keys_fixed) ' features for fixed and ' num2str(num_keys_moving) ' features for moving.']);
            if num_keys_fixed==0 || num_keys_moving==0
                disp('Empty set of descriptors. Skipping')
                continue;
            end
            
            % ----------- SIFT MATCHING AND ROBUST MODEL SELECTION ----------%
            %
            
            tic;
            %Extract the keypoints-only for the shape context calculation
            %D is for descriptor, M is for moving
%            DM_SIFT = []; %DM_SC is defined later
%            LM_SIFT = []; ctr_sift = 1; ctr_sc = 1; 
%            LM_SC = [];
%            for i = 1:length(keys_moving)
%                %If this channel is to be included in the SIFT_registration
%                if any(strcmp(params.REGISTERCHANNELS_SIFT,keys_moving{i}.channel))
%                    DM_SIFT(ctr_sift,:) = keys_moving{i}.ivec;
%                    LM_SIFT(ctr_sift,:) = [keys_moving{i}.y, keys_moving{i}.x, keys_moving{i}.z];
%                    ctr_sift = ctr_sift+1;
%                end
%                
%                if any(strcmp(params.REGISTERCHANNELS_SC,keys_moving{i}.channel))
%                    LM_SC(ctr_sc,:) = [keys_moving{i}.y, keys_moving{i}.x, keys_moving{i}.z];
%                    ctr_sc = ctr_sc+1; 
%                end
%                
%            end
            DM_SIFT = keys_moving_sift.ivec;
            LM_SIFT = keys_moving_sift.pos;
            LM_SC = keys_moving_sc.pos;
            fprintf('prepare keypoints of moving round.');toc;
            
            tic;
            %F for fixed
%            DF_SIFT = []; 
%            LF_SIFT = []; ctr_sift = 1; ctr_sc = 1; 
%            LF_SC = [];
%            for i = 1:length(keys_fixed)
%                if any(strcmp(params.REGISTERCHANNELS_SIFT,keys_fixed{i}.channel))
%                    DF_SIFT(ctr_sift,:) = keys_fixed{i}.ivec;
%                    LF_SIFT(ctr_sift,:) = [keys_fixed{i}.y, keys_fixed{i}.x, keys_fixed{i}.z];
%                    ctr_sift = ctr_sift+1;
%                end
%            
%                if any(strcmp(params.REGISTERCHANNELS_SC,keys_fixed{i}.channel))
%                    LF_SC(ctr_sc,:) = [keys_fixed{i}.y, keys_fixed{i}.x, keys_fixed{i}.z];
%                    ctr_sc = ctr_sc+1; 
%                end
%            end
            DF_SIFT = keys_fixed_sift.ivec;
            LF_SIFT = keys_fixed_sift.pos;
            LF_SC = keys_fixed_sc.pos;
            fprintf('prepare keypoints of fixed round.');toc;
            
            % deuplicate any SIFT keypoints
            fprintf('(%i,%i) before dedupe, ',size(LM_SIFT,1),size(LF_SIFT,1));
            [LM_SIFT,keepM,~] = unique(LM_SIFT,'rows');
            [LF_SIFT,keepF,~] = unique(LF_SIFT,'rows');
            DM_SIFT = DM_SIFT(keepM,:);
            DF_SIFT = DF_SIFT(keepF,:);
            fprintf('(%i,%i) after dedupe\n',size(LM_SIFT,1),size(LF_SIFT,1));
            
            % deuplicate any ShapeContext keypoints
            fprintf('(%i,%i) before dedupe, ',size(LM_SC,1),size(LF_SC,1));
            [LM_SC,~,~] = unique(LM_SC,'rows');
            [LF_SC,~,~] = unique(LF_SC,'rows');
            fprintf('(%i,%i) after dedupe\n',size(LM_SC,1),size(LF_SC,1));
            
            
            fprintf('calculating SIFT correspondences...\n');
            tic;
            DM_SIFT = double(DM_SIFT);
            DF_SIFT = double(DF_SIFT);
            DM_SIFT_norm= DM_SIFT ./ repmat(sum(DM_SIFT,2),1,size(DM_SIFT,2));
            DF_SIFT_norm= DF_SIFT ./ repmat(sum(DF_SIFT,2),1,size(DF_SIFT,2));
            size(DM_SIFT_norm)
            size(DF_SIFT_norm)
            save('sifts.mat','DM_SIFT_norm','DF_SIFT_norm');
            %correspondences_sift = vl_ubcmatch(DM_SIFT_norm',DF_SIFT_norm');
            correspondences_sift = match_3DSIFTdescriptors_cuda(DM_SIFT_norm,DF_SIFT_norm);
            toc;
            size(correspondences_sift)
            
            fprintf('calculating ShapeContext correspondences...\n');
            tic;
            %We create a shape context descriptor for the same keypoint
            %that has the SIFT descriptor.
            %So we calculate the SIFT descriptor on the normed channel
            %(summedNorm), and we calculate the Shape Context descriptor
            %using keypoints from all other channels
            [DM_SC,DF_SC]=ShapeContext(LM_SIFT,LM_SC,LF_SIFT,LF_SC);
            size(DM_SC)
            size(DF_SC)
            %correspondences_sc = vl_ubcmatch(DM_SC,DF_SC);
            correspondences_sc = match_3DSIFTdescriptors_cuda(DM_SC',DF_SC');
            toc;

            fprintf('SIFT-only correspondences get %i matches, SC-only gets %i matches\n',...
                size(correspondences_sift,2),size(correspondences_sc,2));

            correspondences_combine = [correspondences_sc,correspondences_sift]';
            [correspondences,~,~] = unique(correspondences_combine,'rows');
            correspondences = correspondences';
            fprintf('There unique %i matches if we take the union of the two methods\n', size(correspondences,2));
            
            fprintf('calculating SIFT+ShapeContext correspondences...\n');
            tic;
            % correspondences = vl_ubcmatch([DM_SC; DM_SIFT_norm'],[DF_SC; DF_SIFT_norm']);
            correspondences = match_3DSIFTdescriptors_cuda([DM_SC; DM_SIFT_norm']',[DF_SC; DF_SIFT_norm']');
            toc;
            
            %Check for duplicate matches- ie, keypoint A matching to both
            %keypoint B and keypoint C
            
            num_double_matches = 0;
            for idx = 1:2
                u=unique(correspondences(idx ,:));         % the unique values
                [n,~]=histc(correspondences(idx ,:),u);  % count how many of each and where
                col_duplicates_indices=find(n>1);       % index to bin w/ more than one
                num_double_matches = num_double_matches + length(col_duplicates_indices);
                correspondences(:,col_duplicates_indices) = [];
            end
            fprintf('There are %i matches when combining the features evenly (removed %i double matches)\n', size(correspondences,2),num_double_matches);

            if length(correspondences)<20
                disp(['We only see ' num2str(length(correspondences)) ' which is insufficient to calculate a reliable transform. Skipping']);
                error('Insufficient points after filtering. Try increasing the inlier parameters in calc_affine');
                continue
            end
            
            LM = LM_SIFT;
            LF = LF_SIFT;
            %RANSAC filtering producing keyM and keyF varibles
            warning('off','all'); tic;calc_affine; toc;warning('on','all')
            
            %calc_affine produces keyM and keyF, pairs of point correspondences
            %from the robust model fitting. The math is done with local
            %coordinates to the subvolume, so it needs to be adapted to global
            %points
            
            keyM_total = [keyM_total; keyM(:,1) + ymin_moving-1, keyM(:,2) + xmin_moving-1, keyM(:,3) ];
            keyF_total = [keyF_total; keyF(:,1) + ymin_fixed-1, keyF(:,2) + xmin_fixed-1, keyF(:,3)];
            
            
            % ----------- END ---------- %
        end
    end
    
    save(output_keys_filename,'keyM_total','keyF_total');
else %if we'va already calculated keyM_total and keyF_total, we can just load it
    disp('KeyM_total and KeyF_total already calculated. Loading.');
    load(output_keys_filename);
end

fprintf('Using all %i corresondences by ignoring for quantile cutoff\n', size(keyM_total,1));

%If you want to set a maxium warp distance between matching keypoints. This is not currently being used but keeping it in mainly as a reminder that the correspondeces were problematic in the past and code like this can be implemented if need be.
if (params.MAXDISTANCE>-1)
    remove_indices = [];
    for match_idx = 1:size(keyF_total,1)
        if norm(keyF_total(match_idx,:)-keyM_total(match_idx,:))>params.MAXDISTANCE
            norm(keyF_total(match_idx,:)-keyM_total(match_idx,:));
            remove_indices = [remove_indices match_idx];
        end
    end
    keyF_total(remove_indices,:) = [];
    keyM_total(remove_indices,:) = [];

    clear remove_indices;
end

if isempty(keyF_total) || isempty(keyM_total)
    error('ERROR: all keys removed, consider raising `params.MAXDISTANCE`... exiting');
end

%Do a global affine transform on the data and keypoints before
%doing the fine-resolution non-rigid warp

%Because of the annoying switching between XY/YX conventions,
%we have to switch XY components for the affine calcs, then switch back
keyM_total_switch = keyM_total(:,[2 1 3]);
keyF_total_switch = keyF_total(:,[2 1 3]);

%The old way was calculating the affine tform
warning('off','all'); 
affine_tform = findAffineModel(keyM_total_switch, keyF_total_switch);
warning('on','all')

if ~det(affine_tform)
    error('ERROR: affine_tform can not be singular for following calcs... exiting')
end

%Warp the keyM features into the new space
rF = imref3d(size(imgFixed_total));
%Key total_affine is now with the switched XY
keyM_total_affine = [keyM_total_switch, ones(size(keyM_total_switch,1),1)]*affine_tform';
%keyM_total is now switched
keyM_total=keyM_total_affine(:,1:3);
%keyF_total = keyF_total_switch;
%Remove any keypoints which are now outside the bounds of the image
filtered_correspondence_indices = (keyM_total(:,1) <1 | keyM_total(:,2)<1 | keyM_total(:,3)<1 | ...
    keyM_total(:,1) > size(imgFixed_total,2) | ...
    keyM_total(:,2) > size(imgFixed_total,1) | ...
    keyM_total(:,3) > size(imgFixed_total,3) );
fprintf('Losing %i features after affine warp\n',sum(filtered_correspondence_indices));
keyM_total(filtered_correspondence_indices,:) = [];
keyF_total(filtered_correspondence_indices,:) = [];

%switch keyM back to the other format for the TPS calcs
keyM_total = keyM_total(:,[2 1 3]);

for c = 1:length(params.CHANNELS)
    %Load the data to be warped
    tic;
    data_channel = params.CHANNELS{c};
    fprintf('load 3D file for affine transform on %s channel\n',data_channel);
    filename = fullfile(params.INPUTDIR,sprintf('%sround%03d_%s.tif',params.SAMPLE_NAME,params.MOVING_RUN,data_channel));
    imgToWarp = load3DTif_uint16(filename);
    toc;
    
    output_affine_filename = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s_affine.tif',...
        params.SAMPLE_NAME,params.MOVING_RUN,data_channel));
    imgMoving_total_affine = imwarp(imgToWarp,affine3d(affine_tform'),'OutputView',rF);
    save3DTif_uint16(imgMoving_total_affine,output_affine_filename);
end

output_TPS_filename = fullfile(params.OUTPUTDIR,sprintf('TPSMap_%sround%03d.mat',params.SAMPLE_NAME,params.MOVING_RUN));
if exist(output_TPS_filename,'file')==0
    %        [in1D_total,out1D_total] = TPS3DWarpWhole(keyM_total,keyF_total, ...
    
    [in1D_total,out1D_total] = TPS3DWarpWholeInParallel(keyM_total,keyF_total, ...
        size(imgMoving_total), size(imgFixed_total));
    disp('save TPS file')
    tic;
    save(output_TPS_filename,'in1D_total','out1D_total','-v7.3');
    toc;
else
    %load in1D_total and out1D_total
    disp('load TPS file')
    tic;
    load(output_TPS_filename);
    toc;
    %Experiments 7 and 8 may have been saved with zeros in the 1D vectors
    %so this removes it
    [ValidIdxs,I] = find(in1D_total>0);
    in1D_total = in1D_total(ValidIdxs);
    out1D_total = out1D_total(ValidIdxs);
end




%Warp all three channels of the experiment once the index mapping has been
%created
for c = 1:length(params.CHANNELS)
    %Load the data to be warped
    disp('load 3D file to be warped')
    tic;
    data_channel = params.CHANNELS{c};
    filename = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s_affine.tif',params.SAMPLE_NAME,params.MOVING_RUN,data_channel));
    imgToWarp = load3DTif_uint16(filename);
    toc;
    
    %we loaded the bounds_moving data at the very beginning of this file
    if exist(cropfilename,'file')==2
        imgToWarp = imgToWarp(bounds_moving(1):bounds_moving(2),bounds_moving(3):bounds_moving(4),:);
    end
    [ outputImage_interp ] = TPS3DApply(in1D_total,out1D_total,imgToWarp,size(imgFixed_total));
    
    outputfile = fullfile(params.OUTPUTDIR,sprintf('%sround%03d_%s_registered.tif',params.SAMPLE_NAME,params.MOVING_RUN,data_channel));
    save3DTif_uint16(outputImage_interp,outputfile);
end

profile off; profsave(profile('info'),sprintf('profile-results-register-with-desc-%d',moving_run));

end


