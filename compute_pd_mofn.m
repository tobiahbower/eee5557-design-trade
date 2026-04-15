function Pd = compute_pd_mofn(SNR_dB, Pfa, M, N)
% Computes Probability of Detection (Pd) for M-of-N detector
% using noncoherent integration assumption

% Convert SNR to linear
SNR = 10^(SNR_dB/10);

% Step 1: Single-pulse Pd using noncoherent detection approximation
% (square-law detector, Gaussian approx)
gamma = -log(Pfa); % threshold (normalized)
Pd_single = exp(-gamma / (1 + SNR));

% Step 2: M-of-N detection (binomial sum)
Pd = 0;
for k = M:N
    Pd = Pd + nchoosek(N,k) * Pd_single^k * (1 - Pd_single)^(N-k);
end
end