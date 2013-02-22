function varargout = ControlOutput(varargin)
% CONTROLOUTPUT MATLAB code for ControlOutput.fig
%      CONTROLOUTPUT, by itself, creates a new CONTROLOUTPUT or raises the existing
%      singleton*.
%
%      H = CONTROLOUTPUT returns the handle to a new CONTROLOUTPUT or the handle to
%      the existing singleton*.
%
%      CONTROLOUTPUT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTROLOUTPUT.M with the given input arguments.
%
%      CONTROLOUTPUT('Property','Value',...) creates a new CONTROLOUTPUT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ControlOutput_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ControlOutput_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ControlOutput

% Last Modified by GUIDE v2.5 06-Feb-2013 14:47:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ControlOutput_OpeningFcn, ...
                   'gui_OutputFcn',  @ControlOutput_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    a = varargout{1};
    co = getpref('ControlOutput');
    if ~isempty(co); 
        set(a,'Units','characters');
        set(a,'position',co.Position);
    end

else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ControlOutput is made visible.
function ControlOutput_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ControlOutput (see VARARGIN)

% Choose default command line output for ControlOutput
handles.output = hObject;

popupval = get(handles.popupmenu1,'Value');

aoSession = daq.createSession('ni');
aoSession.Rate = 10000;
handles.stim = ones(aoSession.Rate*0.001,1);
aoSession.addAnalogOutputChannel('Dev1',popupval-1,'Voltage')
aoSession.queueOutputData(handles.stim(:)*get(handles.slider1,'Value'));  
aoSession.startBackground
handles.sessions{popupval} = aoSession;
handles.stimvals = zeros(1,length(get(handles.popupmenu1,'String')));
handles.stimvals(popupval) = get(handles.slider1,'Value');
handles.stimval = handles.stimvals(popupval);
set(handles.edit1,'string',num2str(handles.stimval));

set(hObject, 'DeleteFcn', {@ControlOutput_ClosingFcn,hObject})
set(hObject, 'WindowScrollWheelFcn', {@ControlOutput_CtrWheelFcn,hObject})
set(hObject, 'WindowKeyPressFcn', {@ControlOutput_KeyPressFcn,hObject})
set(hObject, 'Position', [0  75 71.6000 6.2308])

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ControlOutput wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ControlOutput_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
popupval = get(handles.popupmenu1,'Value');
handles.stimvals(popupval) = get(handles.slider1,'Value');
handles.stimval = handles.stimvals(popupval);

aoSession = handles.sessions{popupval};
try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
catch ME
    try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
    catch ME
        try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
        catch ME
            try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
            catch ME
                try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                catch ME
                    try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                    catch ME
                        try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                        catch ME
                            try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                            catch ME
                                try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                                catch ME
                                    try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                                    catch ME
                                        try aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                                        catch ME
                                            aoSession.queueOutputData(handles.stim(:)*handles.stimval);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

aoSession.startBackground
handles.sessions{popupval} = aoSession;

set(handles.edit1,'String',num2str(handles.stimval));
guidata(gcbo,handles);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
popupval = get(hObject,'Value');
if ~isempty(handles.sessions{popupval})
    handles.stimval = handles.stimvals(popupval);
    set(handles.slider1,'Value',handles.stimval);
    guidata(gcbo,handles);
    slider1_Callback(handles.slider1, eventdata, handles)
else        
    aoSession = daq.createSession('ni');
    aoSession.Rate = 10000;
    aoSession.addAnalogOutputChannel('Dev1',popupval-1,'Voltage')
    handles.stimval = handles.stimvals(popupval);
    aoSession.queueOutputData(handles.stim(:)*handles.stimval);
    handles.sessions{popupval} = aoSession;

    set(handles.slider1,'Value',handles.stimval);
    guidata(gcbo,handles);
    slider1_Callback(handles.slider1, eventdata, handles)
end


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



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
val = str2double(get(hObject,'String'));
set(handles.slider1,'Value',val);
guidata(hObject, handles);
slider1_Callback(handles.slider1, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ControlOutput_CtrWheelFcn(src,eventdata,hObject)
handles = guidata(hObject);
stimval = get(handles.slider1,'Value');
step = get(handles.slider1,'SliderStep');
top = get(handles.slider1,'Max'); bottom = get(handles.slider1,'Min');

stimval = stimval + ...
    0.01 * (top-bottom) * ...
    eventdata.VerticalScrollAmount * -eventdata.VerticalScrollCount;
if stimval > top;
    beep
    stimval = top;
end
if stimval < 0;
    beep;
    stimval = 0;
end

set(handles.slider1,'Value',stimval);
guidata(hObject, handles);
slider1_Callback(handles.slider1, eventdata, handles)


function ControlOutput_KeyPressFcn(src,eventdata,hObject)
handles = guidata(hObject);
if strcmp(eventdata.Character,' ')
end

function ControlOutput_ClosingFcn(src,eventdata,hObject)
handles = guidata(hObject);
for session = handles.sessions
    if ~isempty(session{1})
        session{1}.stop
        delete(session{1});
    end
end
