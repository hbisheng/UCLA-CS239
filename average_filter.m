% Take the average of x.
% x: the input samples.
% samples: the number of samples in the buffer.
function y = average_filter(x, samples)
    persistent buffer;
    if isempty(buffer)
        buffer = zeros(samples,1);
    end
    y = zeros(size(x), class(x));
    for i = 1:numel(x)
        % Scroll the buffer
        buffer(2:end) = buffer(1:end-1);
        % Add a new sample value to the buffer
        buffer(1) = x(i);
        % Compute the current average value of the window and
        % write result
        y(i) = sum(buffer)/numel(buffer);
    end
end