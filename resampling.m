function [ resampled_data ] = resampling( time, data, sampling_rate)
    % perform resampling base on timestamps
    timestamps = time;
    timestamps = (timestamps - timestamps(1)) / 1000;

    origin_data = data;
    data_timeseries = timeseries(origin_data, timestamps);

    new_time = timestamps(1):(1/sampling_rate):timestamps(end);
    data_resampled = resample(data_timeseries, new_time);
    resampled_data = data_resampled.data;
end

