%-------------Step 1. Read speech x----------------
fs = 16e3;
[x,fs] = audioread('cymenkou1.wav');
N = length(x);
%-------------Step 2. Find offset---------------------
win = 4e-3 *fs; % 4 ms window
num = floor(N/win);
% offset = 20 * log10( rms(x(4000 : 4000+79)) / rms(x(1:win)) );
for j = 1 : num
    off(j) = 20 * log10( rms( x((j*win-win+1):(j*win)) ) );
    j=j+1;
end
offset = max(off) - min(off);  %% Attention

%-------------Step 3. Calculate slope k---------------
k1 = 1; % dB less than 65
k2 = 0.53;                    % 25*exp(65-u); % No more than 90 dB
at = 20e-3; % attack time 20 ms, not 5 ms
rt = 200e-3; % release time 200 ms, not 20 ms

%-------------Step 4. AGC realization-----------------
status = 0;
t = 0;
input = zeros(1,num);
output = zeros(1,num);
k = zeros(1,num);
input(1) = 20*log10( rms(x(1:win)) ) + offset;
tmp = input(1); % last status
if tmp > 65
    status = 1;
    k(1) = k2 - (k2 - k1)*exp(-t/at);
    output(1) = k(1) * input(1);
    t = t + win/fs;
else
    k(1) = 1;
    output(1) = input(1);
end

%for i = 2 : (N-win+1)   
for i = 2: num % No overlap
    input(i) = 20*log10( rms( x((i*win-win+1):(i*win)) ) ) + offset;
    if input(i) > 65 % || ((status == 1) && (t < at))% if current dB > 65
        if status ~= 1
            if status == 0
                t = 0; 
            elseif status == 2
                    t = log( (k(i-1)-k2)/(k1-k2) ) * (-rt);      
            end
        status = 1;
        end
        k(i) = k2 - (k2 - k1)*exp(-t/at);
        t = t + win/fs;
        if (status == 1) && (t < at)
            continue;
        end
    elseif (~(input(i) > 65)) 
        if (status == 0) || ((status == 2) && (t > rt))
            k(i) = 1;
            t = 0; 
            status = 0;
        elseif (status == 1) && (~(t < at))
            status = 2;
            t = 0;
            k(i) = k1 - (k1 - k2)*exp(-t/rt);
        elseif (status == 2) && (~(t > rt))
            k(i) = k1 - (k1 - k2)*exp(-t/rt);
            t = t + win/fs;
        end
    end
    %output(i) = input(i) .* k(i);
%     tmp = input(i); 
    i = i+1;
end

gain = zeros(1,N);
for j = 1 : num
    for i = (j*win-win+1) : (j*win)
        gain(i) = k(j);
        i = i+1;
    end
    j = j+1;
end
y = x'.*gain;


%-------------Diff.---------------------------------
order1 = zeros(1,num-1);
order2 = zeros(1,num-2);
for h = 1:num-2
    order1(h) = input(h+1) - input(h);
    order2(h) = input(h+2) - input(h);
    h = h+1;
end
order1(h) = input(num) - input(num-1);

%-------------Results-------------------------------
b = (1:N)/fs;
a = (1:num)*win/fs;

for i = 2: num
    output(i) = 20*log10( rms( y((i*win-win+1):(i*win)) ) ) + offset;
end
    

figure(1)
subplot(211); 
plot(b,x);
xlabel('t/s')
title('Input signal')
axis([0 8 -1.1 1.1]);
p = get(gca,'pos');
uicontrol('style','push','string','Play','unit','norm','pos',[p(1:2),0.1071,0.0476],'callback','sound(x,fs)');
subplot(212); 
plot(b,y); 
xlabel('t/s')
title('Output signal')
axis([0 8 -1.1 1.1]);
p = get(gca,'pos');
uicontrol('style','push','string','Play','unit','norm','pos',[p(1:2),0.1071,0.0476],'callback','sound(y,fs)');
suptitle('Input-Output Signal in time')

figure(2)
subplot(311); 
plot(a,input);
ylabel('dB')
axis([0 8 -10 90]);
subplot(312); 
plot(a,k);
ylabel('Gain level')
axis([0 8 0 1.1]);
subplot(313); 
plot(a,output); 
ylabel('dB')
axis([0 8 -10 90]);
suptitle('Input-Output AGC in dB')

% figure
% subplot(311)
% plot(b,gain);
% ylabel('Gain level')
% axis([0 7.9 0 1.1]);


% figure(3)
% plot(order1)
% title('1st Order Difference')
% figure(4)
% plot(order2)
% title('2nd Order Difference')
