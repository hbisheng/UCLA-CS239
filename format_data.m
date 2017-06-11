clear;
folders_name = {'20170530_sit', ...% '20170530_running',  %'20170530_walking_air', ...
                '20170530_walking_pocket'};%, '20170610_zr_sit'}';

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
    
    for segment_idx = 1: 300 %min([acc_segment_num, gyro_segment_num, length(polar_hr)])
        total_segment = total_segment + 1;
        acc_segments(total_segment, :, :) = resampled_acc_M( interval_shift*acc_sampling_rate * (segment_idx-1) + 1: interval_shift*acc_sampling_rate * (segment_idx-1) + interval_length*acc_sampling_rate,:);
        gyro_segments(total_segment, :, :) = resampled_gyro_M( interval_shift*gyro_sampling_rate * (segment_idx-1) + 1: interval_shift*gyro_sampling_rate * (segment_idx-1) + interval_length*gyro_sampling_rate,:);
        polar_label(total_segment) = polar_hr(segment_idx);
        file_label(total_segment) = folder_idx;
    end
end

random_indice = randperm(total_segment);
kfold = 5;
fold_len = floor(length(random_indice) / kfold);

for k = 1 : 1
    test_indice = random_indice( (k - 1) * fold_len + 1 : k * fold_len );
    train_indice = [random_indice(1: (k - 1) * fold_len ) random_indice(k * fold_len + 1: end)];
    
    hr_svm_train(acc_segments(train_indice, :, :), acc_sampling_rate, polar_label(train_indice));
end