function varargout = fluorescence(data,params,varargin)
% dFoverF(data,params,montageflag)

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting flourescence routine\n');
    return
end

imdir = regexprep(regexprep(regexprep(data.name,'Raw','Images'),'.mat',''),'Acquisition','Raw_Data');

%% Saving images as single files.
%[filename, pathname] = uigetfile('*.tif', 'Select TIF-file');
imagefiles = dir(fullfile(imdir,[params.protocol '_Image_*']));
num_frame = length(imagefiles);
im = imread(fullfile(imdir,imagefiles(1).name));
num_px = size(im);

I = zeros([num_px(:); 1; num_frame]', 'double');  %preallocate 3-D array
%read in .tif files
for frame=1:num_frame
    [I(:,:,1,frame)] = imread(fullfile(imdir,imagefiles(frame).name));
end

%% calculates a baseline image from frame bl_start through bl_end 
t = makeInTime(params);
exp_t = data.exposure_time;
if sum(exp_t<0)
    bsln = exp_t<0 & exp_t>exp_t(1)+.02;
else
    bsln = exp_t<1 & exp_t>exp_t(1)+.02;
end
bl_numframes = nansum(bsln);
image_sum = nansum(I(:,:,1,bsln),4);
I_F0 = imdivide(image_sum, bl_numframes);

%% select ROI (implement at some point)
figure;
imshow(I_F0,[],'initialmagnification','fit');
title('Fluorescence')

if isfield(data,'ROI')
    line(data.ROI(:,1),data.ROI(:,2));
end

%%

varargout = {I};
