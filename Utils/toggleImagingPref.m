function toggleImagingPref(varargin)
% Turn the imaging preference on or off
campref = getpref('AcquisitionHardware','imagingToggle');
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
        setpref('AcquisitionHardware','imagingToggle','off')
        systemsound('Windows Hardware Remove')
        fprintf('Two Photon Imaging System Disconnected\n')
    case 'off'
        setpref('AcquisitionHardware','imagingToggle','on')
        setpref('AcquisitionHardware','twoPToggle','off')
        systemsound('Windows Hardware Insert')
        fprintf('Two Photon Imaging System Connected\n')
end