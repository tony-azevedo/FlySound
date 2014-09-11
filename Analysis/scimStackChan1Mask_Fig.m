function varargout = scimStackChan1Mask_Fig(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('ShowMovies',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
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
tic; fprintf('Loading: '); 
for frame=1:num_frame
    for chan = 1:num_chan
        [I0(:,:,frame,chan)] = imread(fullfile(imdir,imagefiles(1).name),'tiff',...
            'Index',(2*(frame-1)+chan),'Info',i_info);
    end
end
toc

% Green is always channel 2 for scim

%% select ROI 
roifig = figure;
set(roifig,'position',[680   361   646   646],'color',[1 1 1]);
I_green = squeeze(nanmean(I0(:,:,:,2),3));
I_red = squeeze(nanmean(I0(:,:,:,1),3));

Chan1mean = mean(I_red(:));
Chan1sd = std(I_red(:));
Chan1TH = Chan1mean+2*Chan1sd;
I_mask = I_red;
I_mask(I_red>Chan1TH) = 1;
I_mask(I_red<=Chan1TH) = 0;

panl = panel(roifig);
panl.margin = [18 16 2 10];
panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
panl(1).pack('h',{1/2 1/2})  % response panel, stimulus panel
panl(1).margin = [2 2 2 2];
panl(2).margin = [2 2 2 2];

imshow(cat(3,I_red/max(I_red(:)),zeros(size(I_green)),I_red/max(I_red(:))),[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
imshow(cat(3,zeros(size(I_green)),I_green/max(I_green(:)),zeros(size(I_green))),[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);

imshow(cat(3,I_mask,I_green/max(I_green(:)),I_mask),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
    
panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum])
set(roifig,'name',['mask' '_' protocol '_' trialnum]);
roidrawax = panl(2).select();

roi_temp = getpref('quickshowPrefs','scimStackChan1Mask');
rectangle('position',roi_temp,'parent',roidrawax,'edgecolor',[1 0 0]);

%close(roifig)

