function varargout = Perfusion(varargin)
% PERFUSION MATLAB code for Perfusion.fig
%      PERFUSION, by itself, creates a new PERFUSION or raises the existing
%      singleton*.
%
%      H = PERFUSION returns the handle to a new PERFUSION or the handle to
%      the existing singleton*.
%
%      PERFUSION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PERFUSION.M with the given input arguments.
%
%      PERFUSION('Property','Value',...) creates a new PERFUSION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Perfusion_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Perfusion_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Perfusion

% Last Modified by GUIDE v2.5 17-Jul-2015 15:23:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Perfusion_OpeningFcn, ...
                   'gui_OutputFcn',  @Perfusion_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    a = varargout{1};
    co = getacqpref('ControlOutput');
    if ~isempty(co); 
        set(a,'Units','characters');
        set(a,'position',co.Position);
    end

else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Perfusion is made visible.
function Perfusion_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% popupval = get(handles.popupmenu1,'Value');

doSession = daq.createSession('ni');
doSession.addDigitalChannel('dev3','port1/line4','OutputOnly')
doSession.addDigitalChannel('dev3','port1/line5','OutputOnly')

doSession.outputSingleScan([0 0])

handles.session = doSession;

set(handles.togglebutton1, 'SelectionHighlight', 'off')

set(hObject, 'DeleteFcn', {@ControlOutput_ClosingFcn,hObject})
set(hObject, 'WindowKeyPressFcn', {@ControlOutput_KeyPressFcn,hObject})
%set(hObject, 'Position', [9   326   560   420])

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Perfusion wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Perfusion_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
% popupval = get(hObject,'Value');
% if ~isempty(handles.sessions{popupval})
%     handles.stimval = handles.stimvals(popupval);
%     set(handles.slider1,'Value',handles.stimval);
%     guidata(gcbo,handles);
%     slider1_Callback(handles.slider1, eventdata, handles)
% else        
%     aoSession = daq.createSession('ni');
%     aoSession.Rate = 10000;
%     aoSession.addAnalogOutputChannel('Dev1',popupval-1,'Voltage')
%     handles.stimval = handles.stimvals(popupval);
%     aoSession.queueOutputData(handles.stim(:)*handles.stimval);
%     handles.sessions{popupval} = aoSession;
% 
%     set(handles.slider1,'Value',handles.stimval);
%     guidata(gcbo,handles);
%     slider1_Callback(handles.slider1, eventdata, handles)
% end

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ControlOutput_KeyPressFcn(src,eventdata,hObject)
handles = guidata(hObject);
state = get(handles.togglebutton1,'value');
if ~strcmp(eventdata.Character,'p')
    return
end
switch state
    case 0
        set(handles.togglebutton1,'value',1);
    case 1
        set(handles.togglebutton1,'value',0);
end
guidata(hObject, handles);
togglebutton1_Callback(handles.togglebutton1, eventdata, handles)

function ControlOutput_ClosingFcn(src,eventdata,hObject)
handles = guidata(hObject);
delete(handles.session);


% --- Executes on button press in toggle_button.
function toggle_button_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%handles = guidata(hObject);


% --- Executes on button press in togglebutton1.
function togglebutton1_Callback(hObject, eventdata, handles)

handles = guidata(hObject);
state = get(hObject,'value');
set(hObject, 'SelectionHighlight', 'off')

handles.session.outputSingleScan([state state]);
switch state
    case 0
        set(handles.uipanel1,'backgroundcolor',[0 1 0]);
        set(handles.togglebutton1,'string','ON');
        %set(hObject,'value',1);
    case 1
        set(handles.uipanel1,'backgroundcolor',[1 0 0]);
        set(handles.togglebutton1,'string','OFF');
        %set(hObject,'value',0);
end

guidata(hObject, handles);
