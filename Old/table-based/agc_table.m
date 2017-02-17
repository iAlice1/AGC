%-------------Step 1. Read speech x----------------
fs = 16e3;
[x,fs] = audioread('speech.wav');
N = length(x);
%-------------Step 2. Find offset---------------------
win = 4e-3 *fs; % 4 ms window
num = floor(N/win);
for j = 1 : num
    off(j) = 20 * log10( rms( x((j*win-win+1):(j*win)) ) );
    j=j+1;
end
offset = max(off) - min(off);  %% Attention

%-------------Step 3. Calculate slope k---------------
k1 = 1; % dB less than 65
k2 = 5/11;    % No more than 90 dB
at = 2*20e-3; % attack time 20 ms, not 5 ms
rt = 200e-3; % release time 200 ms, not 20 ms

%-------------Step 4. AGC realization-----------------
status = 0;
% t = 0;
input = zeros(1,num);
output = zeros(1,num);
%k = zeros(1,num);
for i = 1: num
    input(i) = 20*log10( rms( x((i*win-win+1):(i*win)) ) ) + offset;
    i = i+1;
end

% load tablea
% load tabler
k(1) = 1;
index_a = 0;
index_r = 0;
%for i = 2 : (N-win+1)   
for i = 2:num % No overlap
    if (input(i) > 65) || ((~(input(i)>65)) && (index_a~=0))% && index_a<64)
        if (index_a == 0) && (index_r == 0)
            t = 0; 
            index_a = 1;
        elseif index_r ~= 0
                %  k(i-1) or table_r(index)
                [m,index_a] = min( abs(k(i-1)-table_a) );
                index_r = 0;
        end
        if (index_a > 10) || (k(i-1)==0.5)
            index_a = 0;
            k(i) = 0.5;
        else
            k(i) = table_a(index_a);
            index_a = index_a + 1;
        end
        
    elseif (~(input(i) > 65) && index_a == 0) 
        if (k(i-1) == 1) || (index_r > 50)
            k(i) = 1;
            index_r = 0;
        elseif k(i-1)==0.5
            index_r = 1;
            k(i) = table_r(index_r);
            index_r = index_r + 1;
        elseif (index_r > 0) && ~(index_r > 50)
            k(i) = table_r(index_r);
            index_r = index_r + 1;
        end 
    end
    i = i+1;
end
% output = input .* k;

gain = zeros(1,N);
for a = 1 : num
    for i = (a*win-win+1) : (a*win)
        gain(i) = k(a);
        i = i+1;
    end
    a = a+1;
end
y = x'.*gain;
for i = 1: num
    input(i) = 20*log10( rms( y((i*win-win+1):(i*win)) ) ) + offset;
    i = i+1;
end

%-------------Diff.---------------------------------
order1 = zeros(1,num-1);
order2 = zeros(1,num-2);
for h = 1:num-2
    order1(h) = input(h+1) - input(h);
    order2(h) = input(h+2) - input(h);
    h = h+1;
end
% order1(h) = input(num) - input(num-1);

%-------------Results-------------------------------
b = (1:N)/fs;
a = (1:num)*win/fs;

figure(1)
subplot(211); 
plot(b,x);
xlabel('t/s')
title('Input signal')
axis([0 8.9 -1.1 1.1]);
p = get(gca,'pos');
uicontrol('style','push','string','Play','unit','norm','pos',[p(1:2),0.1071,0.0476],'callback','sound(x,fs)');
% subplot(312); 
% plot(b,gain);
% ylabel('Gain level')
% axis([0 9 0.35 1.1]);
subplot(212); 
plot(b,y); 
xlabel('t/s')
title('Output signal')
axis([0 8.9 -1.1 1.1]);
p = get(gca,'pos');
uicontrol('style','push','string','Play','unit','norm','pos',[p(1:2),0.1071,0.0476],'callback','sound(y,fs)');
suptitle('Input-Output Signal in time')

figure(2)
subplot(311); 
plot(a,input);
ylabel('dB')
axis([0 8.9 -1 80]);
subplot(312); 
plot(a,k);
ylabel('Gain level')
axis([0 8.9 0 1.1]);
subplot(313); 
plot(a,output); 
ylabel('dB')
axis([0 8.9 -1 80]);
suptitle('Input-Output AGC in dB')

% figure 
% plot(k)
% %axis([0 8.9 0 1.1 ])
% figure(3)
% plot(order1)
% title('1st Order Difference')
% figure(4)
% plot(order2)
% title('2nd Order Difference')
