%%
clear;
prefix = '20170530_bs_sit';
if_polar = 1;

sampling_rate = 150;
interval_shift = 1 * 1; % seconds
interval_length = 55 * 1; % seconds

% file = '1_android.sensor.accelerometer.data.csv';
file = '4_android.sensor.gyroscope.data.csv';

M = csvread([prefix '/data/' file]);
if if_polar
    polar_data = csvread([prefix '/polar.csv'], 3, 0);
    tmp = polar_data(:, 3);
    segment_num = floor( (length(tmp) - interval_length) / interval_shift + 1);
    polar_hr = zeros(segment_num, 1);
    for i = 1: segment_num;
       polar_hr(i) = mean( tmp( (i-1) * interval_shift+1 : (i-1) * interval_shift + interval_length ) );
    end
end

% perform resampling base on timestamps
channels = resampling(M(:,1), M(:, [2,3,4]), sampling_rate);

% start = 1 + interval_shift * sampling_rate * (i-1)
i = 1;
interval_pointnum = interval_length * sampling_rate;
interval_shiftnum = interval_shift * sampling_rate;

rowNum = floor((size(channels, 1) - interval_pointnum - 1) / interval_shiftnum + 1);
rates_and_power = zeros(rowNum, 5, 2);
true_power = zeros(1, rowNum);

while 1 + interval_shiftnum * (i-1) + interval_pointnum <= size(channels, 1) && i < length(polar_hr)
    window = channels(interval_shiftnum * (i-1) + 1: interval_shiftnum * (i-1) + interval_pointnum, :);
    [rates_and_power(i,:,:), true_power(i)] = predict_heart_rate_still(window(:,1), window(:,2), window(:,3), sampling_rate, 0, polar_hr(i));
    [i rates_and_power(i, 1, 1)]
    i = i + 1;
end

origin = rates_and_power(:, 1, 1);
len = min(length(origin), length(polar_hr));
origin = origin(1:len);
smooth = smooth_curve(origin);

RMSE_origin = computeRMSE(origin, polar_hr(1:len));
RMSE_smooth = computeRMSE(smooth, polar_hr(1:len));
%%
figure();
plot(origin)
hold on
plot(polar_hr)
title('Running, heart rate prediction against time, period = 15 minutes')
xlabel('Time (s)')
ylabel('Heart rate (beats/minutes)')
legend('Heart rate prediction', 'Heart rate ground truth')
set(gca,'fontsize',15)

figure();
plot(smooth)
hold on
plot(polar_hr)
title('Sitting, heart rate prediction(smooth-curved), period = 20 minutes')
xlabel('Time (s)')
ylabel('Heart rate (beats/minutes)')
legend('Heart rate prediction', 'Heart rate ground truth')
set(gca,'fontsize',15)

%%
figure();
plot(rates_and_power(:, :, 2));
hold on
plot(true_power, 'c-');
%%
i = 200;
window = channels(interval_shiftnum * (i-1) + 1: interval_shiftnum * (i-1) + interval_pointnum, :);
predict_heart_rate_still(window(:,1), window(:,2), window(:,3), sampling_rate, 1, polar_hr(i));

polar_hr(i)