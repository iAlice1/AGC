% table
% 1. Attack
at = 2*20e-3;
fs = 16e3;
t1 = 0:(1/fs):0.04;
y1 = 0.5/(1-exp(-1))*exp(-t1/at) + (0.5-exp(-1))/(1-exp(-1));
% 2. Release
rt = 2*100e-3;
t2 = 0:(1/fs):0.2;
y2 = 1/(2*exp(-1)-2)*exp(-t2/rt) + (2-exp(-1))/(2-2*exp(-1));

y1 = y1(2:641);
y2 = y2(2:3201);
table_a = zeros(1,10);
table_r = zeros(1,50);
% 1116  new length  table_a 10, table_r 50
for i = 1:10
    table_a(i) = sum(y1(i*64-63:i*64))/64;
    i = i+1;
end
save tablea table_a

for i = 1:length(table_r)
    table_r(i) = sum(y2(i*64-63:i*64))/64;
    i = i+1;
end
save tabler table_r

