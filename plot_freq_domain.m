function [] = plot_freq_domain( signal , freq )
    % Take the FFT.
    L = length(signal);
    Y = fft(signal);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = freq*(0:(L/2))/L;
    
    figure();
    plot(f * 60, P1);
    title(['Single-Sided Amplitude Spectrum of S(t)'])
    xlabel('f (times/second)')
    ylabel('|P1(f)|') 
end

