function toggleTwoPPref(varargin)
% Turn the Camera preference on or off
campref = getacqpref('AcquisitionHardware','twoPToggle');
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
        setacqpref('AcquisitionHardware','twoPToggle','off')
        systemsound('Windows Hardware Remove')
        fprintf('Two Photon System Disconnected\n')
    case 'off'
        setacqpref('AcquisitionHardware','twoPToggle','on')
        systemsound('Windows Hardware Insert')
        fprintf('Two Photon System Connected\n')
end