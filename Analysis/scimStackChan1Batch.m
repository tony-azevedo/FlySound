function varargout = scimStackChan1Batch(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('PlotFlag',true,@islogical);
p.addParameter('Channels',[1 2],@isnumeric);
parse(p,varargin{:});

varargout = {[]};

imdir = regexprep(data.name,{'Raw','.mat','Acquisition'},{'Images','','Raw_Data'});
if ~isdir(imdir)
    error('No Camera Input: Exiting %s routine',mfilename);
end
if isempty(p.Results.dFoFfig)
    fig = findobj('tag',mfilename);
else
    fig = p.Results.dFoFfig;
end
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[1030 10 560 450],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end

button = p.Results.NewROI;

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
panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
panl(1).pack('h',{1/2 1/2})  % response panel, stimulus panel
panl(1).margin = [2 2 2 2];

imshow(cat(3,I_red/max(I_red(:)),zeros(size(I_green)),I_red/max(I_red(:))),[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
imshow(cat(3,zeros(size(I_green)),I_green/max(I_green(:)),zeros(size(I_green))),[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);

imshow(cat(3,I_mask,I_green/max(I_green(:)),I_mask),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
title('Threshold ROI, double click when done')
roidrawax = panl(2).select();

roi_temp = getpref('quickshowPrefs','scimStackChan1Mask');
rectangle('position',roi_temp,'parent',roidrawax,'edgecolor',[1 0 0]);
button = questdlg('Make new ROI?','ROI','No');
if strcmp(button,'Yes');
    data.ROI = {};
    roihand = imrect(roidrawax);
    roi_temp = wait(roihand);
end

close(roifig)

roi_temp(1) = max(1,floor(roi_temp(1)));
roi_temp(2) = max(1,floor(roi_temp(2)));
roi_temp(3) = ceil(roi_temp(3));
roi_temp(4) = ceil(roi_temp(4));

%% Save the trace to the trial
setpref('quickshowPrefs','scimStackChan1Mask',roi_temp)

%% Batch process the bunch using the same ROI.

[protocol,dateID,flynum,cellnum,trialnum,D,trialStem,datastructfile] = extractRawIdentifiers(data.name);
prtclData = load(datastructfile);
prtclData = prtclData.data;
blocktrials = findLikeTrials('name',data.name,'datastruct',prtclData,'exclude',{'displacement','freq','amp','step'});

for bt = blocktrials;
    data_block = load(fullfile(D,sprintf(trialStem,bt)));
    scimStackChan1Mask(data_block,data_block.params,'NewROI','No','PlotFlag',false,'dFoFfig',fig,varargin{:});
end

data = load(fullfile(D,sprintf(trialStem,data.params.trial)));

scimStackChan1Mask(data,data.params,'NewROI','No','PlotFlag',true,'dFoFfig',fig,varargin{:});

varargout = {data};




function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
try exp_t = exp_t(1:num_frame);
catch
    warning('stack has more frames than time vector');
    exp_t = exp_t(1:min(num_frame,length(exp_t)));
end
