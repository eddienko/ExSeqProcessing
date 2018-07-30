function [mag vect precomp_grads yy ix] = GetGradOri_vector(pix,r,c,s, fv, sift_params, precomp_grads)

rows = sift_params.pix_size(1);
cols = sift_params.pix_size(2);
slices = sift_params.pix_size(3);

% clamp r,c,s to the bounds of the img (pix)
if r < 1
    r = 1;
end
if c < 1
    c = 1;
end
if s < 1
    s = 1;
end
if r > rows
    r = rows;
end
if c > cols
    c = cols;
end
if s > slices
    s = slices;
end

%% Check if computed the gradient previously before
%if (precomp_grads.count(r,c,s) > 0)
    %precomp_grads.count(r,c,s) = precomp_grads.count(r,c,s) + 1; %increment counter
    %% retrieve the data
    %mag = precomp_grads.mag(r,c,s);
    %vect = precomp_grads.vect(r,c,s, 1, 3);
    %yy = precomp_grads.yy(r,c,s,1:sift_params.Tessel_thresh, 1);
    %ix = precomp_grads.ix(r,c,s,1:sift_params.Tessel_thresh, 1);
    %return
%end

if (c == 1)
    xgrad = 2.0 * (double(pix(r,c+1,s)) - double(pix(r,c,s)));
elseif (c == cols)
    xgrad = 2.0 * (double(pix(r,c,s)) - double(pix(r,c-1,s)));
else
    xgrad = double(pix(r,c+1,s)) - double(pix(r,c-1,s));
end
if (r == 1)
    ygrad = 2.0 * (double(pix(r,c,s)) - double(pix(r+1,c,s)));
elseif (r == rows)
    ygrad = 2.0 * (double(pix(r-1,c,s)) - double(pix(r,c,s)));
else
    ygrad = double(pix(r-1,c,s)) - double(pix(r+1,c,s));
end
if (s == 1)
    zgrad = 2.0 * (double(pix(r,c,s+1)) - double(pix(r,c,s)));
elseif (s == slices)
    zgrad = 2.0 * (double(pix(r,c,s)) - double(pix(r,c,s-1)));
else
    zgrad = double(pix(r,c,s+1)) - double(pix(r,c,s-1));
end

xgrad = double(xgrad);
ygrad = double(ygrad);
zgrad = double(zgrad);

mag = sqrt(xgrad * xgrad + ygrad * ygrad + zgrad * zgrad);

if mag ~=0
    vect = [xgrad ygrad zgrad] ./ mag;
else
    vect = [1 0 0];
end

%Find the nearest tesselation face indices
corr_array = fv.centers * vect';
[yy ix] = sort(corr_array,'descend');

idx = sub2ind([rows, cols, slices], r,c,s);
if ((r == 1) && (c == 1) && (s == 4))
    fprintf('mlab idx%d vect0 %.54f vect1 %.54f vect2 %.54f image[idx]%d r%d c%d t%d yy: %.4f %.4f %.54f %.54f ix: %d %d %d %d eq:%d, diff:%.54f\n', ...
        idx - 1, vect(1), vect(2), vect(3), pix(r,c,s), r-1, c-1, s-1, yy(1), yy(2), yy(3), yy(4), ix(1) - 1, ix(2) - 1, ix(3) - 1, ix(4) - 1, yy(3) == yy(4), yy(3) - yy(4));
    fprintf('fv[%d] %.54f %.54f %.54f\n',ix(3) - 1, fv.centers(ix(3), 1), fv.centers(ix(3), 2), fv.centers(ix(3), 3));
    fprintf('fv[%d] %.54f %.54f %.54f\n', ix(4) - 1, fv.centers(ix(4), 1), fv.centers(ix(4), 2), fv.centers(ix(4), 3));
    fprintf('fv[%d] %.54f %.54f %.54f\n', ix(5) - 1, fv.centers(ix(5), 1), fv.centers(ix(5), 2), fv.centers(ix(5), 3));
end


precomp_grads.count(r,c,s) = 1; % number of times seen 1
precomp_grads.mag(r,c,s) = mag;
precomp_grads.vect(r,c,s,1, 1:3) = vect; % 1 by 3
 % Tessel_thresh by 1
precomp_grads.yy(r,c,s, 1:sift_params.Tessel_thresh, 1) = yy(1:sift_params.Tessel_thresh, :);
 % Tessel_thresh by 1
precomp_grads.ix(r,c,s, 1:sift_params.Tessel_thresh, 1) = ix(1:sift_params.Tessel_thresh);
return
