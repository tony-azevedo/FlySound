function varargout = scimStackROIBatch(data,params,varargin)
% scimStackROI(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('MakeMovie',true,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);
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

%% select ROI 
I_green = squeeze(nanmean(I(:,:,:,2),3));
I_red = squeeze(nanmean(I(:,:,:,1),3));
temp.ROI = getpref('quickshowPrefs','roiScimStackROI');

if strcmp(button,'Yes');
    roifig = figure;
    set(roifig,'position',[680   361   646   646]);
    
    panl = panel(roifig);
    panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
    panl(1).pack('h',{1/2 2/2})  % response panel, stimulus panel
    panl(1).margin = [2 2 2 2];

    imshow(I_red,[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
    imshow(I_green,[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
    
    imshow(cat(3,I_red/max(I_red(:)),I_green/max(I_green(:)),I_red/max(I_red(:))),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
    title('Draw ROI, close figure when done')
    roidrawax = panl(2).select();
    
    if ~isfield(data,'ROI')
        data.ROI = temp.ROI;
    end
    for roi_ind = 1:length(data.ROI)
        line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',roidrawax,'color',[1 0 0]);
    end 
    button = questdlg('Make new ROI?','ROI','No');
    if strcmp(button,'No')
        for roi_ind = 1:length(data.ROI)
            roihand = impoly(roidrawax,data.ROI{roi_ind});
            Masks{roi_ind} = createMask(roihand);
        end
        close(roifig)
    end
    if strcmp(button,'Cancel')
        close(roifig)
        fprintf('Quiting analysis\n');
        return
    end
end
if strcmp(button,'Yes');
    data.ROI = {};
    roihand = imfreehand(roidrawax,'Closed',1);
    roi_temp = wait(roihand);
    data.ROI{1} = roi_temp;
    while ishandle(roifig) && sum(roi_temp(3:end)>2)
        roihand = imfreehand(roidrawax,'Closed',1);
        roi_temp = wait(roihand);
        if size(roi_temp,1)<=2
            break
        end
        data.ROI{end+1} = roi_temp;
        Masks{roihand} = createMask(roihand);

    end
    close(roifig);
    toc, fprintf('Closing');
    temp.ROI = data.ROI;

else
    if isempty(Masks)
        error('There is no mask with which to choose an ROI');
    end
end

%% Save the ROI preference
setpref('quickshowPrefs','scimStackChan1Mask',temp.ROI)

%% Batch process the bunch using the same ROI.

[protocol,dateID,flynum,cellnum,trialnum,D,trialStem,datastructfile] = extractRawIdentifiers(data.name);
prtclData = load(datastructfile);
prtclData = prtclData.data;
blocktrials = findLikeTrials('name',data.name,'datastruct',prtclData,'exclude',{'displacement','freq','amp','step'});

for bt = blocktrials;
    data_block = load(fullfile(D,sprintf(trialStem,bt)));
    scimStackROI(data_block,data_block.params,'NewROI','No','Masks',Masks,'MakeMovie',false,'PlotFlag',false,'dFoFfig',fig,varargin{:});
end

data = load(fullfile(D,sprintf(trialStem,data.params.trial)));

scimStackROI(data_block,data_block.params,'NewROI','No','Masks',Masks,'MakeMovie',false,'PlotFlag',true,'dFoFfig',fig,varargin{:});

varargout = {data};


function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
exp_t = exp_t(1:num_frame);