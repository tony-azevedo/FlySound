function varargout = scimStackMotionCorrTiff(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
parse(p,varargin{:});

varargout = {[]};

imdir = regexprep(data.name,{'Raw','.mat','Acquisition'},{'Images','','Raw_Data'});
if ~isdir(imdir)
    error('No Camera Input: Exiting %s routine',mfilename);
end

%%  Load the frames from the Image directory
%[filename, pathname] = uigetfile('*.tif', 'Select TIF-file');
imagefiles = dir(fullfile(imdir,[params.protocol '_Image_*']));
if length(imagefiles)==0
    error('No Camera Input: Exiting %s routine',mfilename);
end
i_info = imfinfo(fullfile(imdir,imagefiles(1).name));
chans = regexp(i_info(1).ImageDescription,'state.acq.acquiringChannel\d=1');
num_chan = length(chans);

num_frame = round(length(i_info)/num_chan);
im = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',1,'Info',i_info);
num_px = size(im);

I0 = zeros([num_px(:); num_frame; num_chan]', 'double');  %preallocate 3-D array
%read in .tif files
tic; fprintf('Loading: %s\n',imagefiles(1).name); 
for frame=1:num_frame
    for chan = 1:num_chan
        [I0(:,:,frame,chan)] = imread(fullfile(imdir,imagefiles(1).name),'tiff',...
            'Index',(2*(frame-1)+chan),'Info',i_info);
    end
end
toc

%% Do motion correction here

% Green is always channel 2 for scim
I = I0;
if p.Results.MotionCorrection
    ref_frame = I(:,:,1,2);
    ref_FFT = fft2(ref_frame);
    for frame=2:num_frame
        [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,frame,2)),1);
        I(:,:,frame,2) = real(ifft2(Greg));
    end
end

I_processed = I;

% Gaussian Smoothing across frames
%     sigma = 4;
%     fsize = size(I_processed,3);
%     x = linspace(-fsize+1,fsize,2*fsize);
%     gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
%     gaussFilter = gaussFilter / sum (gaussFilter);
%
%     for i=1:size(I_processed,1)
%         for j=1:size(I_processed,2)
%             I_temp = squeeze(I_processed(i,j,:,2));
%             nel = length(I_temp);
%             I_temp = [I_temp; flipud(I_temp(end-20:end))];
%             I_temp = conv(I_temp, gaussFilter, 'same');
%             I_processed(i,j,:,2) = I_temp(1:nel);
%         end
%     end

% simple smoothing across frames
for frame=2:2:num_frame
    I_processed(:,:,frame/2,2) = mean(I(:,:,frame-[1 0],2),3);
end
I_processed = I_processed(:,:,1:frame/2,2);

curdir = pwd;
cd(imdir);

fprintf('Making Uncorrected Tiff\n');

outputFileName = ['Scim_movUnCor_' imagefiles(1).name];
if exist(outputFileName,'file')
    delete(outputFileName);
end

% make tif stacks of dff and maximum intensity
for frame = 1:size(I0,3)
    if frame ==1
        t = Tiff(outputFileName, 'w');
        tagstruct.ImageLength = size(I0,1);
        tagstruct.ImageWidth = size(I0,2);
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
        tagstruct.BitsPerSample = 16;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        t.setTag(tagstruct);
        % t.write(uint16(I_processed(:, :, frame,2)));
        t.write(uint16(I0(:, :, frame)));
        t.close();
    else
        t = Tiff(outputFileName, 'a');
        tagstruct.ImageLength = size(I0,1);
        tagstruct.ImageWidth = size(I0,2);
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
        tagstruct.BitsPerSample = 16;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        t.setTag(tagstruct);
        % t.write(uint16(I0(:, :, frame,2)));
        t.write(uint16(I0(:, :, frame,2)));
        t.close();
    end
end

fprintf('Making Corrected Tiff\n');

outputFileName = ['Scim_movCor_' imagefiles(1).name];
if exist(outputFileName,'file')
    delete(outputFileName);
end

% make tif stacks of dff and maximum intensity
for frame = 1:size(I_processed,3)
    if frame ==1
        t = Tiff(outputFileName, 'w');
        tagstruct.ImageLength = size(I,1);
        tagstruct.ImageWidth = size(I,2);
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
        tagstruct.BitsPerSample = 16;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        t.setTag(tagstruct);
        % t.write(uint16(I_processed(:, :, frame,2)));
        t.write(uint16(I_processed(:, :, frame)));
        t.close();
    else
        t = Tiff(outputFileName, 'a');
        tagstruct.ImageLength = size(I,1);
        tagstruct.ImageWidth = size(I,2);
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
        tagstruct.BitsPerSample = 16;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';
        t.setTag(tagstruct);
        % t.write(uint16(I_processed(:, :, frame,2)));
        t.write(uint16(I_processed(:, :, frame)));
        t.close();
    end
end
cd(curdir);

