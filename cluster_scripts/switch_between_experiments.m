%Swapping the target directory
%MUST be ran in root repo directory!

%Eggplant directory:
%target_dir = '/mp/nas0/ExSeq/AutoSeq2/xy10HP'; %No trailing slash!
%target_dir = '/mp/nas0/SplintR/09deconv'; %No trailing slash!
%target_dir = '/mp/nas0/SplintR/09deconv'; %No trailing slash!
target_dir = '/mp/nas0/SplintR/09deconv'; %No trailing slash!
%target_dir = '/mp/nas0/SplintR/splintr2/OzSplintr2/outputroi1_reprocess'; %No trailing slash!

status = system(sprintf('unlink %s','1_deconvolution'));
status = system(sprintf('unlink %s','2_color-correction'));
status = system(sprintf('unlink %s','3_normalization'));
status = system(sprintf('unlink %s','4_registration'));
status = system(sprintf('unlink %s','5_puncta-extraction'));
status = system(sprintf('unlink %s','6_base-calling'));


status = system(sprintf('ln -s %s/1_deconvolution/ 1_deconvolution',target_dir));
status = system(sprintf('ln -s %s/2_color-correction/ 2_color-correction',target_dir));
status = system(sprintf('ln -s %s/3_normalization/ 3_normalization',target_dir));
status = system(sprintf('ln -s %s/4_registration/ 4_registration',target_dir));
status = system(sprintf('ln -s %s/5_puncta-extraction/ 5_puncta-extraction',target_dir));
status = system(sprintf('ln -s %s/6_base-calling/ 6_base-calling',target_dir));

