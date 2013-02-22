function [aiSession, aoSession] = createAIAOSessions(protocol)
% configureAIAO is to start an acquisition routine 

aiSession = daq.createSession('ni');
aiSession.addAnalogInputChannel('Dev1',0, 'Voltage')

% configure AO
staticDisp = 5; % TODO: I want to be able to use -10 + 10V
% staticDisp = static voltage output to piezo; should usually be set to 5V
% so that the medial and lateral directions can be used equally
% AO = analogoutput ('nidaq', 'Dev1');
aoSession = daq.createSession('ni');
% aoSession.addAnalogOutputChannel('Dev1',0:2, 'Voltage')

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

