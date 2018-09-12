% measurement of light power vs voltage to LED driver

v = [ % in Volts. From daq to external control of LED driver. 1000 mA at 10 V
0.0088914  
0.015811
0.028117
0.05
0.088914
0.15811
0.28117
0.5
0.88914
1.5811
2.8117
5
];  

power = [ % in uW. 
    nan
    nan
2.65
11.12
27
55
108
202
363
638
1.12*1E3
1.88*1E3
];

figure
loglog(v,power), hold on
loglog(v,power,'.')