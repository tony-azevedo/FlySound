function display_cam1_frame(obj,event,varargin)
persistent ax
persistent indices
persistent im

if ~isempty(event)
    frame = peekdata(obj,1);
elseif nargin>2
    frame = varargin{1};
else 
    error('No frame provided and video object not started')
end
    
if isempty(ax) && nargin>3
    ax = varargin{2};
elseif isempty(ax)
    displayf = findobj('type','figure','tag','cam1_snapshotfigure');
    ax = findobj(displayf,'type','axes','tag',['cam' num2str(obj.camPortID) '_snapshotax']);
end

if isempty(indices)
    indices = frame;
    indices(:) = 0;
    Cmap = 4:4:size(indices,1);
    Rmap = 4:4:size(indices,2);
    indices(Cmap,Rmap) = 1;
    indices = logical(indices);
end

if (isempty(im) || ~isvalid(im)) && nargin>4
    im = varargin{3};
elseif (isempty(im) || ~isvalid(im))
    shrunk = nan(length(Cmap),length(Rmap));
    shrunk(:) = frame(indices);
    im = imshow(shrunk,'parent',ax);
    drawnow; % force an update of the figure window
end

im.CData(:) = frame(indices);
drawnow; % force an update of the figure window

