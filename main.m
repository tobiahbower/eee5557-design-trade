clc; clear; close all;

[const, radar, antn, MQ18, airboat, design, metrics, des_idx] = base_design();

results.altitude     = trade_altitude(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.tau          = trade_tau(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.psi          = trade_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.power        = trade_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.system       = trade_system(const, radar, antn, MQ18, airboat, design, metrics, des_idx);

[results.twarn_psi, metrics]    = trade_twarn_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.pd_psi       = trade_pd_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.snr_psi      = trade_snr_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.tcn_power    = trade_tcn_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.pd_tau       = trade_pd_vs_tau(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.pd_power     = trade_pd_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx);
results.pd_nom       = trade_pd_nom_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx);

[metrics, results.design_iteration, R_bore, R_near, R_far, psi_far, psi, radar] = run_design_iteration(const, radar, antn, MQ18, airboat, design, metrics, des_idx);

save('trade_study_results.mat', 'results');
disp('All trade studies completed and saved.');
printout_design;
gen_xlsx;
plot_design;


function [const, radar, antn, MQ18, airboat, design, metrics, des_idx] = base_design()
    % Input: freq, alt, boresight grazing, Ant 0.75m, Pt=1500W, Tau=0.1us, Tfa=100s, 3 spins
    % Output: max PRF<500kHz, spin<180rpm, Pd_single>0.1 — iterate until specs met
    const.c = 3e8;
    const.k = 1.38e-23;

    MQ18.ALTITUDE = 6000;
    MQ18.MAX_SPEED = 37.5514;               % m/s

    des_idx = 2;

    radar.scan_az = 30;
    radar.TX_freq = [37e9 90e9 150e9];
    radar.TX_power_ours = 450;
    radar.TX_power = 450;
    radar.PRF = 5e5;
    radar.Tau = 0.03e-6;
    radar.Tsys = [400 500 700];
    radar.PCR = radar.Tau / 0.03e-6;
    radar.TX_power_comp = radar.TX_power_ours * radar.PCR;
    radar.Tfa = 100;                        % sec
    radar.Pfa = 1e-6;
    radar.PRF_doppler = 2e5; % Hz
    radar.Tau_doppler = 0.5;
    radar.simul_detect = 'N';

    antn.del = 0.3;
    antn.daz = 0.3;
    antn.aperture_eff = 0.6;

    radar.lambda = const.c / radar.TX_freq(des_idx);

    antn.HPBW_Bel = 1.2*radar.lambda/antn.del;    % rad
    antn.HPBW_Baz = 1.2*radar.lambda/antn.daz;    % rad
    antn.BW = 1/radar.Tau;                  % -3dB bandwidth

    antn.G = antn.aperture_eff * 4*pi / (antn.HPBW_Bel * antn.HPBW_Baz);

    design.scans = 3;
    design.boresight = 20; % deg

    airboat.MIN_SPEED = 50*1000/3600;
    airboat.MAX_SPEED = 170*1000/3600;

    % Time on target per scan (from antenna beamwidth and spin rate)
    antn.rpm = 100;                                    % your chosen spin rate
    Tspin = 60 / antn.rpm;                             % seconds per full rotation
    metrics.TOT = (antn.HPBW_Baz / (2*pi)) * Tspin;      % time beam dwells on target
    metrics.swath = 0;
    metrics.twarn = 0;


    % Doppler
    lambda = const.c / radar.TX_freq(des_idx);
    psi    = design.boresight;   % degrees
    
    V_UAV    = MQ18.MAX_SPEED;          % 37.55 m/s
    V_t_max  = airboat.MAX_SPEED;       % 170 km/h = 47.2 m/s
    V_t_min  = airboat.MIN_SPEED;       % 50 km/h = 13.9 m/s
    
    % Scenario 1: max target speed, az=0 (closing head-on — max fd)
    fd1 = compute_doppler(V_UAV, V_t_max,   0, psi, lambda);
    
    % Scenario 2: max target speed, az=180 (moving directly away — min fd)
    fd2 = compute_doppler(V_UAV, V_t_max, 180, psi, lambda);
    
    % Scenario 3: max target speed, az=±60 (edge of scan)
    fd3 = compute_doppler(V_UAV, V_t_max,  60, psi, lambda);
    
    % Scenario 4: min target speed, az=0 (along-track, minimum speed)
    fd4 = compute_doppler(V_UAV, V_t_min,   0, psi, lambda);
    
    fprintf('Scenario 1 (max speed, head-on):    fd = %.1f Hz\n', fd1);
    fprintf('Scenario 2 (max speed, away):       fd = %.1f Hz\n', fd2);
    fprintf('Scenario 3 (max speed, az=60 deg):  fd = %.1f Hz\n', fd3);
    fprintf('Scenario 4 (min speed, head-on):    fd = %.1f Hz\n', fd4);
end


function [TCN_dB, TC_dB, TN_dB] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx)
    sigma_t = rcs_airboat(rad2deg(psi));
    sigma_c = rcs_wetland(rad2deg(psi));   % this should return σ⁰ (reflectivity), not total RCS
    
    L = 1;
    
    Pr = (radar.TX_power_comp * antn.G^2 * lambda^2 * sigma_t) / ((4*pi)^3 * R^4 * L);
    
    Bn = 1 / radar.Tau;
    Pn = const.k * radar.Tsys(des_idx) * Bn;
    
    % === FIXED CLUTTER AREA ===
    % A_cell = R^2 * antn.HPBW_Baz * (antn.HPBW_Bel / sin(psi));   % <--- this was the bug
    % Range dimension of clutter cell: pulse-limited (correct)
    delta_R = (const.c * radar.Tau) / 2;
    R_cell  = min(delta_R, R * antn.HPBW_Bel / sin(psi));
    A_cell  = R * antn.HPBW_Baz * R_cell;   % NOT R^2*HPBW_az*HPBW_el/sin
    
    Pc = (radar.TX_power_comp * antn.G^2 * lambda^2 * sigma_c * A_cell) / ((4*pi)^3 * R^4 * L);
    
    TCN_dB = 10*log10(Pr / (Pc + Pn));
    TC_dB  = 10*log10(Pr / Pc);
    TN_dB  = 10*log10(Pr / Pn);
end


function tbl = trade_altitude(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_tau(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_system(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    PRFs = linspace(1e4,15e5,100);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for prf = PRFs
        radar.PRF = prf;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        N = max(1, round(radar.PRF * metrics.TOT));
        Pd = pd_albersheim_multipulse(TCN, N, radar.Pfa);
        results = [results; prf, TCN, Pd];
    end
    tbl = array2table(results,'VariableNames',{'PRF','TCN_dB','Pd'});
end


function T_warn = compute_twarn(R, Vrel),  T_warn = R / Vrel;  end
function [PRF_max, metrics] = compute_prf_max(Rmax, const, metrics),  PRF_max = const.c / (2 * Rmax); metrics.POT = PRF_max * metrics.TOT;  end


function [tbl, metrics] = trade_twarn_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    psis   = deg2rad(linspace(2,50,50));
    h      = MQ18.ALTITUDE;
    Az_max = deg2rad(radar.scan_az / 2);   % half the az scan width

    results = [];
    for psi = psis
        R      = h / sin(psi);
        R_warn = R * cos(Az_max);           % worst case at edge of scan

        % Worst-case closing: target moving directly toward UAV (az=180 deg)
        Vrel   = MQ18.MAX_SPEED - airboat.MAX_SPEED * cos(deg2rad(180));

        T_warn = R_warn / Vrel;
        if T_warn >= metrics.twarn
            metrics.twarn = T_warn;
        end
        results = [results; rad2deg(psi), T_warn];
    end
    tbl = array2table(results, 'VariableNames', {'Psi_deg','Twarn_sec'});
end

function tbl = trade_pd_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    psis = deg2rad(linspace(2,50,50));  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for psi = psis
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        N = max(1, round(radar.PRF * metrics.TOT));
        Pd = pd_albersheim_multipulse(TCN, N, radar.Pfa);
        results = [results; rad2deg(psi), Pd];
    end
    tbl = array2table(results,'VariableNames',{'Psi_deg','Pd'});
end

function tbl = trade_snr_vs_psi(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_tcn_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
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

function tbl = trade_pd_vs_tau(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    taus = linspace(0.02e-6,0.2e-6,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for tau = taus
        radar.Tau = tau;  radar.PCR = tau/0.08e-6;  radar.TX_power_comp = radar.TX_power*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        N = max(1, round(radar.PRF * metrics.TOT));
        Pd = pd_albersheim_multipulse(TCN, N, radar.Pfa);
        results = [results; tau, Pd];
    end
    tbl = array2table(results,'VariableNames',{'Tau','Pd'});
end

function tbl = trade_pd_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    powers = linspace(1,500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        N = max(1, round(radar.PRF * metrics.TOT));
        Pd = pd_albersheim_multipulse(TCN, N, radar.Pfa);
        results = [results; Pt, Pd];
    end
    tbl = array2table(results,'VariableNames',{'Power','Pd'});
end

function tbl = trade_pd_nom_vs_power(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    powers = linspace(1,500,40);  psi = deg2rad(design.boresight);  h = MQ18.ALTITUDE;
    lambda = const.c / radar.TX_freq(des_idx);
    results = [];
    for Pt = powers
        radar.TX_power = Pt;  radar.TX_power_comp = Pt*radar.PCR;
        R = h / sin(psi);
        [TCN,~,~] = evaluate_point(radar, antn, const, R, psi, lambda, des_idx);
        N_pulses = max(1, round(radar.PRF * metrics.TOT));
        Pd_single_scan = pd_albersheim_multipulse(TCN, N_pulses, radar.Pfa);
        
        % Cumulative Pd: 2-of-3 scans (per spec requirement)
        Pd_cum = 0;
        for k = 2:3
            Pd_cum = Pd_cum + nchoosek(3,k) * Pd_single_scan^k * (1 - Pd_single_scan)^(3-k);
        end
        results = [results; Pt, Pd_single_scan, Pd_cum];
    end
    tbl = array2table(results,'VariableNames',{'Power','Pd_single','Pd_2of3'});
end


function [metrics, R_bore, R_near, R_far, psi_far, psi] = evaluate_design(const, radar, antn, MQ18, metrics, des_idx)
    lambda = const.c / radar.TX_freq(des_idx);
    psi      = radar.psi_bore;
    h        = MQ18.ALTITUDE;

    psi_near = psi + antn.HPBW_Bel/2;
    psi_far  = psi - antn.HPBW_Bel/2;
    R_near   = h / sin(psi_near);
    R_bore   = h / sin(psi);
    R_far    = h / sin(psi_far);

    % Swath width on ground
    Rg_near       = R_near * cos(psi_near);
    Rg_far        = R_far  * cos(psi_far);
    swath = (Rg_far - Rg_near);   % convert to km to compare against 10 km spec
    if (swath >= metrics.swath)
        metrics.swath = swath;
    end
    metrics.swath_ok = metrics.swath >= 10000;

    % PRF max constraint (single pulse on surface at far range)
    PRF_max = const.c / (2 * R_far);

    % Time/pulses on target
    rpm          = 100;
    Tspin        = 60 / rpm;
    metrics.TOT  = (antn.HPBW_Baz / (2*pi)) * Tspin;
    metrics.POT  = radar.PRF * metrics.TOT;
    N            = max(1, round(metrics.POT));

    % TCN at all three ranges
    [TCN_bore, ~, ~] = evaluate_point(radar, antn, const, R_bore, psi,      lambda, des_idx);
    [TCN_near, ~, ~] = evaluate_point(radar, antn, const, R_near, psi_near, lambda, des_idx);
    [TCN_far,  ~, ~] = evaluate_point(radar, antn, const, R_far,  psi_far,  lambda, des_idx);

    % Single-scan Pd at each range
    Pd_bore_single = pd_albersheim_multipulse(TCN_bore, N, radar.Pfa);
    Pd_near_single = pd_albersheim_multipulse(TCN_near, N, radar.Pfa);
    Pd_far_single  = pd_albersheim_multipulse(TCN_far,  N, radar.Pfa);

    % Cumulative Pd(2-of-3 scans) at each range
    n_scans  = 3;
    m_detect = 2;
    Pd_bore = 0; Pd_near = 0; Pd_far = 0;
    for k = m_detect:n_scans
        c        = nchoosek(n_scans, k);
        Pd_bore  = Pd_bore + c * Pd_bore_single^k * (1 - Pd_bore_single)^(n_scans - k);
        Pd_near  = Pd_near + c * Pd_near_single^k * (1 - Pd_near_single)^(n_scans - k);
        Pd_far   = Pd_far  + c * Pd_far_single^k  * (1 - Pd_far_single)^(n_scans - k);
    end

    % Store metrics
    metrics.PRF_max    = PRF_max;
    metrics.spin_rpm   = rpm;
    metrics.TCN_bore   = TCN_bore;
    metrics.TCN_near   = TCN_near;
    metrics.TCN_far    = TCN_far;
    metrics.Pd_bore    = Pd_bore;
    metrics.Pd_near    = Pd_near;
    metrics.Pd_far     = Pd_far;
    metrics.Pd         = Pd_far;        % worst case for pass/fail
    metrics.PRF_ok     = PRF_max <= 5e5;
    metrics.spin_ok    = rpm <= 180;
    metrics.Pd_ok      = Pd_far >= 0.80;
end


function [metrics, results, R_bore, R_near, R_far, psi_far, psi, radar] = run_design_iteration(const, radar, antn, MQ18, airboat, design, metrics, des_idx)
    psis = deg2rad(5:2:30);  powers = linspace(50,500,10);
    results = [];
    for psi = psis
        radar.psi_bore = psi;
        for Pt = powers
            radar.TX_power = Pt;  radar.TX_power_comp = Pt * radar.PCR;

            [metrics, R_bore, R_near, R_far, psi_far, psi] = evaluate_design(const, radar, antn, MQ18, metrics, des_idx);
            
            % Psi, Pt, PRF_max, RPM, Pd, PRF_ok, RPM_ok, Pd_ok
            results = [results; rad2deg(psi), Pt, metrics.PRF_max, metrics.spin_rpm, ...
                       metrics.Pd, metrics.PRF_ok, metrics.spin_ok, metrics.Pd_ok];
        end
    end
end


function fd = compute_doppler(V_UAV, V_target, az_target_deg, psi_deg, lambda)
    psi = deg2rad(psi_deg);
    az  = deg2rad(az_target_deg);

    % Radial velocity: UAV component + target component projected onto LOS
    V_UAV_radial    =  V_UAV    * cos(psi);           % UAV along-track projected to slant
    V_target_radial =  V_target * cos(psi) * cos(az); % target projected to slant range

    Vr = V_UAV_radial - V_target_radial;

    fd = (2 / lambda) * Vr;
end