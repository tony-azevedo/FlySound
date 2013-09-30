function varargout = ModeGUI(varargin)
% Last Modified by GUIDE v2.5 29-Aug-2013 19:34:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ModeGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ModeGUI_OutputFcn, ...
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

function ModeGUI_OpeningFcn(hObject, eventdata, handles, varargin)
if nargin > 3 && ~isempty(varargin{1})
    switch varargin{1}
    case 'IClamp'
        set(handles.mode,'SelectedObject',handles.bridge);
        handles.output = 'bridge';
    case 'VClamp'
        set(handles.mode,'SelectedObject',handles.sevc);
        handles.output = 'sevc';
    end
else
    handles.output = 'sevc';
end
handles.modeStr = get(get(handles.mode,'selectedObject'),'tag');

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);
uiwait(handles.figure1);

function varargout = ModeGUI_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
close(handles.figure1);

function enter_Callback(hObject, eventdata, handles)
switch handles.modeStr
    case 'bridge'
        handles.output = 'IClamp';
    case 'sevc'
        handles.output = 'VClamp';
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
set(handles.figure1,'KeyPressFcn',@enter_key_callback);
guidata(handles.figure1, handles);

function enter_key_callback(hObject,key)
if strcmp(key.Key,'return')
    enter_Callback(hObject, [], guidata(hObject));
end
