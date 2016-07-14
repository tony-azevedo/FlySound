function varargout = roiFluoTrace(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParameter('NewROI','Yes',@ischar);
p.addParameter('dFoFfig',[],@ishandle);
p.addParameter('MotionCorrection',true,@islogical);
p.addParameter('ShowMovies',false,@islogical);
p.addParameter('MovieLocation','',@ischar);
p.addParameter('BGCorrectImages',true,@islogical);

parse(p,varargin{:});

varargout = {[]};

if ~isfield(data,'exposure') || sum(data.exposure) == 0
    error('No Camera Input: Exiting roiFluoTrace routine');
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

imdir = regexprep(regexprep(regexprep(data.name,'_Raw_','_Images_'),'.mat',''),'Acquisition','Raw_Data');

exp_t = data.exposure_time;

if sum(exp_t<0)
    bsln = exp_t<0 & exp_t>exp_t(1)+.02;
else
    bsln = exp_t<1 & exp_t>exp_t(1)+.02;
end

if strcmp(button,'No') && isfield(data,'roiFluoTrace') && ~p.Results.MotionCorrection
    dFoverF_trace = 100 * (data.roiFluoTrace/nanmean(data.roiFluoTrace(bsln)) - 1);
    line(exp_t,dFoverF_trace,'parent',ax,'tag','dFoverF_trace','displayname',imdir)
    axis(ax,'tight');
    ylabel(ax,'% \Delta F / F')
    xlabel(ax,'Time (s)')
    
    line(exp_t,data.roiFluoTrace,'parent',absolute_ax,'tag','fluo_trace','displayname',imdir)
    axis(absolute_ax,'tight');
    ylabel(absolute_ax,'F (counts)')
    xlabel(absolute_ax,'Time (s)')
    return
end

%%  Load the frames from the Image directory
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

%% Do motion correction here

I_uncorrected = I;
if p.Results.MotionCorrection
    I_uncorrected = I;
    ref_frame = I(:,:,1,1);
    ref_FFT = fft2(ref_frame);
    for frame=2:num_frame
        [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,1,frame)),1);
        I(:,:,1,frame) = real(ifft2(Greg));
    end
            
    if ~isempty(p.Results.MovieLocation)
        [protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);

        vidObj = VideoWriter([p.Results.MovieLocation '\' protocol '_' dateID '_' flynum '_' cellnum '_' trialnum],'MPEG-4');
        set(vidObj,'FrameRate',round(1/diff(exp_t([1 2]))))
        
        I_uncorrected = squeeze(I_uncorrected);
        I = squeeze(I);

        I_uncorrected_norm = ...
            (I_uncorrected - min(min(min(I_uncorrected))))/...
            (max(max(max(I_uncorrected))) - min(min(min(I_uncorrected))));
        I_norm = ...
            (I - min(min(min(I))))/...
            (max(max(max(I))) - min(min(min(I))));
        
        open(vidObj);
        
        % Create an animation.
        % set(gca,'nextplot','replacechildren');
        for frame=1:num_frame
            % Write each frame to the file.
            writeVideo(vidObj,I_norm(:,:,frame));
        end
        close(vidObj);
      
        varargout = {fullfile(get(vidObj,'Path'), get(vidObj,'Filename'))};
    end
end

I_uncorrected = squeeze(I_uncorrected);
I = squeeze(I);

%% select ROI 

I_F0 = nanmean(I(:,:,bsln),3);
if ~isfield(data,'ROI') || ~isfield(data,'bgROI') || ~strcmp(p.Results.NewROI,'No');
    roifig = figure;
    set(roifig,'position',[1111 459 560 420]);
    imshow(I_F0,[],'initialmagnification','fit');
    title('Draw ROI, close figure when done')
    roidrawax = get(roifig,'children');
    
    if isfield(data,'ROI')
        line(data.ROI(:,1),data.ROI(:,2));
        button = questdlg('Make new ROI?','ROI','No');
    end
    if strcmp(button,'Yes');
        roihand = imfreehand(roidrawax,'Closed',1);
        data.ROI = wait(roihand);
        mask = createMask(roihand);
    else
        mask = poly2mask(data.ROI(:,1),data.ROI(:,2),size(im,1),size(im,2));
    end
    
    
    if isfield(data,'bgROI')
        line(data.bgROI(:,1),data.bgROI(:,2),'color','g');
        button = questdlg('Make new Background ROI?','ROI','No');
    else
        button = 'Yes';
    end
    if strcmp(button,'Yes');
        title('Draw Background ROI, close figure when done')
        bgroihand = imfreehand(roidrawax,'Closed',1);
        data.bgROI = wait(bgroihand);
        bg_mask = createMask(bgroihand);
    else
        bg_mask = poly2mask(data.bgROI(:,1),data.bgROI(:,2),size(im,1),size(im,2));
    end

    close(roifig);
elseif strcmp(p.Results.NewROI,'No')
    mask = poly2mask(data.ROI(:,1),data.ROI(:,2),size(im,1),size(im,2));
    bg_mask = poly2mask(data.bgROI(:,1),data.bgROI(:,2),size(im,1),size(im,2));
end

%% from the roi, make an anular mask for background calculation

X = data.ROI(:,1);
Y = data.ROI(:,2);
[geom] = polygeom(X,Y);

A = geom(1);
x0 = geom(2);
y0 = geom(3);

r = max(sqrt((X-x0).^2 + (Y-y0).^2));
a = 1.2; % inner radius is increased by a certain amount;

theta=[0:.01:2*pi]';
bckgrnd_ri = [x0 + a*r*cos(theta), y0 + a*r*sin(theta)];
bckgrnd_ro = [x0 + sqrt(1+a^2)*r*cos(theta), y0 + sqrt(1+a^2)*r*sin(theta)];

bckgrnd_mask_i = poly2mask(bckgrnd_ri(:,1),bckgrnd_ri(:,2),size(im,1),size(im,2));
bckgrnd_mask_o = poly2mask(bckgrnd_ro(:,1),bckgrnd_ro(:,2),size(im,1),size(im,2));
bckgrnd_mask = bckgrnd_mask_o - bckgrnd_mask_i;

if sum(bckgrnd_mask_i(:,1)) + ...
        sum(bckgrnd_mask_i(1,:)) + ...
        sum(bckgrnd_mask_i(:,end)) + ...
        sum(bckgrnd_mask_i(end,:)) > 1
    bckgrnd_mask = ~bckgrnd_mask_i;
end
    
% quickcheck
sum(bckgrnd_mask(:));
A;
%% Assumptions: 
% # baseline F is composed of F0 from cell and F0_bg, from the background. 
% # F0_bg is uniform and a proxy for the contribution of other cells;

I_masked = I;
I_masked(~repmat(mask,[1 1 num_frame]))=nan;
I_trace = nanmean(nanmean(I_masked,1),2);
I_trace = reshape(I_trace,1,numel(I_trace));

if size(im,1) > 120
    I_bg_masked = I;
else
    I_bg_masked = I_uncorrected;
end
I_bg_masked(~repmat(bckgrnd_mask,[1 1 num_frame]))=nan;
I_bg_trace = nanmean(nanmean(I_bg_masked,1),2);
I_bg_trace = reshape(I_bg_trace,1,numel(I_bg_trace));

numerator = I_trace - I_bg_trace; 
%denominator = (nanmean(I_F0_masked(:)) - nanmean(I_F0_bg_masked(:))); % F0
denominator = mean(numerator(bsln)); % F0

use_hand_bg_mask = 0;
if denominator < 100 
    % do this if the background is anywhere close to the actual
    % fluorescence
    I_bg_masked = I_uncorrected;
    I_bg_masked(~repmat(bg_mask,[1 1 num_frame]))=nan;
    I_bg_trace = nanmean(nanmean(I_bg_masked,1),2);
    I_bg_trace = reshape(I_bg_trace,1,numel(I_bg_trace));
    numerator = I_trace - I_bg_trace;
    denominator = mean(numerator(bsln)); % F0
    use_hand_bg_mask = 1;
end

dFoverF_trace = 100 * (... % percent
    numerator/denominator - 1);

%% Save the trace to the trial
data.backGroundTrace = I_bg_trace;
data.roiFluoTrace = I_trace;
data.dFoverF = dFoverF_trace;

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
imshow(I_F0,[0 max(I_F0(:))],'initialmagnification','fit','parent',roi_ax);

line(data.ROI(:,1),data.ROI(:,2),'parent',roi_ax);
if ~use_hand_bg_mask
    line(bckgrnd_ri(:,1),bckgrnd_ri(:,2),'color','g','parent',roi_ax);
    line(bckgrnd_ro(:,1),bckgrnd_ro(:,2),'color','g','parent',roi_ax);
else
    line(data.bgROI(:,1),data.bgROI(:,2),'color','g','parent',roi_ax);
end

% Fluorescence (uncorrected, corrected, background)
if p.Results.MotionCorrection
    I_masked = I_uncorrected;
    I_masked(~repmat(mask,[1 1 num_frame]))=nan;
        
    I_trace_uncorrected = nanmean(nanmean(I_masked,1),2);
    I_trace_uncorrected = reshape(I_trace_uncorrected,1,numel(I_trace_uncorrected));
    line(exp_t,I_trace_uncorrected,'color',[.8 .8 1],'parent',absolute_ax,'tag','motion','displayname','w/ motion')
end
line(exp_t,I_trace,'parent',absolute_ax,'tag','fluo_trace','displayname','F')
line(exp_t,I_bg_trace,'parent',absolute_ax,'tag','background_trace','displayname','bckgnd','color','g')
line(exp_t,numerator,'parent',absolute_ax,'tag','fluo_trace','displayname','F-bckgnd','color','r')

axis(absolute_ax,'tight');
ylabel(absolute_ax,'F (counts)')
xlabel(absolute_ax,'Time (s)')

h = legend(absolute_ax,'show','location','best');
set(h,'fontsize',6,'box','off')

% %\DeltaF/F
if p.Results.BGCorrectImages
    dFoverF_fulltrace = dFoverF_bgcorr_trace(data);
else
    dFoverF_fulltrace = dFoverF_withbg_trace(data);
end

l = line(exp_t,dFoverF_fulltrace,'parent',ax,'color','k');
set(l,'tag','dFoverF_trace','displayname',imdir)
axis(ax,'tight');
ylabel(ax,'% \Delta F / F')
xlabel(ax,'Time (s)')
try textbp(sprintf('\\DeltaT_F = %.3f s\tBG corrected: %d',diff(exp_t(1:2)),p.Results.BGCorrectImages));
catch e
end


