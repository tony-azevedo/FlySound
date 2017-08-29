% Shortest probe (units of .1 mg)
Probe1  = [
    0   0
    100 45
    200 96
    300 150
    400 200
    500 250
    25  12
    50  24
    75  40
    100 52
    125 65
    150 79
    175 91
    200 105
    225 120
    250 134
    25  13
    50  26
    75  38
    100 53
    125 65
    150 80
    175 91
    200 106
    225 118
    250 133];

% Next shortest probe (green material, nearly as long as pink probe)
Probe2 = [
    0   -8   -13 0   -1
    100 0   -4  7   6
    200 7   5   16  16
    300 16  11  25  24  
    400 25  21  33  33
    500 33  30  40  NaN
    600 38  38  nan NaN
    700 45  45  nan NaN
    800 54  50  nan NaN
    900 64  65  nan NaN
    1000    70  73  nan NaN];

Probe2(:,2) = Probe2(:,2)-Probe2(1,2);
Probe2(:,3) = Probe2(:,3)-Probe2(1,3);
Probe2(:,5) = Probe2(:,5)-Probe2(1,5);
Probe2 = [
    Probe2(:,1) Probe2(:,2);
    Probe2(:,1) Probe2(:,3);
    Probe2(:,1) Probe2(:,4);
    Probe2(:,1) Probe2(:,5);
    ];
Probe2 = Probe2(~isnan(Probe2(:,2)),:);
    
% Probe3: Original pink probe
Probe3 = [
    0  0    0   0
    100 7   7   6
    200 15  15  14
    300 23  23  21
    400 30  30  28
    500 38  39  35
    600 46  46  38  
    700 55  52  NaN
    800 62  60  NaN
    900 69  68  68
    1000 77 79  79
    ];

Probe3 = [
    Probe3(:,1) Probe3(:,2);
    Probe3(:,1) Probe3(:,3);
    Probe3(:,1) Probe3(:,4);
    ];
Probe3 = Probe3(~isnan(Probe3(:,2)),:);

%%
figure
plot(Probe1(:,1),Probe1(:,2),'.','displayName','Probe1');
hold on
plot(Probe2(:,1),Probe2(:,2),'.','displayName','Probe2');
plot(Probe3(:,1),Probe3(:,2),'.','displayName','Probe3');


legend toggle
xlabel('um')
ylabel('1E-4 g')