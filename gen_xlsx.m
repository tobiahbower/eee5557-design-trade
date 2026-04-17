%% ===================== EXPORT TO EXCEL =====================

filename = 'radar_design_output.xlsx';

%% -------- DESIGN PARAMETERS --------
param_names = {
    'Radar Frequency (Hz)'
    'Altitude (km)'
    'Boresight Grazing Angle (deg)'
    'Antenna Elevation Diameter (m)'
    'Antenna Azimuth Diameter (m)'
    'Spin Rate (rpm)'
    'Scan Azimuth (deg)'
    'Transmit Power (W)'
    'Pulse Width (us)'
    'PRF (Hz)'
    'Pulse Compression Ratio'
};

param_values = [
    radar.TX_freq(des_idx)
    MQ18.ALTITUDE/1000
    design.boresight
    antn.del
    antn.daz
    antn.rpm
    radar.scan_az
    radar.TX_power_ours
    radar.Tau*1e6
    radar.PRF
    radar.PCR
];

T_params = table(param_names, param_values);

%% -------- PERFORMANCE METRICS --------
metric_names = {
    'Swath Width (km)'
    'Rnear (m)'
    'Rbore (m)'
    'Rfar (m)'
    'Range Resolution (m)'
    'Azimuth Resolution (m)'
    'Pulses on Target (POT)'
    'Pd (Boresight)'
    'T/(C+N) (dB)'
    'Doppler Precision (Hz)'
};

metric_values = [
    metrics.swath/1000
    R_near
    R_bore
    R_far
    range_res
    az_res
    metrics.POT
    metrics.Pd_bore
    metrics.TCN_bore
    0; %delta_fd_max
];

T_metrics = table(metric_names, metric_values);

%% -------- WRITE TO EXCEL --------
writetable(T_params, filename, 'Sheet', 'Design Parameters');
writetable(T_metrics, filename, 'Sheet', 'Performance Metrics');

disp(['Excel file created: ', filename]);