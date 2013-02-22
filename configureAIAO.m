function [aiSession, aoSession] = configureAIAO(protocol)
% configureAIAO is to start an acquisition routine 

gainSession = daq.createSession('ni');
gainSession.addAnalogInputChannel('Dev1',1, 'Voltage')
modeSession = daq.createSession('ni');
modeSession.addAnalogInputChannel('Dev1',2, 'Voltage')

aiSession = daq.createSession('ni');
aiSession.addAnalogInputChannel('Dev1',0, 'Voltage')

% configure AO
staticDisp = 5; % TODO: I want to be able to use -10 + 10V
% staticDisp = static voltage output to piezo; should usually be set to 5V
% so that the medial and lateral directions can be used equally
% AO = analogoutput ('nidaq', 'Dev1');
aoSession = daq.createSession('ni');
aoSession.addAnalogOutputChannel('Dev1',0:2, 'Voltage')

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger')
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger')


% configure testPiezo AI and AO
if strcmp(protocol,'testPiezo')
    sampratein = 10000; samprateout = 10000;
    aiSession.Rate = sampratein;
    aoSession.Rate = samprateout;
    
% configure testAMfreq AI and AO
elseif strcmp(protocol,'testFmAndCS') || strcmp(protocol,'testFc')
    sampratein = 10000; samprateout = 40000;
    aiSession.Rate = sampratein;
    aoSession.Rate = samprateout;
    
end

% configure AI
function s = configureAI(sampratein)
% Return the DAQ session object

% AI = analoginput ('ni', 'Dev1');
% addchannel (AI, 0:2);  % initialize channels A0,A1,A2 (10Vm_out, I_out, and scaled output, respectively)
% set(AI, 'SampleRate', sampratein);
% set(AI, 'SamplesPerTrigger', inf);
% set(AI, 'InputType', 'Differential');
% set(AI, 'TriggerType', 'Manual');
% set(AI, 'ManualTriggerHwOn','Trigger');



% TODO:
% Run the session and read the mode channel to decide what the analog input
% 1 is reading.  Note, this is likely to be unessecary, the output of the
% amp is always in voltage
%
% Could do a startBackground
%
% Could trigger off interesting things, I think.  Or at least I could use
% align recording with acquisition 
% 
%
% configure testCurrentInj AI and AO    
% elseif strcmp(protocol,'testCurrentInj')
%     sampratein = 10000; samprateout = 10000;
%     
%     % configure AI
%     AI = configureAI(sampratein);
%     
%     % configure one AO channel (for both Ihpulse and current injection)
%     AO = analogoutput ('nidaq', 'Dev3');
%     addchannel (AO, 1);
%     set(AO, 'SampleRate', samprateout);
%     set(AO, 'TriggerType', 'Manual');
%     
% %% configure testWind AI and AO
% elseif strcmp(protocol,'testwind')
%     sampratein = 10000; samprateout = 1000;
%     
%     % configure AI
%     AI = configureAI(sampratein);
%     
%     % configure analog output
%     AO = analogoutput ('nidaq', 'Dev3');
%     addchannel (AO, 1);
%     set(AO, 'SampleRate', samprateout);
%     set(AO, 'TriggerType', 'Manual');
