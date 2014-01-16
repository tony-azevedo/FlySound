function varargout = dFoverF(data,params,varargin)
% dFoverF(data,params,montageflag)

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    return
end
fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[1030 181 560 275],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end
if nargin>2
    button = 'No';
end

% dummyax = findobj('tag',[mfilename 'dummyax']);
% if isempty(dummyax)
%     dummyax = axes('Position',get(ax,'Position'),...
%         'tag',[mfilename 'dummyax'],...
%         'parent',fig,...
%         'XAxisLocation','top',...
%         'Color','none',...
%         'Ytick',[],...
%         'XColor','k','YColor','k');
% else
%     delete(get(dummyax,'children'));
% end


imdir = regexprep(regexprep(regexprep(data.name,'Raw','Images'),'.mat',''),'Acquisition','Raw_Data');

t = makeInTime(params);
exp_t = t(data.exposure);

if exist('button','var') && isfield(data,'dFoverF')
    line(exp_t,data.dFoverF,'parent',ax,'tag','dFoverF_trace','displayname',imdir)
    axis(ax,'tight');
    ylabel(ax,'% \Delta F / F')
    xlabel(ax,'Time (s)')
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

%% calculates a baseline image from frame bl_start through bl_end 
if sum(exp_t<0)
    bsln = exp_t<0 & exp_t>exp_t(1)+.02;
else
    bsln = exp_t<1 & exp_t>exp_t(1)+.02;
end
bl_numframes = nansum(bsln);
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

line(exp_t(1:length(I_trace)),dFoverF_trace,'parent',ax,'tag','dFoverF_trace')
axis(ax,'tight');
%axis(ax,[exp_t(1) exp_t(length(I_trace)) get(ax,'ylim')])
% line((1:length(I_trace)),dFoverF_trace,'parent',dummyax,'linestyle','none')
% axis(dummyax, [1 length(I_trace) get(ax,'ylim')]);
ylabel('% \Delta F / F')
xlabel('Time (s)')

data.dFoverF = dFoverF_trace;

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');

%calculate change in fluorescence frame by frame relative to baseline
% I_dFovF = I;
% for frame=1:num_frame
%     I_dFovF(:,:,1,frame) = (I(:,:,1,frame) ./ I_F0)-1;
%     I_dFovF(I_dFovF(:,:,1,frame) >= 500,1,frame) = 0;
% end

%apply Gaussian filter:
%rotationally symmetric Gaussian lowpass filter of size 5x5 with standard deviation
%sigma 2 (positive). 
% G = fspecial('gaussian',[3 3],2);
% I_dFovF_thr_filt = imfilter(I_dFovF,G);
%I_dFovFmov = imfilter(I,G);

% if montageflag
%     %plot montage of dFoverF images
%     c = [min(min(min(min(I_dFovF)))) max(max(max(max(I_dFovF))))];
%     
%     Idim = size(I);
%     Checkers = ones([Idim(1:3), Idim(4)*2])*c(1);
%     Checkers(:,:,1,2:2:end) = I_dFovF_thr_filt;
%     
%     figure
%     dim1 = floor(sqrt(Idim(4)*2));
%     if ~mod(dim1,2)
%         dim1 = dim1-1;
%     end
%     montage(Checkers,'Size',[NaN dim1])
%     colormap(hot)
%     caxis(c)
%     % t=[num2str(filebase)];
%     % title(t)
%     
% %     figure
% %     mov = immovie(I,hot);
% %     implay(mov);
% end

varargout = {I};
