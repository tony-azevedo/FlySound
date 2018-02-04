function varargout = dFoverF(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','',@ischar);
p.addParameter('dFoFfig',[],@isnumeric);
parse(p,varargin{:});

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    varargout = {[]};
    return
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
            'Position',[1030 181 560 275],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
figure(fig); 
ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(2,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    cla(ax,'reset');
end
absolute_ax = subplot(2,1,2,'parent',fig,'tag',[mfilename 'absolute_ax']);
cla(absolute_ax,'reset');

button = p.Results.NewROI;

imdir = regexprep(regexprep(regexprep(data.name,'Raw','Images'),'.mat',''),'Acquisition','Raw_Data');

exp_t = data.exposure_time;

if sum(exp_t<0)
    bsln = exp_t<0 & exp_t>exp_t(1)+.02;
else
    bsln = exp_t<1 & exp_t>exp_t(1)+.02;
end
bl_numframes = nansum(bsln);

if strcmp(button,'No') && isfield(data,'dFoverF')
    line(exp_t,data.dFoverF,'parent',ax,'tag','dFoverF_trace','displayname',imdir)
    axis(ax,'tight');
    ylabel(ax,'% \Delta F / F')
    xlabel(ax,'Time (s)')
    varargout = {[]};
    return
end

%%  Currently, I'm saving images as single files.  Sucks!
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

image_sum = nansum(I(:,:,1,bsln),4);
I_F0 = imdivide(image_sum, bl_numframes);

%% select ROI (implement at some point)
roifig = figure;
imshow(I_F0,[],'initialmagnification','fit');
title('Draw ROI, close figure when done')

button = 'Yes';
if isfield(data,'ROI')
    line(data.ROI(:,1),data.ROI(:,2));
    button = questdlg('Make new ROI?','ROI','No');
end
if strcmp(button,'Yes');
    roihand = imfreehand(get(roifig,'children'),'Closed',1);
    % if isfield(data,'ROI')
    %     roihand.setPosition(data.ROI)
    % end
    data.ROI = wait(roihand);
    mask = createMask(roihand);
else
    mask = poly2mask(data.ROI(:,1),data.ROI(:,2),size(im,1),size(im,2));
end
close(roifig);


%%
I_masked = I;
I_masked(~repmat(mask,[1 1 num_frame]))=nan;
I_F0_masked = I_F0;
I_F0_masked(~mask)=nan;


I_trace = nanmean(nanmean(I_masked,1),2);
I_trace = reshape(I_trace,1,numel(I_trace));
dFoverF_trace = 100 * (I_trace/nanmean(nanmean(I_F0_masked)) - 1);

line(data.exposure_time,dFoverF_trace,'parent',ax,'tag','dFoverF_trace')
axis(ax,'tight');

ylabel('% \Delta F / F')
xlabel('Time (s)')

data.dFoverF = dFoverF_trace;

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');

varargout = {I};
