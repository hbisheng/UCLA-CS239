function [rates_and_power, true_power] = predict_heart_rate_still(x, y, z, freq, draw, true_hr)
    xx = filter_one_component(x, freq, draw);
    yy = filter_one_component(y, freq, draw);
    zz = filter_one_component(z, freq, draw);
    % Aggregate with sqrt(x^2 + y^2 + z^2).
    agg = sqrt(xx .^ 2 + yy .^ 2 + zz .^ 2);
    % Filter with band-pass 2nd butterworth
    % with cutoff frequence 0.66 to 2.5Hz.
    
    [b, a] = butter(1, [40, 180] / 60 / freq * 2);
    pulse = filter(b, a, agg);
    
    % Take the FFT.
    L = length(agg);
    Y = fft(pulse);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = freq*(0:(L/2))/L;
    
    P1_temp = P1;
    
    top_num = 5;
    rates_and_power = zeros(top_num, 2);
    cnt = 1;
    while cnt <= top_num
        [power, I] = max(P1_temp);
        if 40 < 60 * f(I) && 60 * f(I) < 180 && power < 1
            rates_and_power(cnt, 1) = 60 * f(I);
            rates_and_power(cnt, 2) = power;
            cnt = cnt + 1;
        end
        P1_temp(I) = -Inf;
    end
    
    upper_bound = floor( (true_hr+3) * L / 60 / freq + 1);
    lower_bound = ceil( (true_hr-3) * L / 60 / freq + 1);
    true_power = max(P1(lower_bound:upper_bound));
    
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