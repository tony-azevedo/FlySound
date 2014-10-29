function toggleTwoPPref(varargin)
% Turn the Camera preference on or off
campref = getpref('AcquisitionHardware','twoPToggle');
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
        setpref('AcquisitionHardware','twoPToggle','off')
        systemsound('Windows Hardware Remove')
        fprintf('Two Photon System Disconnected\n')
    case 'off'
        setpref('AcquisitionHardware','twoPToggle','on')
        setpref('AcquisitionHardware','imagingToggle','off')
        systemsound('Windows Hardware Insert')
        fprintf('Two Photon System Connected\n')
end