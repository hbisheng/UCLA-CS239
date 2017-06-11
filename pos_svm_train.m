% Train a svm to predict the heart rate.
% data: A 3-d matrix, each row is a sample. Contains 3 channels.
% fs: the sampling rate.
% hr: the ground true heart rate.
% @return model: the trained svm, can be fed into 'predict'.
% @return RMSE: the mean absolute error on train set.
function [model, err] = pos_svm_train(data, fs, pos)
    % Simply aggregate them.
    data = sqrt(data(:,:,1).^2 + data(:,:,2).^2 + data(:,:,3).^2);
    features = fq_feature_extract(data, fs);
    % Create a SVM regression model
%     modelGaussian = fitcsvm(features, pos, ...
%         'Standardize', true, ...
%         'kernelfunction', 'gaussian',...
%         'KernelScale', 'auto',...
%         'Verbose', 1 ...
%         );
%     CVGaussian = crossval(modelGaussian);
%     errGaussian = kfoldLoss(CVGaussian);
%     
%     modelLinear = fitcsvm(features, pos, ...
%         'Standardize', true, ...
%         'kernelfunction', 'linear',...
%         'KernelScale', 'auto',...
%         'Verbose', 1 ...
%         );
%     CVLinear = crossval(modelLinear);
%     errLinear = kfoldLoss(CVLinear);
%     
%     modelPoly = fitcsvm(features, pos, ...
%         'Standardize', true, ...
%         'kernelfunction', 'gaussian',...
%         'KernelScale', 'auto',...
%         'Verbose', 1 ...
%         );
%     CVPoly = crossval(modelPoly);
%     errPoly = kfoldLoss(CVPoly);
%     
%     fprintf('errGaussian: %f, errLinear: %f, errPoly: %f',...
%         errGaussian, errLinear, errPoly);
%    
%     kernel = 'gaussian';
%     if errLinear <= errGaussian && errLinear <= errPoly
%         kernel = 'linear';
%     end
%     if errPoly <= errGaussian && errPoly <= errLinear
%         kernel = 'polynomial';
%     end
    model = fitcecoc(features, pos);
    err = resubLoss(model);
%     err = computeRMSE(model.resubPredict, pos);
    % Plot the prediction result
    figure;
    scatter(pos, model.resubPredict);
    legend('Response in Training data', 'location', 'best');
end