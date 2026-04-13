function Pd = pd_albersheim_multipulse(SNR1_dB, N, Pfa)
    A = log(0.62 / Pfa);

    Pd_vec = 0.01:0.001:0.999;
    snr_req = zeros(size(Pd_vec));

    for i = 1:length(Pd_vec)
        pd = Pd_vec(i);
        B = log(pd / (1 - pd));
        snr_req(i) = -5*log10(N) + 6.2 + (4.54 / sqrt(N + 0.44)) * log10(A + 0.12*A*B + 1.7*B);
    end

    [~, idx] = min(abs(snr_req - SNR1_dB));
    Pd = Pd_vec(idx);

end