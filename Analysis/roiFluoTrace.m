function varargout = roiFluoTrace(data,params,varargin)
% dFoverF(data,params,montageflag)

p = inputParser;
p.PartialMatching = 0;
p.addParamValue('NewROI','',@ischar);
p.addParamValue('dFoFfig',[],@isnumeric);
p.addParamValue('MotionCorrection',true,@islogical);
p.addParamValue('ShowMovies',false,@islogical);
p.addParamValue('MovieLocation','',@ischar);

parse(p,varargin{:});

varargout = {[]};

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    return
end
if isempty(p.Results.dFoFfig)
    fig = findobj('tag',mfilename);
else
    fig = p.Results.dFoFfig;
    subplot(2,1,1,'parent',fig,'tag',[mfilename 'ax']);
end
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
figure(fig);
ax = findobj(fig,'tag',[mfilename 'ax']);
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

I_F0 = nanmean(I(:,:,1,bsln),4);

%% Do motion correction here

if p.Results.MotionCorrection
    I_uncorrected = I;
    ref_frame = I(:,:,1,1);
    ref_FFT = fft2(ref_frame);
    for frame=2:num_frame
        [~, Greg] = dftregistration(ref_FFT,fft2(I(:,:,1,frame)),1);
        I(:,:,1,frame) = real(ifft2(Greg));
    end
    
    I_F0_uncorrected = I_F0;
    I_F0 = nanmean(I(:,:,1,bsln),4);
        
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

if ~isfield(data,'ROI') || ~strcmp(p.Results.NewROI,'No');
    roifig = figure;
    set(roifig,'position',[1111 459 560 420]);
    imshow(I_F0,[],'initialmagnification','fit');
    title('Draw ROI, close figure when done')
    
    if isfield(data,'ROI')
        line(data.ROI(:,1),data.ROI(:,2));
        button = questdlg('Make new ROI?','ROI','No');
    end
    if strcmp(button,'Yes');
        roihand = imfreehand(get(roifig,'children'),'Closed',1);
        data.ROI = wait(roihand);
        mask = createMask(roihand);
    else
        mask = poly2mask(data.ROI(:,1),data.ROI(:,2),size(im,1),size(im,2));
    end
    close(roifig);
elseif strcmp(p.Results.NewROI,'No')
    mask = poly2mask(data.ROI(:,1),data.ROI(:,2),size(im,1),size(im,2));
end


%%
I_masked = I;
I_masked(~repmat(mask,[1 1 num_frame]))=nan;

I_F0_masked = I_F0;
I_F0_masked(~mask)=nan;

I_trace = nanmean(nanmean(I_masked,1),2);
I_trace = reshape(I_trace,1,numel(I_trace));
dFoverF_trace = 100 * (I_trace/nanmean(nanmean(I_F0_masked)) - 1);

line(exp_t,dFoverF_trace,'parent',ax,'tag','dFoverF_trace','displayname',imdir)
axis(ax,'tight');
ylabel(ax,'% \Delta F / F')
xlabel(ax,'Time (s)')

line(exp_t,I_trace,'parent',absolute_ax,'tag','fluo_trace','displayname',imdir)
axis(absolute_ax,'tight');
ylabel(absolute_ax,'F (counts)')
xlabel(absolute_ax,'Time (s)')
if p.Results.MotionCorrection
    I_masked = I_uncorrected;
    I_masked(~repmat(mask,[1 1 num_frame]))=nan;
        
    I_trace_uncorrected = nanmean(nanmean(I_masked,1),2);
    I_trace_uncorrected = reshape(I_trace_uncorrected,1,numel(I_trace_uncorrected));
    line(exp_t,I_trace_uncorrected,'color',[1 0 0],'parent',absolute_ax,'tag','fluo_trace','displayname',imdir)
end

data.roiFluoTrace = I_trace;

save(regexprep(data.name,'Acquisition','Raw_Data'), '-struct', 'data');

