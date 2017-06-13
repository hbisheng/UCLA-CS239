clear;
close all;
% Data we would like to use.
folders_name = {'20170530_bs_sit', '20170611_bs_walk_pocket', '20170530_bs_running', ...
    '20170611_zr_walk_pocket'};

% Sampling rate for accelerometer
acc_sampling_rate = 250;
% Sampling rate for gyroscope.
gyro_sampling_rate = 150;
% Use which data. 1 for accelerometer, 0 for gyroscope.
use_acc = 0;

% Sliding window step.
interval_shift = 1 * 1; % seconds
% Sliding window size.
interval_length = 25 * 1; % seconds

% Total number of segments.
total_segment = 0;
% At most 3600 segments.
MAX_SEG = 3600;
% Allocate the segments.
acc_segments = zeros(MAX_SEG, interval_length * acc_sampling_rate, 3);
gyro_segments = zeros(MAX_SEG, interval_length * gyro_sampling_rate, 3);
polar_label = zeros(MAX_SEG,1);
file_label = zeros(MAX_SEG,1);
per_file_acc_segments = zeros([length(folders_name), size(acc_segments)]);
per_file_gyro_segments = zeros([length(folders_name), size(gyro_segments)]);
per_file_polar_label = zeros(length(folders_name), MAX_SEG, 1);
per_file_total_segments = zeros(length(folders_name), 1);

% Used for the final test for the whole system.
% Number of test segments for each scenario.
final_test_n = 180;
total_final_segments = 0;
final_test_acc_segments = zeros(final_test_n * 3, interval_length * acc_sampling_rate, 3);
final_test_gyro_segments = zeros(final_test_n * 3, interval_length * gyro_sampling_rate, 3);
final_test_hr = zeros(final_test_n * 3, 1);

% Load all the files.
for folder_idx = 1 : length(folders_name)
    prefix = folders_name{folder_idx};
    polar_data = csvread([prefix '/polar.csv'], 3, 0);
    polar_hr = polar_data(:, 3);
    
    acc_file  = '1_android.sensor.accelerometer.data.csv';    
    gyro_file = '4_android.sensor.gyroscope.data.csv';
    
    acc_M = csvread([prefix '/data/' acc_file]);
    gyro_M = csvread([prefix '/data/' gyro_file]);
    
    resampled_acc_M = resampling(acc_M(:, 1), acc_M(:, [2,3,4]), acc_sampling_rate); 
    resampled_gyro_M = resampling(gyro_M(:, 1), gyro_M(:, [2,3,4]), gyro_sampling_rate); 
    
    acc_segment_num = floor((size(resampled_acc_M, 1) - 1 - interval_length*acc_sampling_rate) / (interval_shift*acc_sampling_rate) + 1);
    gyro_segment_num = floor((size(resampled_gyro_M, 1) - 1 - interval_length*gyro_sampling_rate) / (interval_shift*gyro_sampling_rate) + 1);

    polar_segment_num = floor((length(polar_hr) - interval_length) / interval_shift + 1);
    
    for segment_idx = 1: min([acc_segment_num, gyro_segment_num, polar_segment_num])
        acc_seg = resampled_acc_M( interval_shift*acc_sampling_rate * (segment_idx-1) + 1: interval_shift*acc_sampling_rate * (segment_idx-1) + interval_length*acc_sampling_rate,:);
        gyro_seg = resampled_gyro_M( interval_shift*gyro_sampling_rate * (segment_idx-1) + 1: interval_shift*gyro_sampling_rate * (segment_idx-1) + interval_length*gyro_sampling_rate,:);
        hr_seg = mean(polar_hr((segment_idx-1)*interval_shift+1 : (segment_idx-1)*interval_shift + interval_length));
        if folder_idx < 4 && segment_idx <= final_test_n
            % Cut the first final_test_n segments to the final test.
            total_final_segments = total_final_segments + 1;
            final_test_acc_segments(total_final_segments, :, :) = acc_seg;
            final_test_gyro_segments(total_final_segments, :, :) = gyro_seg;
            final_test_hr(total_final_segments) = hr_seg;
            continue;
        end
        % Otherwise, used for training and cross validation.
        per_file_total_segments(folder_idx) = per_file_total_segments(folder_idx) + 1;
        total_segment = total_segment + 1;
        acc_segments(total_segment, :, :) = acc_seg;
        per_file_acc_segments(folder_idx, per_file_total_segments(folder_idx), :, :) = acc_seg;
        gyro_segments(total_segment, :, :) = gyro_seg;
        per_file_gyro_segments(folder_idx, per_file_total_segments(folder_idx), :, :) = gyro_seg;
        polar_label(total_segment) = hr_seg;
        per_file_polar_label(folder_idx, per_file_total_segments(folder_idx), :) = hr_seg;
        file_label(total_segment) = folder_idx;
    end
end

random_indice = randperm(total_segment);
kfold = 5;
fold_len = floor(length(random_indice) / kfold);
if use_acc
    sampling_rate = acc_sampling_rate
else
    sampling_rate = gyro_sampling_rate;
end

for k = 1 : 1
    % Train a svm for each pos.
    pos_train_data = [];
    pos_train_label = [];
    pos_test_data = [];
    pos_test_label = [];
    pos_test_hr = [];
    models = cell(1, length(folders_name));
    for fid = 1 : length(folders_name) - 1
        r = randperm(per_file_total_segments(fid));
        bar = floor(length(r) / kfold);
        % Cut the data into training and testing.
        tr = r(1:bar);
        te = r(bar+1:end);
        % Prepare the data using gyroscope.
        if use_acc
            train_data = squeeze(per_file_acc_segments(fid, tr, :, :));
            test_data = squeeze(per_file_acc_segments(fid, te, :, :));
        else
            train_data = squeeze(per_file_gyro_segments(fid, tr, :, :));
            test_data = squeeze(per_file_gyro_segments(fid, te, :, :));
        end
        train_hr = per_file_polar_label(fid, tr)';
       
        test_hr = per_file_polar_label(fid, te)';
        pos_train_data = [pos_train_data; train_data];
        pos_train_label = [pos_train_label; ones(size(train_hr, 1), 1) * fid];
        pos_test_data = [pos_test_data; test_data];
        pos_test_label = [pos_test_label; ones(size(test_hr, 1), 1) * fid];
        pos_test_hr = [pos_test_hr; test_hr];
        models{fid} = hr_svm_train(train_data, sampling_rate, train_hr);
        [~, testRMSE] = hr_svm_predict(test_data, sampling_rate, test_hr, models{fid});
    end
    
    % Train a pos classifier.
    [posModel, err] = pos_svm_train(pos_train_data, sampling_rate, pos_train_label);
    % Do the cross validation.
    predicted = zeros(size(pos_test_hr));
    for i = 1 : size(pos_test_hr, 1)
        data = pos_test_data(i, :, :);
        data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
        feature = fq_feature_extract(data, sampling_rate);
        label = predict(posModel, feature);
        predicted(i) = predict(models{label}, feature);
    end
    RMSE = computeRMSE(pos_test_hr, predicted);
    RMSEs = zeros(1, length(folders_name) - 1);
    for i = 1 : length(folders_name) - 1
        RMSEs(i) = computeRMSE(pos_test_hr(pos_test_label==i), predicted(pos_test_label==i));
    end
    figure;
    scatter(pos_test_hr, predicted);
    
    % Do a final test using gyroscope data.
    if use_acc
        pos_test_data = final_test_acc_segments(1:total_final_segments, :, :);
    else
        pos_test_data = final_test_gyro_segments(1:total_final_segments, :, :);
    end
    pos_test_hr = final_test_hr(1:total_final_segments, :);
    predicted = zeros(size(pos_test_hr));
    for i = 1 : size(pos_test_hr, 1)
        data = pos_test_data(i, :, :);
        data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
        feature = fq_feature_extract(data, sampling_rate);
        label = predict(posModel, feature);
        predicted(i) = predict(models{label}, feature);
    end
    RMSE = computeRMSE(pos_test_hr, predicted);
    RMSE_sitting = computeRMSE(pos_test_hr(1:final_test_n), predicted(1:final_test_n));
    RMSE_walking = computeRMSE(pos_test_hr((final_test_n+1):2*final_test_n), predicted((final_test_n+1):2*final_test_n));
    RMSE_running = computeRMSE(pos_test_hr((2*final_test_n+1):3*final_test_n), predicted((2*final_test_n+1):3*final_test_n));
    fprintf('RMSE Sit %f Walk %f Run %f All %f\n', RMSE_sitting, RMSE_walking, RMSE_running);
    figure;
    plot(predicted);
    hold on;
    plot(pos_test_hr);
    legend('predicted', 'ground true');
    xlabel('Time(s)');
    ylabel('Heart Beat (BPM)');
    title('Estimated Heart Rate');

%     pos_test_data = squeeze(per_file_acc_segments(4, 1:per_file_total_segments(4), :, :));
%     pos_test_label = ones(size(pos_test_data, 1), 1) * 2;
%     pos_test_hr = per_file_polar_label(4, 1:per_file_total_segments(4))';
%     predicted = zeros(size(pos_test_hr));
%     for i = 1 : size(pos_test_hr, 1)
%         data = pos_test_data(i, :, :);
%         data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
%         feature = fq_feature_extract(data, acc_sampling_rate);
%         label = predict(posModel, feature);
%         predicted(i) = predict(models{label}, feature);
% %         fprintf('label = %d, heart = %d, max(feature) = %d\n', label, predicted(i), max(feature));
%     end
%     RMSE = computeRMSE(pos_test_hr, predicted)
%     figure;
%     plot(predicted);
%     hold on;
%     plot(pos_test_hr);
%     legend('predicted', 'ground true');
end