clear;
folders_name = {'20170530_walking_pocket', ...
     '20170530_running', '20170530_sit'};

acc_sampling_rate = 250;
gyro_sampling_rate = 150;

interval_shift = 1 * 1; % seconds
interval_length = 20 * 1; % seconds

total_segment = 0;
MAX_SEG = 7200;
acc_segments = zeros(MAX_SEG, interval_length * acc_sampling_rate, 3);
gyro_segments = zeros(MAX_SEG, interval_length * gyro_sampling_rate, 3);
polar_label = zeros(MAX_SEG,1);
file_label = zeros(MAX_SEG,1);
per_file_acc_segments = zeros([length(folders_name), size(acc_segments)]);
per_file_gyro_segments = zeros([length(folders_name), size(gyro_segments)]);
per_file_polar_label = zeros(length(folders_name), MAX_SEG, 1);
per_file_total_segments = zeros(length(folders_name), 1);

for folder_idx = 1 : length(folders_name)
    prefix = folders_name{folder_idx};
    polar_data = csvread([prefix '/polar.csv'], 3, 0);
    polar_hr = polar_data(interval_length:end, 3);
    
    acc_file  = '1_android.sensor.accelerometer.data.csv';    
    gyro_file = '4_android.sensor.gyroscope.data.csv';
    
    acc_M = csvread([prefix '/data/' acc_file]);
    gyro_M = csvread([prefix '/data/' gyro_file]);
    
    resampled_acc_M = resampling(acc_M(:, 1), acc_M(:, [2,3,4]), acc_sampling_rate); 
    resampled_gyro_M = resampling(gyro_M(:, 1), gyro_M(:, [2,3,4]), gyro_sampling_rate); 
    
    acc_segment_num = floor((size(resampled_acc_M, 1) - 1 - interval_length*acc_sampling_rate) / (interval_shift*acc_sampling_rate) + 1);
    gyro_segment_num = floor((size(resampled_gyro_M, 1) - 1 - interval_length*gyro_sampling_rate) / (interval_shift*gyro_sampling_rate) + 1);
    
%     for segment_idx = 1: 600
    for segment_idx = 1: min([acc_segment_num, gyro_segment_num, length(polar_hr)])
        per_file_total_segments(folder_idx) = per_file_total_segments(folder_idx) + 1;
        total_segment = total_segment + 1;
        acc_segments(total_segment, :, :) = resampled_acc_M( interval_shift*acc_sampling_rate * (segment_idx-1) + 1: interval_shift*acc_sampling_rate * (segment_idx-1) + interval_length*acc_sampling_rate,:);
        per_file_acc_segments(folder_idx, segment_idx, :, :) = acc_segments(total_segment, :, :);
        gyro_segments(total_segment, :, :) = resampled_gyro_M( interval_shift*gyro_sampling_rate * (segment_idx-1) + 1: interval_shift*gyro_sampling_rate * (segment_idx-1) + interval_length*gyro_sampling_rate,:);
        per_file_gyro_segments(folder_idx, segment_idx, :, :) = gyro_segments(total_segment, :, :);
        polar_label(total_segment) = polar_hr(segment_idx);
        per_file_polar_label(folder_idx, segment_idx, :) = polar_label(total_segment);
        file_label(total_segment) = folder_idx;
    end
end

random_indice = randperm(total_segment);
kfold = 5;
fold_len = floor(length(random_indice) / kfold);

for k = 1 : 1
%     train_indice = random_indice( (k - 1) * fold_len + 1 : k * fold_len );
%     test_indice = [random_indice(1: (k - 1) * fold_len ) random_indice(k * fold_len + 1: end)];
    
%     [model, trainRMSE] = hr_svm_train(acc_segments(train_indice, :, :), acc_sampling_rate, polar_label(train_indice));
%     [predicted, testRMSE] = hr_svm_predict(acc_segments(test_indice, :, :), acc_sampling_rate, polar_label(test_indice), model);
%     
%     [posModel, err] = pos_svm_train(acc_segments(train_indice, :, :), acc_sampling_rate, file_label(train_indice));
%     [posPredicted, posErr] = pos_svm_predict(acc_segments(test_indice, :, :), acc_sampling_rate, file_label(test_indice), posModel);
%     
    % Train a svm for each pos.
    pos_train_data = [];
    pos_train_label = [];
    pos_test_data = [];
    pos_test_label = [];
    pos_test_hr = [];
    models = cell(1, length(folders_name));
    for fid = 1 : length(folders_name)
        r = randperm(per_file_total_segments(fid));
        bar = floor(length(r) / kfold);
        tr = r(1:bar);
        te = r(bar+1:end);
        train_data = squeeze(per_file_acc_segments(fid, tr, :, :));
        train_hr = per_file_polar_label(fid, tr)';
        test_data = squeeze(per_file_acc_segments(fid, te, :, :));
        test_hr = per_file_polar_label(fid, te)';
        pos_train_data = [pos_train_data; train_data];
        pos_train_label = [pos_train_label; ones(size(train_hr, 1), 1) * fid];
        pos_test_data = [pos_test_data; test_data];
        pos_test_label = [pos_test_label; ones(size(test_hr, 1), 1) * fid];
        pos_test_hr = [pos_test_hr; test_hr];
        models{fid} = hr_svm_train(train_data, acc_sampling_rate, train_hr);
        [~, testRMSE] = hr_svm_predict(test_data, acc_sampling_rate, test_hr, models{fid});
    end
    % Train a pos classifier.
    [posModel, err] = pos_svm_train(pos_train_data, acc_sampling_rate, pos_train_label);
%     [posPredicted, posErr] = pos_svm_predict(acc_segments(test_indice, :, :), acc_sampling_rate, file_label(test_indice), posModel);
    predicted = zeros(size(pos_test_hr));
    for i = 1 : size(pos_test_hr, 1)
        data = pos_test_data(i, :, :);
        data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
        feature = fq_feature_extract(data, acc_sampling_rate);
        label = predict(posModel, feature);
        predicted(i) = predict(models{label}, feature);
    end
    RMSE = computeRMSE(pos_test_hr(pos_test_label == 1), predicted(pos_test_label == 1));
    figure;
    scatter(pos_test_hr, predicted);
end