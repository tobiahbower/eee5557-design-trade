function Pd = pd_from_snr(Pfa, SNR_dB, n)

SNR = 10^(SNR_dB/10);
A = log(0.62 / Pfa);
eps = 1 / (0.62 + 0.454 / sqrt(n + 0.44));
chi = (SNR * sqrt(n))^eps;
beta = (chi - A) / (0.12*A + 1.7);

Pd = exp(beta) / (1 + exp(beta));

end