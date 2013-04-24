function offset = scaledVoltageOffset(varargin)
if nargin<1;
    gain = readGain();
else
    gain = varargin{1};
end

switch gain
    case 0.5
        offset = -0.0113764;
    case 1
        offset = -0.0064541;
    case 2
        offset = -0.0039713;
    case 5
        offset = -0.0022362;  
    case 10
        offset = -0.0017351; 
    case 20
        offset = -0.0014971; 
    case 50
        offset = -0.0013205;
    case 100
        offset = -0.0012701;
    case 200
        offset = -0.0012438; 
    case 500
        offset = -0.001224;
end        

    
    