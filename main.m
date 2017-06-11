clear;
prefix = '20170530_running';
if_polar = 1;

sampling_rate = 150;
interval_shift = 1 * 1; % seconds
interval_sec = 20 * 1; % seconds

% file = '1_android.sensor.accelerometer.data.csv';
file = '4_android.sensor.gyroscope.data.csv';

M = csvread([prefix '/data/' file]);
if if_polar
    polar_data = csvread([prefix '/polar.csv'], 3, 0);
    polar_hr = polar_data(interval_sec:end, 3);
end

% perform resampling base on timestamps
timestamps = M(:, 1);
timestamps = (timestamps - timestamps(1)) / 1000;

origin_data = M(:, [2,3,4]);
data_timeseries = timeseries(origin_data, timestamps);

new_time = timestamps(1):(1/sampling_rate):timestamps(end);
data_resampled = resample(data_timeseries, new_time);
channels = data_resampled.data;

% start = 1 + interval_shift * sampling_rate * (i-1)
i = 1;
interval_pointnum = interval_sec * sampling_rate;
interval_shiftnum = interval_shift * sampling_rate;

rowNum = floor((size(channels, 1) - interval_pointnum - 1) / interval_shiftnum + 1);
result = zeros(1, rowNum);

data_matrix = zeros(rowNum, interval_pointnum, 3);
truth_labels = zeros(rowNum,1);

length - 1 - interval_pointNum

while 1 + interval_shiftnum * (i-1) + interval_pointnum <= size(channels, 1)
    window = channels(interval_shiftnum * (i-1) + 1: interval_shiftnum * (i-1) + interval_pointnum, :);
%     rate = predict_heart_rate_still(window(:,1), window(:,2), window(:,3), sampling_rate, 0);
%     [i rate]
%     result(i) = rate;
    data_matrix(i, :, 1) = window(:,1);
    data_matrix(i, :, 2) = window(:,2);
    data_matrix(i, :, 3) = window(:,3);
    truth_labels(i) = polar_hr(i);
    i = i + 1;
end

figure();
plot(result);
if if_polar
    hold on
    plot(polar_hr);
end