function varargout = GainGUI(varargin)
% GAINGUI MATLAB code for GainGUI.fig
%      GAINGUI, by itself, creates a new GAINGUI or raises the existing
%      singleton*.
%
%      H = GAINGUI returns the handle to a new GAINGUI or the handle to
%      the existing singleton*.
%
%      GAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GAINGUI.M with the given input arguments.
%
%      GAINGUI('Property','Value',...) creates a new GAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GainGUI

% Last Modified by GUIDE v2.5 24-Sep-2013 08:17:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GainGUI_OutputFcn, ...
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


% --- Executes just before GainGUI is made visible.
function GainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
ch = get(handles.gainpanel,'children');
gainstrs = cell(size(ch));
for gs = 1:length(ch)
    gainstrs{gs} = get(ch(gs),'string');
end
if nargin > 3 && ~isempty(varargin{1})
    gainstr = num2str(varargin{1});
    set(handles.gainpanel,'SelectedObject',ch(strcmp(gainstrs,gainstr)));
else
    set(handles.gainpanel,'SelectedObject',ch(strcmp(gainstrs,'1')));
end
if nargin > 4 && ~isempty(varargin{2})
    set(handles.gainpanel,'title',varargin{2})
end
handles.gainStr = get(get(handles.gainpanel,'selectedObject'),'string');
handles.output = str2double(handles.gainStr);
% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GainGUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
close(handles.figure1);


% --- Executes on button press in enter.
function enter_Callback(hObject, eventdata, handles)
handles.output = str2double(handles.gainStr);
guidata(hObject, handles);
uiresume;


% --- Executes when selected object is changed in gainpanel.
function gainpanel_SelectionChangeFcn(hObject, eventdata, handles)
handles.gainStr = get(hObject,'string');
guidata(handles.figure1, handles);


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
