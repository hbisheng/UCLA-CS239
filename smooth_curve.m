function [ data ] = smooth_curve( data )
    history_len = 20;
    for i = 1:length(data)
        if i > history_len 
            history_mean = mean(data(i-history_len:i-1));
            if abs(data(i) - history_mean) / history_mean > 0.1
                data(i) = history_mean + 3 * sign(data(i) - history_mean);
            end
        end
    end
    %mean([his data(i-1) + 4 * sign(data(i) - data(i-1))]);
end