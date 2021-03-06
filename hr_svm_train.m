% Train a svm to predict the heart rate.
% data: A 3-d matrix, each row is a sample. Contains 3 channels.
% fs: the sampling rate.
% hr: the ground true heart rate.
% @return model: the trained svm, can be fed into 'predict'.
% @return RMSE: the mean absolute error on train set.
function [model, RMSE] = hr_svm_train(data, fs, hr)
    % Simply aggregate them.
    data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
    features = fq_feature_extract(data, fs);
    % Create a SVM regression model
%     modelGaussian = fitrsvm(features, hr, ...
%         'Standardize', true, ...
%         'kernelfunction', 'gaussian',...
%         'KernelScale', 'auto',...
%         'kFold', 5, ...
%         'Verbose', 0 ...
%         );
%     errGaussian = kfoldLoss(modelGaussian);
%     
%     modelLinear = fitrsvm(features, hr, ...
%         'Standardize', true, ...
%         'kernelfunction', 'linear',...
%         'KernelScale', 'auto',...
%         'kFold', 5, ...
%         'Verbose', 0 ...
%         );
%     errLinear = kfoldLoss(modelLinear);
%     
%     modelPoly = fitrsvm(features, hr, ...
%         'Standardize', true, ...
%         'kernelfunction', 'gaussian',...
%         'KernelScale', 'auto',...
%         'kFold', 5, ...
%         'Verbose', 0 ...
%         );
%     errPoly = kfoldLoss(modelPoly);
%     
%     fprintf('errGaussian: %f, errLinear: %f, errPoly: %f',...
%         errGaussian, errLinear, errPoly);
    
    kernel = 'gaussian';
%     if errLinear <= errGaussian && errLinear <= errPoly
%         kernel = 'linear';
%     end
%     if errPoly <= errGaussian && errPoly <= errLinear
%         kernel = 'polynomial';
%     end
    model = fitrsvm(features, hr, ...
        'Standardize', true, ...
        'kernelfunction', kernel,...
        'KernelScale', 'auto', ...
        'Verbose', 0 ...
        );
    RMSE = computeRMSE(model.resubPredict, hr);
    % Plot the prediction result
    figure;
    scatter(hr, model.resubPredict);
    legend('Response in Training data','location','best');
end