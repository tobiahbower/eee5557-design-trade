function Pd = pd_from_snr2(Pfa, SNR_dB, n)
    % Stable Albersheim Pd calculation
    if SNR_dB > 40
        Pd = 1;
    elseif SNR_dB < -5
        Pd = 0;
    else
        SNR50 = albersheim(0.5, Pfa, n);           % SNR required for Pd=0.5
        z = (SNR_dB - SNR50) * 0.23 * n^0.08;      % tuned scaling
        Pd = 1 ./ (1 + exp(-z));
    end
end