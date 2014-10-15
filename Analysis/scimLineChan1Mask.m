function varargout = scimLineChan1Mask(data,params,varargin)
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
num_frame = length(i_info);
chans = regexp(i_info(1).ImageDescription,'state.acq.acquiringChannel\d=1');
num_chan = length(chans);

im = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',1,'Info',i_info);
num_px = size(im);

exp_t = makeLineScanTime(i_info,params);

I = zeros([num_px(:); num_frame; 1]', 'double');  %preallocate 3-D array
%read in .tif files
for frame=1:num_frame
    [I(:,:,frame,1)] = imread(fullfile(imdir,imagefiles(1).name),'tiff','Index',frame,'Info',i_info);
end

I = squeeze(I);

%% select ROI 
I_red = I(:,:,1);
I_green = I(:,:,2);

red_pix = mean(I_red,1);
Chan1mean = mean(red_pix);
Chan1sd = std(red_pix);
Chan1TH = Chan1mean+.2*Chan1sd;
I_mask = red_pix;
I_mask(red_pix>Chan1TH) = 1;
I_mask(red_pix<=Chan1TH) = 0;
I_mask = repmat(I_mask,size(I_red,1),1);

roi_temp = getpref('quickshowPrefs','scimLineChan1Mask');
if strcmp(button,'Yes')
    
    roifig = figure;
    set(roifig,'position',[680     9   560   988]);
    
    panl = panel(roifig);
    panl.pack('h',{1/3 1/3 1/3})  % response panel, stimulus panel
    
    imshow(I_red,[],'initialmagnification','fit','parent',panl(1).select());%,'DisplayRange',[0 1000]);
    imshow(I_green,[],'initialmagnification','fit','parent',panl(2).select());%,'DisplayRange',[0 1000]);
    
    imshow(cat(3,I_mask,I_green/max(I_green(:)),I_mask),[],'initialmagnification','fit','parent',panl(3).select());%,'DisplayRange',[0 1000]);
    
    roi_temp = [roi_temp(1),0,roi_temp(3),num_px(1)];
    rectangle('position',roi_temp,'parent',panl(3).select(),'edgecolor',[1 0 0]);
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
    data.ROI = {};
    roi_rect = imrect(panl(3).select());
    roi_temp = wait(roi_rect);
    roi_temp = [roi_temp(1),0,roi_temp(3),num_px(1)];
    setPosition(roi_rect,roi_temp);
end

roi_temp(1) = max(1,floor(roi_temp(1)));
roi_temp(2) = max(1,floor(roi_temp(2)));
roi_temp(3) = ceil(roi_temp(3));
roi_temp(4) = ceil(roi_temp(4));
mask_mask = I_mask;
mask_mask(:) = 0;
mask_mask(roi_temp(2):roi_temp(2)-1+roi_temp(4),roi_temp(1):roi_temp(1)-1+roi_temp(3)) = 1;

I_mask = I_mask.*mask_mask;

%% Calculate across ROIs 
I_traces = nan([length(exp_t),num_chan,size(roi_temp,1)]);
I_masked = I;
I_masked(~repmat(I_mask,[1 1 num_chan]))=nan;
I_trace = squeeze(nanmean(I_masked,2));
I_traces(:,:,1) = I_trace(1:length(exp_t),:);


%% Save the trace to the trial
data.scimLineTrace = I_traces;
setpref('quickshowPrefs','scimLineChan1Mask',roi_temp)
data.exposureTimes = exp_t;
data.channel1Threshold = Chan1TH;

if isfield(data,'lineScanChan1Mask')
data = rmfield(data,'lineScanChan1Mask')
end
if isfield(data,'scimStackTrace')
data = rmfield(data,'scimStackTrace')
end

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');

%% plotting traces
if p.Results.PlotFlag

figure(fig);
set(fig,'color',[1 1 1])
panl = panel(fig);

panl.pack('v',{1/3 2/3})  % response panel, stimulus panel
panl.margin = [18 10 2 10];
panl.fontname = 'Arial';
panl(1).marginbottom = 2;
panl(2).margintop = 8;

[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
    
panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum])
set(fig,'name',[dateID '_' flynum '_' cellnum '_' protocol '_' trialnum '_' mfilename])

im_ax = panl(1).select();
set(im_ax,'tag',[mfilename '_im_ax']);
cla(im_ax,'reset');

roi_ax = panl(2).select();
set(roi_ax,'tag',[mfilename '_roi_ax']);
cla(roi_ax,'reset');

I_norm = max([I_red(:);I_green(:)]);
I_tricolor = cat(3,I_red/I_norm,I_green/I_norm,I_red/I_norm);

imshow(permute(I_tricolor,[2,1,3]),[],'initialmagnification','fit','parent',im_ax);
colors = [1 0 1; 0 1 0];

for n = p.Results.Channels
    line(exp_t,I_traces(:,n,1),...
        'parent',roi_ax,...
        'tag',['fluo_trace_',num2str(n)],...
        'color',colors(n,:),...
        'displayname',[num2str(n)])
end

axis(roi_ax,'tight');
ylabel(roi_ax,'F (counts)')
xlabel(roi_ax,'Time (s)')

h = legend(roi_ax,'show','location','best');
set(h,'fontsize',6,'box','off')

end

function exp_t = makeLineScanTime(i_info,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.msPerLine=','end');
delta_t = str2double(dscr(strstart+1))/1000;
t = makeInTime(params);
delta_t_ind = find(t==t(1)+delta_t);
exp_t = t(1:delta_t_ind-1:length(t));
try exp_t = exp_t(1:i_info(1).Height);
catch
    warning('Line scan has more lines than time vector');
    exp_t = exp_t(1:min(i_info(1).Height,length(exp_t)));
end





