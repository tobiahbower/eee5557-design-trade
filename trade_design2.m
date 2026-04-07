clc; clear; close all;

[const, radar, antn, MQ18, airboat, design, des_idx] = base_design();

results.altitude     = trade_altitude(const, radar, antn, MQ18, airboat, design, des_idx);
results.tau          = trade_tau(const, radar, antn, MQ18, airboat, design, des_idx);
results.psi          = trade_psi(const, radar, antn, MQ18, airboat, design, des_idx);
results.power        = trade_power(const, radar, antn, MQ18, airboat, design, des_idx);
results.system       = trade_system(const, radar, antn, MQ18, airboat, design, des_idx);

results.twarn_psi    = trade_twarn_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx);
results.pd_psi       = trade_pd_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx);
results.snr_psi      = trade_snr_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx);
results.tcn_power    = trade_tcn_vs_power(const, radar, antn, MQ18, airboat, design, des_idx);
results.pd_tau       = trade_pd_vs_tau(const, radar, antn, MQ18, airboat, design, des_idx);
results.pd_power     = trade_pd_vs_power(const, radar, antn, MQ18, airboat, design, des_idx);
results.pd_nom       = trade_pd_nom_vs_power(const, radar, antn, MQ18, airboat, design, des_idx);

[metrics, results.design_iteration, R_bore, R_near, R_far, psi_far, psi] = run_design_iteration(const, radar, antn, MQ18, airboat, design, des_idx);

save('trade_study_results.mat', 'results');
disp('All trade studies completed and saved.');
printout_design;
gen_xlsx;
plot_design;


function [const, radar, antn, MQ18, airboat, design, des_idx] = base_design()
    % Input: freq, alt, boresight grazing, Ant 0.75m, Pt=1500W, Tau=0.1us, Tfa=100s, 3 spins
    % Output: max PRF<500kHz, spin<180rpm, Pd_single>0.1 — iterate until specs met
    const.c = 3e8;
    const.k = 1.38e-23;

    MQ18.ALTITUDE = 6000;
    MQ18.MAX_SPEED = 37.5514;               % m/s

    des_idx = 1;

    radar.scan_az = 30;
    radar.TX_freq = [37e9 90e9 150e9];
    radar.TX_power = 1500;
    radar.PRF = 5e5;
    radar.Tau = 0.1e-6;
    radar.Tsys = [400 500 700];
    radar.PCR = radar.Tau / 0.08e-6;
    radar.TX_power_comp = radar.TX_power * radar.PCR;
    radar.Tfa = 100;                        % sec
    radar.Pfa = 1e-6;
    radar.PRF_doppler = 2e5; % Hz
    radar.duty_cycle_doppler = 0.5;
    radar.simul_detect = 'N';

    antn.del = 0.75;
    antn.daz = 0.75;
    antn.aperture_eff = 0.6;

    radar.lambda = const.c / radar.TX_freq(des_idx);

    antn.HPBW_Bel = 1.2*radar.lambda/antn.del;    % rad
    antn.HPBW_Baz = 1.2*radar.lambda/antn.daz;    % rad
    antn.BW = 1/radar.Tau;                  % -3dB bandwidth

    antn.G = antn.aperture_eff * 4*pi / (antn.HPBW_Bel * antn.HPBW_Baz);

    design.scans = 3;
    design.boresight = 30;

    airboat.MIN_SPEED = 50*1000/3600;
    airboat.MAX_SPEED = 170*1000/3600;
end


function [TCN_dB, TC_dB, TN_dB] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx)
    sigma_t = rcs_airboat(rad2deg(psi));
    sigma_c = rcs_wetland(rad2deg(psi));   % this should return σ⁰ (reflectivity), not total RCS
    
    L = 1;
    
    Pr = (radar.TX_power_comp * antn.G^2 * lambda^2 * sigma_t) / ((4*pi)^3 * R^4 * L);
    
    Bn = 1 / radar.Tau;
    Pn = const.k * radar.Tsys(des_idx) * Bn;
    
    % === FIXED CLUTTER AREA ===
    A_cell = R^2 * antn.HPBW_Baz * (antn.HPBW_Bel / sin(psi));   % <--- this was the bug
    
    Pc = (radar.TX_power_comp * antn.G^2 * lambda^2 * sigma_c * A_cell) / ((4*pi)^3 * R^4 * L);
    
    TCN_dB = 10*log10(Pr / (Pc + Pn));
    TC_dB  = 10*log10(Pr / Pc);
    TN_dB  = 10*log10(Pr / Pn);
end


function tbl = trade_altitude(const, radar, antn, MQ18, airboat, design, des_idx)
    alts = linspace(3000,10000,40);  psi = deg2rad(design.boresight);
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for h = alts
        R = h / sin(psi);
        [TCN, TC, TN] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; h, TCN, TC, TN];
    end
    tbl = array2table(results,'VariableNames',{'Altitude','TCN_dB','TC_dB','TN_dB'});
end

function tbl = trade_tau(const, radar, antn, MQ18, airboat, design, des_idx)
    taus = linspace(0.02e-6,0.5e-6,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for tau = taus
        radar.Tau = tau;  radar.PCR = tau/0.08e-6;  radar.TX_power_comp = radar.TX_power*radar.PCR;
        R = h / sin(psi);
        [TCN, TC, TN] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; tau, TCN, TC, TN];
    end
    tbl = array2table(results,'VariableNames',{'Tau','TCN_dB','TC_dB','TN_dB'});
end

function tbl = trade_psi(const, radar, antn, MQ18, airboat, design, des_idx)
    psis = deg2rad(linspace(2,30,50));  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for psi = psis
        R = h / sin(psi);
        [TCN, TC, TN] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; rad2deg(psi), TCN, TC, TN];
    end
    tbl = array2table(results,'VariableNames',{'Psi_deg','TCN_dB','TC_dB','TN_dB'});
end

function tbl = trade_power(const, radar, antn, MQ18, airboat, design, des_idx)
    powers = linspace(1,1500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN, TC, TN] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; Pt, TCN, TC, TN];
    end
    tbl = array2table(results,'VariableNames',{'Power','TCN_dB','TC_dB','TN_dB'});
end

function tbl = trade_system(const, radar, antn, MQ18, airboat, design, des_idx)
    PRFs = linspace(1e4,5e5,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for prf = PRFs
        radar.PRF = prf;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        POT = prf * 0.01;                       % simplified dwell
        Pd = pd_from_snr(radar.Pfa, TCN, POT);
        results = [results; prf, TCN, Pd];
    end
    tbl = array2table(results,'VariableNames',{'PRF','TCN_dB','Pd'});
end


function T_warn = compute_twarn(R, Vrel),  T_warn = R / Vrel;  end
function PRF_max = compute_prf_max(Rmax, const),  PRF_max = const.c / (2 * Rmax);  end


function tbl = trade_twarn_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx)
    psis = deg2rad(linspace(2,50,50));  h = MQ18.ALTITUDE;
    results = [];
    for psi = psis
        R = h / sin(psi);
        Vrel = MQ18.MAX_SPEED - airboat.MAX_SPEED * cos(180);  % worst case
        T_warn = compute_twarn(R, Vrel);
        results = [results; rad2deg(psi), T_warn];
    end
    tbl = array2table(results,'VariableNames',{'Psi_deg','Twarn_sec'});
end

function tbl = trade_pd_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx)
    psis = deg2rad(linspace(2,50,50));  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for psi = psis
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        POT = radar.PRF * 0.01;
        Pd = pd_from_snr(radar.Pfa, TCN, POT);
        results = [results; rad2deg(psi), Pd];
    end
    tbl = array2table(results,'VariableNames',{'Psi_deg','Pd'});
end

function tbl = trade_snr_vs_psi(const, radar, antn, MQ18, airboat, design, des_idx)
    psis = deg2rad(linspace(2,50,50));  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for psi = psis
        R = h / sin(psi);
        [TCN, TC, TN] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; rad2deg(psi), TCN, TC, TN];
    end
    tbl = array2table(results,'VariableNames',{'Psi_deg','TCN_dB','TC_dB','TN_dB'});
end

function tbl = trade_tcn_vs_power(const, radar, antn, MQ18, airboat, design, des_idx)
    powers = linspace(1,500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        results = [results; Pt, TCN];
    end
    tbl = array2table(results,'VariableNames',{'Power','TCN_dB'});
end

function tbl = trade_pd_vs_tau(const, radar, antn, MQ18, airboat, design, des_idx)
    taus = linspace(0.02e-6,0.2e-6,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for tau = taus
        radar.Tau = tau;  radar.PCR = tau/0.08e-6;  radar.TX_power_comp = radar.TX_power*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        POT = radar.PRF * 0.01;
        Pd = pd_from_snr(radar.Pfa, TCN, POT);
        results = [results; tau, Pd];
    end
    tbl = array2table(results,'VariableNames',{'Tau','Pd'});
end

function tbl = trade_pd_vs_power(const, radar, antn, MQ18, airboat, design, des_idx)
    powers = linspace(1,500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        POT = radar.PRF * 0.01;
        Pd = pd_from_snr(radar.Pfa, TCN, POT);
        results = [results; Pt, Pd];
    end
    tbl = array2table(results,'VariableNames',{'Power','Pd'});
end

function tbl = trade_pd_nom_vs_power(const, radar, antn, MQ18, airboat, design, des_idx)
    powers = linspace(1,500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);  N=2; M=4;
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        POT = radar.PRF * 0.01;
        Pd_single = pd_from_snr(radar.Pfa, TCN, POT);
        Pd_nom = 0;
        for k = N:M
            Pd_nom = Pd_nom + nchoosek(M,k) * Pd_single^k * (1-Pd_single)^(M-k);
        end
        results = [results; Pt, Pd_nom];
    end
    tbl = array2table(results,'VariableNames',{'Power','Pd_NofM'});
end


function [metrics, R_bore, R_near, R_far, psi_far, psi] = evaluate_design(const, radar, antn, MQ18, airboat, req, des_idx)
    lambda = const.c / radar.TX_freq(des_idx);
    psi = radar.psi_bore;  
    h = MQ18.ALTITUDE;
    R_far = h / sin(psi - antn.HPBW_Bel/2);
    R_bore = h / sin(psi);

    psi_near = psi + antn.HPBW_Bel/2;
    psi_far  = psi - antn.HPBW_Bel/2;
    R_near = h / sin(psi_near); % meters
    R_far  = h / sin(psi_far); % meters
    R_bore = h / sin(psi); % meters

    swath_angle = deg2rad(radar.scan_az);  % e.g., 90 deg total

    % Ground range at boresight (better than near)
    Rg_bore = R_bore * cos(psi);
    
    % Swath width on ground
    metrics.swath = 2 * Rg_bore * tan(swath_angle / 2);

    PRF_max = const.c / (2 * R_far);                    % single pulse on surface

    rpm = min(100, 180);                                % example choice (hardware limit)
    Tspin = 60 / rpm;
    metrics.TOT = (antn.HPBW_Baz / (2*pi)) * Tspin;
    metrics.POT = radar.PRF * metrics.TOT;

    [TCN,~,~] = evaluate_point(radar, antn, const, R_bore, psi, lambda, des_idx);
    Pd = pd_from_snr2(radar.Tau, TCN, radar.PRF*0.01);       % simplified

    metrics.PRF_max = PRF_max;
    metrics.spin_rpm = rpm;
    metrics.Pd = Pd;
    metrics.PRF_ok = PRF_max <= 5e5;
    metrics.spin_ok = rpm <= 180;
    metrics.Pd_ok = Pd >= 0.1;
end


function [metrics, results, R_bore, R_near, R_far, psi_far, psi] = run_design_iteration(const, radar, antn, MQ18, airboat, req, des_idx)
    psis = deg2rad(5:2:30);  powers = linspace(50,500,10);
    results = [];
    for psi = psis
        radar.psi_bore = psi;
        for Pt = powers
            radar.TX_power = Pt;  radar.TX_power_comp = Pt * radar.PCR;
            [metrics, R_bore, R_near, R_far, psi_far, psi] = evaluate_design(const, radar, antn, MQ18, airboat, req, des_idx);
            results = [results; rad2deg(psi), Pt, metrics.PRF_max, metrics.spin_rpm, ...
                       metrics.Pd, metrics.PRF_ok, metrics.spin_ok, metrics.Pd_ok];
        end
    end
end