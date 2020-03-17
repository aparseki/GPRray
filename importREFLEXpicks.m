function [DATA] = importREFLEXpicks(filein)
% takes in a reflex pick file with pick labels and extracts just the
% reflectors. Assumes air and GW are also picked.  Pick order must be
% sequential from earliest times to later.

d = load(filein);

d = sortrows(d,7);
x = d(:,2);
t = d(:,4);
l = d(:,7)+1;

numlay = max(l);
for i = 3:numlay; %starting on #3 to ignore airwave and groundwave
g = l == i;

DATA{i-2} = [x(g)'; t(g)'];
end





