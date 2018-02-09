function varargout = scimStackChan2Mask(data,params,varargin)
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
if isempty(p.Results.dFoFfig)
    fig = findobj('tag',mfilename);
else
    fig = p.Results.dFoFfig;
end
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[1030 10 560 450],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
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


%% select ROI 
I_green = squeeze(nanmean(I0(:,:,:,2),3));
I_red = squeeze(nanmean(I0(:,:,:,1),3));

Chan2mean = mean(I_green(:));
Chan2sd = std(I_green(:));

% These are the brightest points
Chan2TH = Chan2mean+1.6*Chan2sd;
I_mask = I_green;
I_mask(I_green>Chan2TH) = 1;
I_mask(I_green<=Chan2TH) = 0;

% Extend the mask slightly
rind = maskRind(I_mask);
for i = 1:4
    I_mask = I_mask+maskRind(I_mask);
    I_mask(I_mask>0) = 1;
    % imshow(I_mask,[],'initialmagnification','fit');
end
I_mask = imfill(I_mask,'holes');
I_mask = myImfill(I_mask);

roi_temp = getacqpref('quickshowPrefs','scimStackChan2Mask');
if strcmp(button,'Yes')
    roifig = figure;
    set(roifig,'position',[680   361   646   646],'color',[1 1 1]);

    panl = panel(roifig);
    panl.pack('v',{1/4 3/4})  % response panel, stimulus panel
    panl(1).pack('h',{1/2 1/2})  % response panel, stimulus panel
    panl(1).margin = [2 2 2 2];
    
    imshow(cat(3,I_red/max(I_red(:)),zeros(size(I_green)),I_red/max(I_red(:))),[],'initialmagnification','fit','parent',panl(1,1).select());%,'DisplayRange',[0 1000]);
    imshow(cat(3,zeros(size(I_green)),I_green/max(I_green(:)),zeros(size(I_green))),[],'initialmagnification','fit','parent',panl(1,2).select());%,'DisplayRange',[0 1000]);
    
    imshow(cat(3,rind,I_green/max(I_green(:)),I_mask*2/3),[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
    roidrawax = panl(2).select();
    
    rectangle('position',roi_temp,'parent',roidrawax,'edgecolor',[1 0 0]);
    
    button = questdlg('Make new ROI?','ROI','No');
    if strcmp(button,'No')
        close(roifig)
    end
    if strcmp(button,'Cancel')
        close(roifig)
        fprintf('Quiting analysis\n');
        return
    end
end
if strcmp(button,'Yes');
    title('Threshold ROI, double click when done')
    data.ROI = {};
    roihand = imrect(roidrawax);
    roi_temp = wait(roihand);
    close(roifig)
end

roi_temp(1) = max(1,floor(roi_temp(1)));
roi_temp(2) = max(1,floor(roi_temp(2)));
roi_temp(3) = ceil(roi_temp(3));
roi_temp(4) = ceil(roi_temp(4));
mask_mask = I_mask;
mask_mask(:) = 0;
mask_mask(roi_temp(2):roi_temp(2)+roi_temp(4),roi_temp(1):roi_temp(1)+roi_temp(3)) = 1;

I_mask = I_mask.*mask_mask;

%% Calculate across ROIs 
tic; fprintf('Calculating: ');
I_traces = nan(num_frame,num_chan,size(roi_temp,1));
I_masked = I;

I_masked(~repmat(I_mask,[1 1 num_frame num_chan]))=nan;
I_trace = squeeze(nanmean(nanmean(I_masked,2),1));
I_traces(:,:,1) = I_trace;


%% Save the trace to the trial
tic; fprintf('Saving: '); 
setacqpref('quickshowPrefs','scimStackChan2Mask',roi_temp)
data.scimStackTrace = I_traces;
data.exposureTimes = exp_t;
data.channel2Threshold = Chan2TH;
data.channel2roi = roi_temp;
save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');
toc

varargout = {data};

%% plotting traces
if p.Results.PlotFlag
    
    figure(fig);
    set(fig,'color',[1 1 1])
    panl = panel(fig);
    
    panl.pack('v',{1/2 1/2})  % response panel, stimulus panel
    panl.margin = [18 16 2 10];
    panl.fontname = 'Arial';
    panl(1).marginbottom = 16;
    panl(2).margintop = 16;
    
    panl(1).pack('h',{1/3 1/3 1/3})
    %p(1).de.margin = 2;
    
    [protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
    
    panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum '\_' mfilename])
    set(fig,'name',[dateID '_' flynum '_' cellnum '_' protocol '_' trialnum '_' mfilename])
    
    % control_ax = panl(1,1).select();
    mask_roi_ax = panl(1,1).select();
    set(mask_roi_ax,'tag',[mfilename '_maskroi_ax']);
    cla(mask_roi_ax,'reset');
    
    red_roi_ax = panl(1,2).select();
    set(red_roi_ax,'tag',[mfilename '_redroi_ax']);
    cla(red_roi_ax,'reset');
    
    green_roi_ax = panl(1,3).select();
    set(green_roi_ax,'tag',[mfilename '_greenroi_ax']);
    cla(green_roi_ax,'reset');
    
    panl(2).pack('h',{1/2 1/2})
    
    absolute_ax = panl(2,1).select();
    set(absolute_ax,'tag',[mfilename '_absolute_ax']);
    cla(absolute_ax,'reset');
    
    ax = panl(2,2).select();
    set(ax,'tag',[mfilename '_ax']);
    cla(ax,'reset');
    
    % ROI
    imshow(I_mask,[],'initialmagnification','fit','parent',mask_roi_ax);%,'DisplayRange',[0 1000]);
    imshow(I_green,[],'initialmagnification','fit','parent',green_roi_ax);%,'DisplayRange',[0 1000]);
    imshow(I_red,[],'initialmagnification','fit','parent',red_roi_ax);%,'DisplayRange',[0 1000]);
    colors = [1 0 1; 0 1 0];
    
    for n = p.Results.Channels
        line(exp_t,I_traces(:,n,1),...
            'parent',absolute_ax,...
            'tag',['fluo_trace_',num2str(n),'_',num2str(1)],...
            'color',colors(n,:),...
            'displayname',[num2str(n)])
    end
    
    axis(absolute_ax,'tight');
    ylabel(absolute_ax,'F (counts)')
    xlabel(absolute_ax,'Time (s)')
    
    h = legend(absolute_ax,'show','location','best');
    set(h,'fontsize',6,'box','off')
    
    if sum(exp_t<0)
        bsln = exp_t<0 & exp_t>exp_t(1)+.02;
    else
        bsln = exp_t<1 & exp_t>exp_t(1)+.02;
    end
    
    for n = 2
        line(exp_t,(I_traces(:,n,1)/nanmean(I_traces(bsln,n,1))-1)*100,...
            'parent',ax,...
            'tag',['fluo_trace_',num2str(n),'_',num2str(1)],...
            'color',colors(n,:),...
            'displayname',[num2str(n)])
    end
    % l = line(exp_t,dFoverF_fulltrace,'parent',ax,'color','k');
    % set(l,'tag','dFoverF_trace','displayname',imdir)
    axis(ax,'tight');
    ylabel(ax,'% \Delta F / F')
    xlabel(ax,'Time (s)')
    
end

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
