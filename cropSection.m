%This script will load the TPS outputs (tiff sequence) and output 3d tif images
%It can also crop if you specify it


%Where is the registration code outputing the TPS* directories?
dir_input = '/om/user/dgoodwin/ExSeq/slice/output/';
%Where is the the folder that we can write files on the cluster?  
dir_rootoutput = '/om/project/boyden/ExSeqSlice/output/';

experiment_string = 'sa0916slicedncv';

DO_CROP = 0;

if DO_CROP
    PREPEND= 'CROP';
else
    PREPEND = 'FULL';
end

TOP_LEFT = [1125,291];
BOTTOM_RIGHT = [1699,687];

if ~exist(dir_rootoutput, 'dir')
    mkdir(dir_rootoutput);
end

files = dir(dir_input);
files = files([files.isdir]); %only load the output

files(1:2) = []; %ignore . and ..

%%

for file_index = 1:length(files)
    %Don't recrop the same fil
    if ~findstr(files(file_index).name,'TPS') %Make sure it's an image output
        continue;
    end
   
    %load
    data = loadTifSequence(fullfile(dir_input,files(file_index).name));
    %crop?
    if DO_CROP
        data = data(TOP_LEFT(1):BOTTOM_RIGHT(1),TOP_LEFT(2):BOTTOM_RIGHT(2),:);
    end
    %save
    save3DTif(data,fullfile(dir_rootoutput,[PREPEND files(file_index).name '.tif']));
end
