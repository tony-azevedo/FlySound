function toggleCameraPref(varargin)
% Turn the Camera preference on or off
campref = getpref('AcquisitionHardware','cameraToggle');
if nargin
    campref = varargin{1};
    switch campref
    case 'on'
        campref = 'off';
    case 'off'
        campref = 'on';
    end
end
switch campref
    case 'on'
        setpref('AcquisitionHardware','cameraToggle','off')
        systemsound('Windows Hardware Remove')
        fprintf('Camera Disconnected\n')
    case 'off'
        setpref('AcquisitionHardware','cameraToggle','on')
        systemsound('Windows Hardware Insert')
        fprintf('Camera Connected\n')
end