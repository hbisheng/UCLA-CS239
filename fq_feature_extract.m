% Extract some basic frequence domain features for training.
% The fft at [0 ~ 180] Hz.
% data: each row is a sample.
% fs: the sampling frequence.
function fq_feature = fq_feature_extract(data, fs)
    Y = fft(data')';
    L = size(data, 2);
    P2 = abs(Y / L);
    P1 = P2(:, 1 : L/2+1);
    P1(:, 2:end-1) = 2*P1(:, 2:end-1);
    f = 60 * fs * (0:(L/2))/L;
    fq_feature = P1(:, f <= 180);
%     fq_feature = zeros(size(data, 1), 181);
%     for row = 1:size(data, 1)
%         row_data = timeseries(P1(row, :), f);
%         fq_feature(row, :) = resample(row_data, 0:180);
%     end
end