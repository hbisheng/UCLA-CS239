%%
clear;
close all;

% Data we would like to use.
folder_name = '20170530_bs_sit';
% Use which data. 1 for accelerometer, 0 for gyroscope.
use_acc = 0;
% Sliding window step.
interval_shift = 1 * 1; % seconds
% Sliding window size.
interval_length = 40 * 1; % seconds


if use_acc == 1
    sampling_rate = 250;
    file = '1_android.sensor.accelerometer.data.csv';
else
    sampling_rate = 150;
    file = '4_android.sensor.gyroscope.data.csv';
end

% load the data file
M = csvread([folder_name '/data/' file]);

% load ground truth from polar data
polar_data = csvread([folder_name '/polar.csv'], 3, 0);
tmp = polar_data(:, 3);
segment_num = floor( (length(tmp) - interval_length) / interval_shift + 1);
polar_hr = zeros(segment_num, 1);
for i = 1: segment_num;
   polar_hr(i) = mean( tmp( (i-1) * interval_shift+1 : (i-1) * interval_shift + interval_length ) );
end

% perform resampling base on timestamps
data_resampled = resampling(M(:,1), M(:, [2,3,4]), sampling_rate);

i = 1;
interval_pointnum = interval_length * sampling_rate;
interval_shiftnum = interval_shift * sampling_rate;

windowNum = floor((size(data_resampled, 1) - interval_pointnum - 1) / interval_shiftnum + 1);

% for each window, get the top 5 power and their corresponding heart rates
rates_and_power = zeros(windowNum, 5, 2);

% the power of the true heart rate
true_power = zeros(1, windowNum);

while 1 + interval_shiftnum * (i-1) + interval_pointnum <= size(data_resampled, 1) && i < length(polar_hr)
    window = data_resampled(interval_shiftnum * (i-1) + 1: interval_shiftnum * (i-1) + interval_pointnum, :);
    [rates_and_power(i,:,:), true_power(i)] = predict_heart_rate(window(:,1), window(:,2), window(:,3), sampling_rate, 0, polar_hr(i));
    i = i + 1;
end

predicted_hr = rates_and_power(:, 1, 1);
len = min(length(predicted_hr), length(polar_hr));
predicted_hr = predicted_hr(1:len);
smooth_hr = smooth_curve(predicted_hr);

RMSE_origin = computeRMSE(predicted_hr, polar_hr(1:len));
RMSE_smooth = computeRMSE(smooth_hr, polar_hr(1:len));

figure();
plot(predicted_hr)
hold on
plot(polar_hr)
title(['Heart rate prediction RMSE:' num2str(RMSE_origin)])
xlabel('Time (s)')
ylabel('Heart rate (beats/minutes)')
legend('Heart rate prediction', 'Heart rate ground truth')
set(gca,'fontsize',15)

figure();
plot(smooth_hr)
hold on
plot(polar_hr)
title(['HR prediction(smooth-curved) RMSE:' num2str(RMSE_smooth)])
xlabel('Time (s)')
ylabel('Heart rate (beats/minutes)')
legend('Heart rate prediction', 'Heart rate ground truth')
set(gca,'fontsize',15)

%% Show the figure of the ith window
i = 200;
window = data_resampled(interval_shiftnum * (i-1) + 1: interval_shiftnum * (i-1) + interval_pointnum, :);
predict_heart_rate(window(:,1), window(:,2), window(:,3), sampling_rate, 1, polar_hr(i));

%% 
% In frequency domain of each data window
% plot the top 5 power and the power corresponding to the true heart rate
figure();
plot(rates_and_power(:, :, 2));
hold on
plot(true_power, 'c-');