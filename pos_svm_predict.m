function [predicted, err] = pos_svm_predict(data, fs, pos, model)
    % Simply aggregate them.
    data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
    features = fq_feature_extract(data, fs);
    % Predict.
    predicted = predict(model, features);
    err = sum(predicted ~= pos) / length(pos);
    fprintf('RMSE: %f', err);
    % Plot the prediction result
    figure;
    scatter(pos, predicted);
%     plot(hr);
%     hold on;
%     plot(predicted);
    legend('Response in Testing data','Predicted Response','location','best');
end