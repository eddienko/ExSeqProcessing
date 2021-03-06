loadParameters;

%Create a holder object for the rgb images for all rounds and the 100
%puncta we want to view
all_rgb_regions = cell(params.NUM_ROUNDS,100);
center_point_coords = cell(1,100);
puncta_viewed = [];

WINDOW=100;

load(fullfile(params.basecallingResultsDir,sprintf('%s_transcriptsv11.mat',params.FILE_BASENAME)));
transcript_pos = pos;
indices = randperm(size(pos,1),100);


for rnd_idx = 1:params.NUM_ROUNDS
    
    output_ctr =1;
    filename_chan1 = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,rnd_idx,'ch00'));
    filename_chan2 = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,rnd_idx,'ch01SHIFT'));
    filename_chan3 = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,rnd_idx,'ch02SHIFT'));
    filename_chan4 = fullfile(params.registeredImagesDir,sprintf('%s_round%.03i_%s_registered.tif',params.FILE_BASENAME,rnd_idx,'ch03SHIFT'));
    
    fprintf('Loading images for Round %i...',rnd_idx);
    img = load3DTif(filename_chan1);
    imgs = zeros([size(img) 4]);
    imgs(:,:,:,1) = img;
    img = load3DTif(filename_chan2);
    imgs(:,:,:,2) =img;
    img = load3DTif(filename_chan3);
    imgs(:,:,:,3) = img;
    img = load3DTif(filename_chan4);
    imgs(:,:,:,4) = img;
    clear img;
    fprintf('DONE\n');
    
    
    for t_idx = indices
        
        
        clear imgdata4chan
        pos = transcript_pos(t_idx,:);
        
        if ~any(pos)
            fprintf('Skipping pos=[0,0,0] for t_idx=%i\n',t_idx)
            continue;
        end
        y_min = max(pos(1)-WINDOW+1,1); y_max = min(pos(1)+WINDOW,size(imgs,1));
        x_min = max(pos(2)-WINDOW+1,1); x_max = min(pos(2)+WINDOW,size(imgs,2));
        for c_idx = params.COLOR_VEC
            imgdata4chan(:,:,c_idx) = imgs(y_min:y_max,x_min:x_max,pos(3),c_idx);
        end
        
        
        
        rgb_img = makeRGBImageFrom4ChanData(imgdata4chan);
        
        all_rgb_regions{rnd_idx,output_ctr}=rgb_img;
        center_point_coords{1,output_ctr} = [pos(2)-x_min,pos(1)-y_min];
        
        puncta_viewed = [puncta_viewed t_idx];
        
        output_ctr = output_ctr+1;
        if output_ctr>100
            break
        end
        
    end %finish looping over puncta
    
end
puncta_viewed = unique(puncta_viewed);

save(fullfile(params.basecallingResultsDir,sprintf('%s_rgbimagesforpuncta.mat',params.FILE_BASENAME)),'all_rgb_regions','puncta_viewed');

%% Now actually make the image looping over the cell arrays of the rGB images

giffilename3='puncta_for_all_images.gif';

figure(3)
set(gcf,'Visible','Off');
set(gcf,'pos',[ 23, 5, 2600, 1600]);
subplot(4,5,1);
hasInitGif=0;
for puncta_idx = 1:size(all_rgb_regions,2)
    
    for rnd_idx = 1:size(all_rgb_regions,1)
        
        subplot(4,5,rnd_idx)
        
        imshow(all_rgb_regions{rnd_idx,puncta_idx},'InitialMagnification',100);
        title(sprintf('rnd%i',rnd_idx));
        hold on;
        pos = center_point_coords{1,puncta_idx};
        
        plot(pos(1),pos(2),'o','MarkerSize',10,'Color','white');
        hold off;
    end
    
    frame = getframe(3);
    im = frame2im(frame);
    [imind1,cm1] = rgb2ind(im,256);
    
    if hasInitGif==0
        imwrite(imind1,cm1,giffilename3,'gif', 'Loopcount',inf);
        hasInitGif = 1;
    else
        imwrite(imind1,cm1,giffilename3,'gif','WriteMode','append');
    end
end

