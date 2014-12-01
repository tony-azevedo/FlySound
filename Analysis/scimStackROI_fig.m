function varargout = scimStackROI_fig(data,params,varargin)
% scimStackROIBatch(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('MakeMovie',true,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('Channels',[1 2],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Masks',{},@iscell);

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

exp_t = makeScimStackTime(i_info,num_frame,params);

I0 = zeros([num_px(:); num_frame; num_chan]', 'double');  %preallocate 3-D array
%read in .tif files
[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
fprintf([protocol '_' dateID '_' flynum '_' cellnum '_' trialnum '\n'])
tic; fprintf('Loading: '); 
for frame=1:num_frame
    for chan = 1:num_chan
        [I0(:,:,frame,chan)] = imread(fullfile(imdir,imagefiles(1).name),'tiff',...
            'Index',(2*(frame-1)+chan),'Info',i_info);
    end
end
toc


%% Do motion correction here

I = I0;
if p.Results.MotionCorrection
    ref_frame = I(:,:,1,2);
    ref_FFT = fft2(ref_frame);
    for frame=2:num_frame
        [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,frame,2)),1);
        I(:,:,frame,2) = real(ifft2(Greg));
    end
end

%% select ROI 
I_green = squeeze(nanmean(I(:,:,:,2),3));
I_red = squeeze(nanmean(I(:,:,:,1),3));
temp.ROI = getpref('quickshowPrefs','roiScimStackROI');
if ~isfield(data,'ROI')
    data.ROI = temp.ROI;
end

Masks = {};
roifig = figure;
set(roifig,'position',[680   361   646   646]);

panl = panel(roifig);
panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
panl(1).pack('h',{1/2 2/2})  % response panel, stimulus panel
panl(1).margin = [2 2 2 2];
panl.margin = [2 2 10 20];

imshow(I_red,[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
imshow(I_green,[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);

imshow(cat(3,I_red/max([I_red(:);I_green(:)]),I_green/max(I_green(:)),I_red/max([I_red(:);I_green(:)])),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
title('Merged image, ROI')
roidrawax = panl(2).select();

for roi_ind = 1:length(data.ROI)
    line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',roidrawax,'color',[1 0 0]);
end

%close(roifig)
[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);

panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum '\_' regexprep(mfilename,'_','\\_')])
set(roifig,'name',[dateID '_' flynum '_' cellnum '_' protocol '_' trialnum '_' mfilename])


function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
exp_t = exp_t(1:num_frame);