
fn = fullfile('/mp/nas1/share/ExSEQ/ExSeqAutoFrameA1/3_normalization/exseqautoframea1_round006_ch03SHIFT.tif');
len = 400;
img = load3DTif_uint16(fn);
%img_mini = img(1:len, 1:len, :);
img_mini = img(:, :, :);

compute_err = @(X, ref) sum(sum(sum(abs(X - ref)))) / sum(ref(:));

h = fspecial3('gaussian', 20);

%disp('Built-in convn')
%if exist('img_blur.mat')
    %img_blur = loadmat('img_blur.mat');
    %% Takes ~6100 seconds (1.7 hrs) to create
    % Several minutes to load from file
%else
    %tic; img_blur = convn(img_mini, h, 'same'); toc;
%end

disp('convnfft')
tic; img_blur_fft = convnfft(img_mini, h, 'same'); toc;
%compute_err(img_blur_fft, img_blur)

disp('Custom FFT based matlab implementation')
tic; img_blur_cust = convn_custom(img_mini, h, false); toc;
compute_err(img_blur_cust, img_blur_fft)

%disp('Custom FFT based matlab implementation power2flag')
%tic; img_blur_cust_pow2 = convn_custom(img_mini, h, true); toc;
%compute_err(img_blur_cust_pow2, img_blur)

%disp('Custom FFT based CUDA implementation')
%tic;
%toc;
%sprintf('\n\n')
