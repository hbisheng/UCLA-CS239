% Process one component.
% x: the input vector.
% freq: the frequence of the input vector (sample/second)
function y = filter_one_component(x, freq, draw)
%     x_normed = normalize_z_score(x);
%     window = floor(freq / 7);
%     x_avg = average_filter(x_normed, window);
%     y = x_avg;

    window = hamming(floor(freq / 7));
    x_avg = conv(x, window);    
    [b, a] = butter(1, [40, 180] / 60 / freq * 2);
    y = filter(b, a, x_avg);
    
    if 0
%         freqz(b, a);
        figure();
        subplot(2, 2, 1);
        plot(x);
        subplot(2, 2, 2);
        plot(x_normed);
        subplot(2, 2, 3);
        plot(x_avg);
        subplot(2, 2, 4);
        plot(y);
        pause
    end
end