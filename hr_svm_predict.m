function [predicted, RMSE] = hr_svm_predict(data, fs, hr, model)
    % Simply aggregate them.
    agg = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
    features = fq_feature_extract(agg, fs);
    % Predict.
    predicted = predict(model, features);
    RMSE = computeRMSE(predicted, hr);
    fprintf('RMSE: %f', RMSE);
    % Plot the prediction result
    figure;
    scatter(hr, predicted);
    hold on;
    plot(hr, hr, 'LineWidth', 2);
%     plot(hr);
%     hold on;
%     plot(predicted);
    xlabel('Goundtrue HR (BPM)');
    ylabel('Estimated HR (BPM)');
    window = size(agg, 2) / fs;
    sensor = 'Accelerometer';
    if fs < 200
        sensor = 'Gyroscope';
    end
    title(sprintf('Estimated HR (BPM), window = %ds, %s', window, sensor));
end