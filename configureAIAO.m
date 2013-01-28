function [AI AO] = configureAIAO(protocol)

daqreset;
%% configure testPiezo AI and AO
if strcmp(protocol,'testPiezo')
    sampratein = 10000; samprateout = 10000;
    
    % configure AI
    AI = configureAI(sampratein);
    
    % configure AO
    staticDisp = 5; % staticDisp = static voltage output to piezo; should usually be set to 5V
                    % so that the medial and lateral directions can be used equally
    % AO = analogoutput ('nidaq', 'Dev1');
    AO = analogoutput ('nidaq', 'Dev3');
    addchannel (AO, 0:1);
    set(AO, 'SampleRate', samprateout);
    set(AO, 'TriggerType', 'Manual');
    %AO.Channel.OutputRange = [-1 10];
    putsample(AO,[staticDisp 0]);
    
    
%% configure testAMfreq AI and AO
elseif strcmp(protocol,'testFmAndCS') || strcmp(protocol,'testFc')
    sampratein = 10000; samprateout = 40000;
    
    % configure AI
    AI = configureAI(sampratein);
    
    % configure AO
    AO = analogoutput ('nidaq', 'Dev3');
    % addchannel (AO, 0:1);
    addchannel (AO, 0);
    set(AO, 'SampleRate', samprateout);
    set(AO, 'TriggerType', 'Manual');
    
%% configure testCurrentInj AI and AO    
elseif strcmp(protocol,'testCurrentInj')
    sampratein = 10000; samprateout = 10000;
    
    % configure AI
    AI = configureAI(sampratein);
    
    % configure one AO channel (for both Ihpulse and current injection)
    AO = analogoutput ('nidaq', 'Dev3');
    addchannel (AO, 1);
    set(AO, 'SampleRate', samprateout);
    set(AO, 'TriggerType', 'Manual');
    
%% configure testWind AI and AO
elseif strcmp(protocol,'testwind')
    sampratein = 10000; samprateout = 1000;
    
    % configure AI
    AI = configureAI(sampratein);
    
    % configure analog output
    AO = analogoutput ('nidaq', 'Dev3');
    addchannel (AO, 1);
    set(AO, 'SampleRate', samprateout);
    set(AO, 'TriggerType', 'Manual');
end

%% configure AI
function AI = configureAI(sampratein)

AI = analoginput ('nidaq', 'Dev3');
addchannel (AI, 0:2);  % initialize channels A0,A1,A2 (10Vm_out, I_out, and scaled output, respectively)
set(AI, 'SampleRate', sampratein);
set(AI, 'SamplesPerTrigger', inf);
set(AI, 'InputType', 'Differential');
set(AI, 'TriggerType', 'Manual');
set(AI, 'ManualTriggerHwOn','Trigger');