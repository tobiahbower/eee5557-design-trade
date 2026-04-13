
fprintf('\n============================================================\n');
fprintf('              RADAR DESIGN PARAMETERS CHOICES\n');
fprintf('============================================================\n');

fprintf('%-45s %-20s\n', 'Description', 'Proposed Value');
fprintf('%s\n', repmat('-',1,70));

fprintf('%-45s %-20s\n', '01. Radar Freq', sprintf('%.2f GHz', radar.TX_freq(des_idx)/1e9));

fprintf('%-45s %-20s\n', '02. UAV Altitude', sprintf('%.2f km', MQ18.ALTITUDE/1000));

% grazing angle
fprintf('%-45s %-20s\n', '03. Ant.boresight grazing ang', ...
    sprintf('%.2f deg', design.boresight));

fprintf('%-45s %-20s\n', '04. Ant diameter elevation', sprintf('%.2f m', antn.del));

fprintf('%-45s %-20s\n', '05. Ant diameter azimuth', sprintf('%.2f m', antn.daz));

fprintf('%-45s %-20s\n', '06. Ant spin rate', sprintf('%.2f rpm', metrics.spin_rpm));

az_res = R_bore * antn.HPBW_Baz;
fprintf('%-45s %-20s\n', '07. Ant Az Limit (+/- deg active radar meas)', sprintf('%.2f deg', az_res));

fprintf('%-45s %-20s\n', '08. Xmtr Pwr', sprintf('%.1f W', radar.TX_power));

fprintf('%-45s %-20s\n', '09. Xmt pulse width', sprintf('%.2f us', radar.Tau*1e6));

fprintf('%-45s %-20s\n', '10. PRF', sprintf('%.1f Hz', radar.PRF));

fprintf('%-45s %-20s\n', '11. Avg Tfa', sprintf('%.2f sec', radar.Tfa));

fprintf('%-45s %-20s\n', '12. No. fore-looking scans tgt is tracked', sprintf('%d', 0));
fprintf('%-45s %-20s\n', '13. PCR (>=1.0)', sprintf('%.2f', radar.PCR));


fprintf('%-45s %-20s\n', '1. Fwd-look POT/scan used for detection', sprintf('%d #', 0));
fprintf('%-45s %-20s\n', '2. worst case # scans on target = N', sprintf('%d', design.scans));
fprintf('%-45s %-20s\n', '3. Doppler-mode PRF', sprintf('%.1f Hz', radar.PRF_doppler));
fprintf('%-45s %-20s\n', '4. Xmtr duty cycle Doppler-mode', sprintf('%.1f Hz', radar.Tau_doppler));
fprintf('%-45s %-20s\n', '5. (Tdetect/scan)/(TOT/scan)', sprintf('%.1f ratio', 0));


fprintf('%-45s %-20s\n', 'Simultaneous Target detection?', radar.simul_detect);   % should be 'Y' or 'N'



fprintf("\n\n================ RADAR PERFORMANCE ACHIEVED ================\n");
fprintf("%-55s %-20s\n", "Metric", "Value");
fprintf("--------------------------------------------------------------------------\n");

fprintf("%-55s %-20s\n", "Operation Mode", "Sequential");

fprintf("%-55s %-20.2f deg\n", "Minimum grazing angle", rad2deg(psi_far));

fprintf("%-55s %-20.2f\n", "Rnear (m)", R_near);

fprintf("%-55s %-20.2f\n", "Rbore (m)", R_bore);

fprintf("%-55s %-20.2f\n", "Rfar (m)", R_far);

fprintf("%-55s %-20.2f rpm\n", "Min antenna spin rate", metrics.spin_rpm);

fprintf("%-55s %-20.2f deg\n", "Az scan limit (+/-) wrt fore-look", rad2deg(antn.HPBW_Baz/2));

fprintf("%-55s %-20.6f sec\n", "Minimum warning time", metrics.TOT); % want this to be high

fprintf("%-55s %-20.3f km\n", "Swath width", metrics.swath/1000);

range_res = const.c * radar.Tau / 2;
fprintf("%-55s %-20.2f m\n", "Range resolution", range_res);

fprintf("%-55s %-20.2f m\n", "Azimuth resolution", az_res);

fprintf("%-55s %-20.3f\n", "Duty cycle (Detection)", radar.Tau);

fprintf("%-55s %-20.3f\n", "Duty cycle (Doppler)", radar.Tau);

sigma_t_bore = rcs_airboat(rad2deg(psi));
sigma_c_bore = rcs_wetland(rad2deg(psi));

fprintf("%-55s %-20.3f m^2\n", "Target RCS @ boresight", sigma_t_bore);

fprintf("%-55s %-20.3f m^2\n", "Clutter RCS @ boresight", sigma_c_bore);

fprintf("%-55s %-20.2f pulses\n", "Pulses on target (POT)", round(metrics.POT));

X = (radar.TX_power * antn.G^2 * radar.lambda^2) / ((4*pi)^3);
fprintf("%-55s %-20.2f dB\n", "Radar equation constant X", 10*log10(X));

fprintf("%-55s %-20.2f dB\n", "T/(C+N) @ boresight", results.tcn_power.TCN_dB(numel(results.tcn_power.TCN_dB)/2));

fprintf("%-55s %-20.3f\n", "Pd @ boresight", results.pd_psi.Pd(numel(results.pd_psi.Pd)/2));

fd_max = (2 * airboat.MAX_SPEED) / radar.lambda;

fprintf("%-55s %-20.2f Hz\n", "Max Doppler @ boresight", fd_max);

fprintf("%-55s %-20.6f sec\n", "Doppler TOT", metrics.TOT);

% fprintf("%-55s %-20.2f Hz\n", "Doppler precision", delta_fd_max);


fprintf("\n\n================ SPECIFICATION COMPLIANCE MATRIX =====================\n");
fprintf("%-45s %-15s %-15s %-15s\n", ...
    "Metric", "Proposed", "Spec", "Margin");
fprintf("-------------------------------------------------------------------------------\n");

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Transmit Power (W)", radar.TX_power, 1500, 1500 - radar.TX_power);

fprintf("%-45s %-15.3f %-15.3f %-15.3f\n", ...
    "Duty Cycle (Detect)", radar.Tau, 0.10, 0.10 - radar.Tau);

fprintf("%-45s %-15.3f %-15.3f %-15.3f\n", ...
    "Duty Cycle (Doppler)", radar.Tau, 0.20, 0.20 - radar.Tau);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Grazing Angle @ Far (deg)", rad2deg(psi_far), 2, rad2deg(psi_far) - 2);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Az Dimension (m)", antn.daz, 1.2, 1.2 - antn.daz);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "El Dimension (m)", antn.del, 1.2, 1.2 - antn.del);

fprintf("%-45s %-15.3f %-15.2f %-15.3f\n", ...
    "Swath (km)", metrics.swath/1000, 10, (metrics.swath/1000) - 10);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Spin Rate (rpm)", metrics.spin_rpm, 180, 180 - metrics.spin_rpm);

fprintf("%-45s %-15d %-15d %-15d\n", ...
    "Number of Scans", design.scans, 3, design.scans - 3);

fprintf("%-45s %-15.0f %-15.0f %-15.0f\n", ...
    "PRF (Hz)", radar.PRF, 5e5, 5e5 - radar.PRF);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Range Resolution (m)", range_res, 6, range_res - 6);

fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
    "Az Resolution (m)", az_res, 6, az_res - 6);

Tspin = 60 / metrics.spin_rpm;

fprintf("%-45s %-15.4f %-15.4f %-15.4f\n", ...
    "Warning Time (sec)", metrics.twarn, 6, metrics.twarn - 6);

fprintf("%-45s %-15.3f %-15.3f %-15.3f\n", ...
    "Pd (worst case)", metrics.Pd_far, 0.80, metrics.Pd_far - 0.80);

% fprintf("%-45s %-15.2f %-15.2f %-15.2f\n", ...
%     "Doppler Precision (Hz)", delta_fd_max, 700, 700 - delta_fd_max);