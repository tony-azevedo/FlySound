function varargout = scimLineROI(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('ShowMovies',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);

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

if ~isfield(data,'ROI') || ~strcmp(p.Results.NewROI,'No');
    roifig = figure;
    set(roifig,'position',[680     9   560   988]);
    I_tricolor = I; I_tricolor(:,:,3) = I(:,:,1);
    imshow(I_tricolor,[],'initialmagnification','fit');
    title('Draw ROI, close figure when done')
    roidrawax = get(roifig,'children');
    
    if isfield(data,'ROI')
        for roi_ind = 1:size(data.ROI,1)
            quad(1,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)];
            quad(2,:) = [data.ROI(roi_ind,1)+data.ROI(roi_ind,3),data.ROI(roi_ind,2)];
            quad(3,:) = [data.ROI(roi_ind,1)+data.ROI(roi_ind,3),data.ROI(roi_ind,2)+data.ROI(roi_ind,4)];
            quad(4,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)+data.ROI(roi_ind,4)];
            quad(5,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)];
            
            line(quad(:,1),quad(:,2),'parent',roidrawax,'color',[1 0 0]);
        end
        button = questdlg('Make new ROI?','ROI','No');
    end
    if strcmp(button,'Yes');
        roirect = imrect(roidrawax);
        roi_temp = wait(roirect);
        data.ROI(1,:) = [roi_temp(1),0,roi_temp(3),num_px(1)];
        setPosition(roirect,data.ROI(end,:));
        while ishandle(roifig) && sum(roi_temp(3:end)>2)
            roirect = imrect(roidrawax);
            roi_temp = wait(roirect);
            if sum(roi_temp(3:end)<=2)
                break
            end
            data.ROI(end+1,:) = [roi_temp(1),0,roi_temp(3),num_px(1)];
            setPosition(roirect,data.ROI(end,:));
        end
    end
end

%% Assumptions: 
% # baseline F is composed of F0 from cell and F0_bg, from the background. 
% # F0_bg is uniform and a proxy for the contribution of other cells;

I_traces = nan(num_px(1),num_frame,size(data.ROI,1));
for roi_ind = 1:size(data.ROI,1)
    I_masked = I;
    roirect = imrect(roidrawax,data.ROI(roi_ind,:,:));
    mask = createMask(roirect);
    I_masked(~repmat(mask,[1 1 num_frame]))=nan;
    I_trace = squeeze(nanmean(I_masked,2));
    I_traces(:,:,roi_ind) = I_trace;
end

close(roifig);
%% Save the trace to the trial
data.roiLineScanTrace = I_traces;

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');

%% plotting traces

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

im_ax = panl(1).select();
set(im_ax,'tag',[mfilename '_im_ax']);
cla(im_ax,'reset');

roi_ax = panl(2).select();
set(roi_ax,'tag',[mfilename '_roi_ax']);
cla(roi_ax,'reset');

% ROI
I_tricolor = I; 
I_tricolor(:,:,3) = I(:,:,1);
imshow(permute(I_tricolor,[2,1,3]),[],'initialmagnification','fit','parent',im_ax);
colors = [1 0 1; 0 1 0];

for roi_ind = 1:size(data.ROI,1)
    quad(1,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)];
    quad(2,:) = [data.ROI(roi_ind,1)+data.ROI(roi_ind,3),data.ROI(roi_ind,2)];
    quad(3,:) = [data.ROI(roi_ind,1)+data.ROI(roi_ind,3),data.ROI(roi_ind,2)+data.ROI(roi_ind,4)];
    quad(4,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)+data.ROI(roi_ind,4)];
    quad(5,:) = [data.ROI(roi_ind,1),data.ROI(roi_ind,2)];
    
    line(quad(:,2),quad(:,1),'parent',im_ax,'color',[1 1 1]);
    
    for n = 1:num_frame
        line(exp_t,I_traces(:,n,roi_ind),...
            'parent',roi_ax,...
            'tag',['fluo_trace_',num2str(n),'_',num2str(roi_ind)],...
            'color',colors(n,:),...
            'displayname',[num2str(n),'_',num2str(roi_ind)])
    end
end

axis(roi_ax,'tight');
ylabel(roi_ax,'F (counts)')
xlabel(roi_ax,'Time (s)')

h = legend(roi_ax,'show','location','best');
set(h,'fontsize',6,'box','off')


function exp_t = makeLineScanTime(i_info,params)
dscr = i_info(1).ImageDescription;
strstart = regexp(dscr,'state.acq.msPerLine=','end');
delta_t = str2double(dscr(strstart+1))/1000;
t = makeInTime(params);
delta_t_ind = find(t==t(1)+delta_t);
exp_t = t(1:delta_t_ind-1:length(t));
exp_t = exp_t(1:i_info(1).Height);