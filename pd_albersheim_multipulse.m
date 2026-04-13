function Pd = pd_albersheim_multipulse(SNR1_dB, N, Pfa)
% Compute Pd using Albersheim's multi-pulse approximation (no toolbox needed)
% Inputs:
%   SNR1_dB : Single-pulse SNR in dB
%   N       : Number of noncoherently integrated pulses (pulses on target)
%   Pfa     : Probability of false alarm (e.g., 1e-6)
% Output:
%   Pd      : Probability of detection
%
% Valid range: 0.1 <= Pd <= 0.9, 1e-7 <= Pfa <= 1e-3, 1 <= N <= 8096
% Test case (slide 62): SNR1_dB=13, N=10, Pfa=1e-6 --> Pd ~ 0.9

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