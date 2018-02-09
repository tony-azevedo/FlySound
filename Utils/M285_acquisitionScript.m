
setOrigin(sutterM285);
setVelocity(sutterM285, 5000, 10) 
pause(1) 
% moveTime = moveTo(sutterM285,[-100;0;0]); % outof (+)/ into (-) board (x)
moveTime = moveTo(sutterM285,[100;0;0]); % left(+)/right(-) (y)
pause(1)
moveTime = moveTo(sutterM285,[0;0;0]); % left(+)/right(-) (y)
% 
% % moveTime = moveTo(sutterM285,[-80;0;0]); % outof (+)/ into (-) board (x)
% % moveTime = moveTo(sutterM285,[0;-100;0]); % left(+)/right(-) (y)
% moveTime = moveTo(sutterM285,[0;100;0]); % left(+)/right(-) (y)
% pause(1)
% 
% moveTime = moveTo(sutterM285,[0;100;0]); % left(+)/right(-) (y)
% 
% % moveTime = moveTo(sutterM285,[0;0;0]); % left(+)/right(-) (y)

