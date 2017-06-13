clear;
prefix = '20170530_walking_pocket';
if_polar = 1;

sampling_rate = 150;
interval_shift = 1 * 1; % seconds
interval_sec = 30 * 1; % seconds

% file = '1_android.sensor.accelerometer.data.csv';
file = '4_android.sensor.gyroscope.data.csv';

M = csvread([prefix '/data/' file]);
if if_polar
    polar_data = csvread([prefix '/polar.csv'], 3, 0);
    polar_hr = polar_data(interval_sec:end, 3);
end

% perform resampling base on timestamps
channels = resampling(M(:,1), M(:, [2,3,4]), sampling_rate);

% start = 1 + interval_shift * sampling_rate * (i-1)
i = 1;
interval_pointnum = interval_sec * sampling_rate;
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

figure();
plot(rates_and_power(:, 1, 1));
if if_polar
    hold on
    plot(polar_hr);
end


figure();
plot(rates_and_power(:, :, 2));
hold on
plot(true_power, 'co');