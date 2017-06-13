% Process one component.
% x: the input vector.
% freq: the frequence of the input vector (sample/second)
function y = filter_one_component(x, freq)
    window = hamming(floor(freq / 7));
    x_avg = conv(x, window);    
    [b, a] = butter(1, [40, 180] / 60 / freq * 2);
    y = filter(b, a, x_avg);
end