function varargout = PGRPatchCamera(varargin)
% PGRPATCHCAMERA MATLAB code for PGRPatchCamera.fig
%      PGRPATCHCAMERA, by itself, creates a new PGRPATCHCAMERA or raises the existing
%      singleton*.
%
%      H = PGRPATCHCAMERA returns the handle to a new PGRPATCHCAMERA or the handle to
%      the existing singleton*.
%
%      PGRPATCHCAMERA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PGRPATCHCAMERA.M with the given input arguments.
%
%      PGRPATCHCAMERA('Property','Value',...) creates a new PGRPATCHCAMERA or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PGRPatchCamera_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PGRPatchCamera_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PGRPatchCamera

% Last Modified by GUIDE v2.5 04-Nov-2016 15:34:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PGRPatchCamera_OpeningFcn, ...
                   'gui_OutputFcn',  @PGRPatchCamera_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before PGRPatchCamera is made visible.
function PGRPatchCamera_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PGRPatchCamera (see VARARGIN)

% Choose default command line output for PGRPatchCamera
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes PGRPatchCamera wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PGRPatchCamera_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function max_field_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_field (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_field_Callback(hObject, eventdata, h)
h = guidata(hObject);
wasrunning = 0;
if strcmp(h.videoInput.Running,'on')
    wasrunning = 1;
    h.videoInput.stop;
end

h.max_field.Value = str2double(h.max_field.String);
if isnan(h.max_field.Value)
    h.max_field.Value = str2double(h.max_text.String);
end
scale = [h.min_field.Value h.max_field.Value];

h.videoInput.TimerFcn = {@imaqplot,h.hImage,scale};
h.videoInput.TimerPeriod = 0.05;
h.videoInput.FramesPerTrigger = Inf;

set(h.iax,'clim',scale);

h.videoInput.TimerFcn = {@imaqplot,h.hImage,scale};
h.videoInput.TimerPeriod = 0.05;
h.videoInput.FramesPerTrigger = Inf;

guidata(h.figure1, h);

if wasrunning
    h.videoInput.start;
end
    
guidata(hObject,h)

function min_field_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function min_field_Callback(hObject, eventdata, handles)
h = guidata(hObject);
h.min_field.Value = str2double(h.min_field.String);
if isnan(h.min_field.Value)
    h.min_field.Value = str2double(h.min_text.String);
end
guidata(hObject,h)
max_field_Callback(hObject, eventdata, h)

% --- Executes on button press in start_button.
function start_button_Callback(hObject, eventdata, handles)
if hObject.Value
    set(hObject,'String','Stop');
    start(handles.videoInput);
else
    set(hObject,'String','Start');
    stop(handles.videoInput);
end

% --- Executes on button press in close_button.
function close_button_Callback(hObject, eventdata, handles)

%initialize_gui(gcbf, handles, true);

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the close_button flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to close_button the data.

imqhwnfo = imaqhwinfo('pointgrey');
for i = 1:length(imqhwnfo.DeviceInfo)
    if strcmp(imqhwnfo.DeviceInfo(i).DeviceName,'Chameleon3 CM3-U3-13Y3M')
        break
    end
end
handles.videoInput = videoinput('pointgrey', i, 'F7_Raw8_1280x1024_Mode0');
% preview(handles.videoInput)
% stoppreview(handles.videoInput)

handles.source = getselectedsource(handles.videoInput);
frame = getsnapshot(handles.videoInput);

handles.iw = figure;
set(handles.iw,'units','normalized','position',[0.0 0.0287 0.8766 0.9426],...
    'MenuBar','none',...
    'NumberTitle','off')
handles.iax = axes('parent',handles.iw,'units','pixels','position',[196 1 1280 1024]);
colormap(handles.iax,'gray');

handles.hImage = imagesc(frame,'parent',handles.iax);
set(handles.iax,'box','off','tickdir','out','xcolor',[0.9400    0.9400    0.9400],'ycolor',[0.9400    0.9400    0.9400]);

handles.max_text.String = num2str(max(frame(:)));
handles.min_text.String = num2str(min(frame(:)));
handles.max_field.Value = max(frame(:));
handles.min_field.Value = min(frame(:));
handles.max_field.String = num2str(max(frame(:)));
handles.min_field.String = num2str(min(frame(:)));
scale = [handles.min_field.Value handles.max_field.Value];

handles.videoInput.TimerFcn = {@imaqplot,handles.hImage,scale};
handles.videoInput.TimerPeriod = 0.05;
handles.videoInput.FramesPerTrigger = Inf;


guidata(handles.figure1, handles);


% --- Executes on button press in refresh_button.
function refresh_button_Callback(hObject, eventdata, handles)
h = guidata(hObject);
wasrunning = 0;
if strcmp(h.videoInput.Running,'on')
    wasrunning = 1;
    h.videoInput.stop;
end
frame = getsnapshot(h.videoInput);
h.max_text.String = num2str(max(frame(:)));
h.min_text.String = num2str(min(frame(:)));
h.max_field.Value = max(frame(:));
h.min_field.Value = min(frame(:));
h.max_field.String = num2str(max(frame(:)));
h.min_field.String = num2str(min(frame(:)));

guidata(h.figure1, h);
max_field_Callback(h.max_field,eventdata,handles);


function imaqplot(vid,event,himage,scale)

try    
    % Get the latest data to plot.
    set(himage, 'CData', getsnapshot(vid));
    
    % Adjust the axis limits in case the image resolution changed.
%     res = get(vid, 'ROIPosition');
%     ax = get(himage, 'Parent');
%     set(ax, 'XLim', [0.5 res(3)+0.5], 'YLim', [0.5 res(4)+0.5], ...
%         'XTick', [], 'XTickLabel', [], 'YTick', [], 'YTickLabel', []);
    set(get(himage,'parent'),'clim',scale,'box','off','tickdir','out','xcolor',[0.9400    0.9400    0.9400],'ycolor',[0.9400    0.9400    0.9400]);
    
catch
    % Error gracefully.
    error('MATLAB:imaqplot:error', ...
        sprintf('IMAQPLOT is unable to plot correctly.\n%s', lasterr))
end


function figure1_DeleteFcn(hObject, eventdata, handles)
h = guidata(hObject);
delete(h.videoInput)
delete(h.iw)
