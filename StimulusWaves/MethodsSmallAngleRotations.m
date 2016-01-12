% Methods: calculate rotations and rotational velocities, etc, from the
% small angle approximation

V2d = 3; % um per V
r = 170; % um;

v = .3*.05; %[.3 1 3 10] * .05 %V

x = V2d*v;

theta_0 = asin(x/r) % 2.647e-4 rad for 0.015;
theta_a = x/r % 2.647e-4 rad for 0.015;

er = (theta_0-theta_a)/theta_0 * 100

deg = radtodeg(theta_a)


%% From Lehnert S1

v_air = 1E-3; % m/s
theta_ant = 1.55E-3; % rad
v_ref = 5E-8; % m/s

SVL = 20*log10(v_air/v_ref)

theta_ant*170 

%% From Lehnert S1 Behavioral threshold and dB thresh = 65

v_ref = 5E-8; % m/s
SVL = 65;
v_air = 10^(SVL/20) * v_ref % 8.9E-5

theta_ant = 4.1E-4; % rad

x_tresh = theta_ant*170

%% from Lehnert text on the startle response
v_ref = 5E-8; % m/s
v_air = 1.2E-4; % m/s
SVL = 20*log10(v_air/v_ref)

% this is weird, it all depends on what we report.

theta_ant = 5.28E-4

x_tresh = theta_ant*170
