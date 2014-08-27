function varargout = roiScimStack(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('ShowMovies',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);
p.addParameter('Channels',[2],@isnumeric);
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

if ~isfield(data,'ROI') || ~strcmp(p.Results.NewROI,'No');
    roifig = figure;
    set(roifig,'position',[680   361   646   646]);
    I_green = squeeze(nanmean(I0(:,:,:,2),3));
    imshow(I_green,[],'initialmagnification','fit','DisplayRange',[0 1000]);
    title('Draw ROI, close figure when done')
    roidrawax = get(roifig,'children');
    
    if isfield(data,'ROI')
        for roi_ind = 1:length(data.ROI)
            line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',roidrawax,'color',[1 0 0]);
        end
        button = questdlg('Make new ROI?','ROI','No');
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
        end
    end
end


%% Calculate across ROIs 
tic; fprintf('Calculating: ');
I_traces = nan(num_frame,num_chan,length(data.ROI));
for roi_ind = 1:length(data.ROI)
    I_masked = I0;
    roihand = impoly(roidrawax,data.ROI{roi_ind});
    mask = createMask(roihand);
    I_masked(~repmat(mask,[1 1 num_frame num_chan]))=nan;
    I_trace = squeeze(nanmean(nanmean(I_masked,2),1));
    I_traces(:,:,roi_ind) = I_trace;
end
toc
close(roifig);

%% Save the trace to the trial
tic; fprintf('Saving: '); 
data.roiLineScanTrace = I_traces;
data.exposureTimes = exp_t;

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');
toc

%% plotting traces

figure(fig);
set(fig,'color',[1 1 1])
panl = panel(fig);

panl.pack('v',{1/3 2/3})  % response panel, stimulus panel
panl.margin = [18 16 2 2];
panl.fontname = 'Arial';
panl(1).marginbottom = 16;
panl(2).margintop = 16;

panl(1).pack('h',{1/3 2/3})
%p(1).de.margin = 2;

[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
    
panl.title([protocol '\_' dateID '\_' flynum '\_' cellnum '\_' trialnum])

roi_ax = panl(1,1).select();
set(roi_ax,'tag',[mfilename '_roi_ax']);
cla(roi_ax,'reset');

absolute_ax = panl(1,2).select();
set(absolute_ax,'tag',[mfilename '_absolute_ax']);
cla(absolute_ax,'reset');

ax = panl(2).select();
set(ax,'tag',[mfilename '_ax']);
cla(ax,'reset');

% ROI
imshow(I_green,[],'initialmagnification','fit','parent',roi_ax,'DisplayRange',[0 1000]);
colors = [1 0 0; 0 1 0];

for roi_ind = 1:length(data.ROI)
    line(data.ROI{roi_ind}(:,1),data.ROI{roi_ind}(:,2),'parent',roi_ax,...
        'color',[0 0 1]*(1-(roi_ind-1)/length(data.ROI)),'tag',['roi_',num2str(roi_ind)]);
    for n = p.Results.Channels
        line(exp_t,I_traces(:,n,roi_ind),...
            'parent',absolute_ax,...
            'tag',['fluo_trace_',num2str(n),'_',num2str(roi_ind)],...
            'color',colors(n,:)*(1-(roi_ind-1)/length(data.ROI)),...
            'displayname',[num2str(n),'_',num2str(roi_ind)])
    end
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

for roi_ind = 1:length(data.ROI)
    for n = p.Results.Channels
        line(exp_t,I_traces(:,n,roi_ind)/nanmean(I_traces(bsln,n,roi_ind))*100,...
            'parent',ax,...
            'tag',['fluo_trace_',num2str(n),'_',num2str(roi_ind)],...
            'color',colors(n,:)*(1-(roi_ind-1)/length(data.ROI)),...
            'displayname',[num2str(n),'_',num2str(roi_ind)])
    end
end
% l = line(exp_t,dFoverF_fulltrace,'parent',ax,'color','k');
% set(l,'tag','dFoverF_trace','displayname',imdir)
axis(ax,'tight');
ylabel(ax,'% \Delta F / F')
xlabel(ax,'Time (s)')

set(fig,'units','pixels');
pos = get(fig,'position');
delete(findobj(fig,'type','uicontrol'))
roi_text = uicontrol('style','text',...
    'position',[8 pos(4)-30 24 16],...
    'string','ROI',...
    'parent',fig,...
    'fontsize',8,...
    'BackgroundColor',[1 1 1]);
chan_text = uicontrol('style','text',...
    'position',[32 pos(4)-30 24 16],...
    'string','Ch',...
    'parent',fig,...
    'fontsize',8,...
    'BackgroundColor',[1 1 1]);
roinum = length(findobj('-regexp', 'tag', 'roi_'));
for roi_ind = 1:roinum
    ui_checks(roi_ind) = uicontrol('style','checkbox',...
        'position',[8 pos(4)-30 24 16],...
        'string','Ch',...
        'parent',fig,...
        'fontsize',8,...
        'BackgroundColor',[1 1 1],...
        'tag',['roi_' num2str(roi_ind)]);
    
end


function exp_t = makeScimStackTime(i_info,num_frame,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.frameRate=','end');
strend = regexp(dscr,'state.acq.frameRate=\d*\.\d*','end');
delta_t = 1/str2double(dscr(strstart+1:strend));
t = makeInTime(params);
exp_t = [fliplr([-delta_t:-delta_t:t(1)]), 0:delta_t:t(end)];
exp_t = exp_t(1:num_frame);