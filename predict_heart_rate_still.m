function hr = predict_heart_rate_still(x, y, z, freq, draw)
    xx = filter_one_component(x, freq, draw);
    yy = filter_one_component(y, freq, draw);
    zz = filter_one_component(z, freq, draw);
    % Aggregate with sqrt(x^2 + y^2 + z^2).
    agg = sqrt(xx .^ 2 + yy .^ 2 + zz .^ 2);
    % Filter with band-pass 2nd butterworth
    % with cutoff frequence 0.66 to 2.5Hz.
    
    [b, a] = butter(1, [40, 180] / 60 / freq * 2);
    pulse = filter(b, a, agg);

%     pulse = agg;
    
    % Take the FFT.
    L = length(agg);
    Y = fft(pulse);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = freq*(0:(L/2))/L;
    
    hr = 0;
    tmp = P1;
    for cnt = 1:1
        [~, I] = max(tmp);
%         if 60 * f(I) > 180
%             tmp(I) = -Inf;
%             continue;
%         end
        hr = max(hr, 60 * f(I));
    end
    
    if draw
        figure();
        subplot(2, 1, 1);
        plot(agg);
        subplot(2, 1, 2);
        plot(pulse);
        
        figure();
        plot(f * 60, P1);
        title(['Single-Sided Amplitude Spectrum of S(t) HR:', num2str(hr)])
        xlabel('f (Hz)')
        ylabel('|P1(f)|') 
        pause
    end
end