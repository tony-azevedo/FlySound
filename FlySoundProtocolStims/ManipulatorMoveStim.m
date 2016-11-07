function [stim,m] = ManipulatorMoveStim(p)

x = makeInTime(p);
y = x;
y(:) = 0;
m = repmat(y(:)',3,1);
nmoves = length(p.coordinate);

for i = 1:nmoves
    y(x>=(i-1)*(p.pause+.1) & x<i*(p.pause+.1)) = norm(p.coordinate{i},2);
    move = p.coordinate{1};
    m(1,x>=(i-1)*(p.pause+.1) & x<i*(p.pause+.1)) = move(1);
    m(2,x>=(i-1)*(p.pause+.1) & x<i*(p.pause+.1)) = move(2);
    m(3,x>=(i-1)*(p.pause+.1) & x<i*(p.pause+.1)) = move(3);
end
if ~p.return
    y(x>=i*(p.pause+.1)) = norm(p.coordinate{i},2);
    m(1,x>=i*(p.pause+.1)) = move(1);
    m(2,x>=i*(p.pause+.1)) = move(2);
    m(3,x>=i*(p.pause+.1)) = move(3);
end
if ~sum(m(3,:))
    m = m(1:2,:);
end
stim = y;