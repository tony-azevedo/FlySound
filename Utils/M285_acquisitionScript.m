
setOrigin(sutterM285);
setVelocity(sutterM285, 200, 10) 
pause(2) 
moveTime = moveTo(sutterM285,[-100;0;0]);%% positive flexes the leg
% moveTime = moveTo(sutterM285,[0;-40;0]); % left/right (y)
pause(2)

moveTime = moveTo(sutterM285,[100;0;0]); % in/out of board (x)
% moveTime = moveTo(sutterM285,[0;40;0]); % left/right (y)
 
