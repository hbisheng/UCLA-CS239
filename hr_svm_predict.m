function [predicted, RMSE] = hr_svm_predict(data, fs, hr, model)
    % Simply aggregate them.
    data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
    features = fq_feature_extract(data, fs);
    % Predict.
    predicted = predict(model, features);
    RMSE = computeRMSE(predicted, hr);
    fprintf('RMSE: %f', RMSE);
    % Plot the prediction result
    figure;
    plot(hr);
    hold on;
    plot(predicted);
    legend('Response in Testing data','Predicted Response','location','best');
end