function varargout = RadioDialog(varargin)
% Last Modified by GUIDE v2.5 29-Aug-2013 19:01:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RadioDialog_OpeningFcn, ...
                   'gui_OutputFcn',  @RadioDialog_OutputFcn, ...
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

function RadioDialog_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);
uiwait(handles.figure1);

function varargout = RadioDialog_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
close(handles.figure1);

function enter_Callback(hObject, eventdata, handles)
switch handles.modeStr
    case 'bridge'
        handles.output = 'IClamp';
    case 'sevc'
        handles.output = 'IClamp';
end
guidata(hObject, handles);
uiresume;

function mode_SelectionChangeFcn(hObject, eventdata, handles)
handles.modeStr = get(hObject,'tag');
guidata(handles.figure1, handles);

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
if isfield(handles, 'metricdata') && ~isreset
    return;
end

handles.modeStr = get(get(handles.mode,'selectedObject'),'tag');
guidata(handles.figure1, handles);
