load("trade_study_results.mat");
inputs = readtable("radar_design_output.xlsx");

figure;

subplot(4,3,1);
plot(results.altitude.Altitude, abs(results.altitude.TCN_dB), LineWidth=4, DisplayName='T/(C+N)');
hold on;
plot(results.altitude.Altitude, abs(results.altitude.TC_dB),  LineWidth=2, DisplayName='T/C');
plot(results.altitude.Altitude, abs(results.altitude.TN_dB),  LineWidth=2, DisplayName='T/N');
xlabel('Altitude (m)');
ylabel('Power Ratio Magnitude (dB)');
title('SNR vs UAV Altitude');
grid on;
xline(inputs.param_values(2)*1e3, DisplayName="Operating Pt"); % alttidue operatin point
legend;

% figure;
subplot(4,3,2);
plot(results.tau.Tau*1e6, abs(results.tau.TCN_dB), LineWidth=4, DisplayName='T/(C+N)');
hold on;
plot(results.tau.Tau*1e6, abs(results.tau.TC_dB),  LineWidth=2, DisplayName='T/C');
plot(results.tau.Tau*1e6, abs(results.tau.TN_dB),  LineWidth=2, DisplayName='T/N');
xlabel('Pulse Width \tau (\mus)');
ylabel('Power Ratio Magnitude (dB)');
title('SNR vs Pulse Width');
grid on;
xline(inputs.param_values(9), DisplayName="Operating Pt"); 
legend;


% figure;
subplot(4,3,3);
plot(results.psi.Psi_deg, abs(results.psi.TCN_dB), LineWidth=4, DisplayName='T/(C+N)');
hold on;
plot(results.psi.Psi_deg, abs(results.psi.TC_dB),  LineWidth=2, DisplayName='T/C');
plot(results.psi.Psi_deg, abs(results.psi.TN_dB),  LineWidth=2, DisplayName='T/N');
xlabel('Boresight Grazing Angle \psi (deg)');
ylabel('Power Ratio Magnitude (dB)');
title('SNR vs Boresight Grazing Angle');
grid on;
xline(inputs.param_values(3), DisplayName="Operating Pt")
legend;


% figure;
subplot(4,3,4);
plot(results.power.Power, abs(results.power.TCN_dB), LineWidth=4, DisplayName='T/(C+N)');
plot(results.power.Power, abs(results.power.TN_dB),  LineWidth=2, DisplayName='T/N');
hold on;
plot(results.power.Power, abs(results.power.TC_dB),  LineWidth=2, DisplayName='T/C');
xlabel('Transmit Power P_t (W)');
ylabel('Power Ratio Magnitude (dB)');
title('SNR vs Transmit Power');
grid on;
xline(inputs.param_values(8), DisplayName="Operating Pt")
legend;


% figure;
subplot(4,3,5);
plot(results.system.PRF/1e3, abs(results.system.TCN_dB), LineWidth=2, DisplayName='T/(C+N)');
xline(inputs.param_values(10)/1e3, DisplayName="Operating Pt")
legend;
xlabel('PRF (kHz)');
ylabel('T/(C+N) (dB)');
title('SNR vs PRF');
grid on;

subplot(4,3,6);
plot(results.system.PRF/1e3, abs(results.system.Pd), LineWidth=2, DisplayName='P_d');
xline(inputs.param_values(10)/1e3, DisplayName="Operating Pt")
legend;
xlabel('PRF (kHz)');
ylabel('P_d');
title('P_d vs PRF');
grid on;


% figure;
subplot(4,3,7);
plot(results.twarn_psi.Psi_deg, results.twarn_psi.Twarn_sec, LineWidth=2, DisplayName='T_{warn}');
yline(6, 'r--', DisplayName='Spec (6 s)', LineWidth=1.5);
yline(60, 'g--', DisplayName='Goal (60 s)', LineWidth=1.5);
xline(inputs.param_values(3), DisplayName="Operating Pt")
legend;
xlabel('Boresight Grazing Angle \psi (deg)');
ylabel('T_{warn} (s)');
title('Warning Time vs Grazing Angle');
grid on;


% figure;
subplot(4,3,8);
plot(results.pd_psi.Psi_deg, results.pd_psi.Pd, LineWidth=2, DisplayName='P_d');
yline(0.80, 'r--', DisplayName='Spec (0.80)', LineWidth=1.5);
xline(inputs.param_values(3), DisplayName="Operating Pt")
legend;
xlabel('Boresight Grazing Angle \psi (deg)');
ylabel('P_d');
title('P_d vs Grazing Angle');
grid on;


% figure;
subplot(4,3,9);
plot(results.snr_psi.Psi_deg, results.snr_psi.TCN_dB, LineWidth=4 ,DisplayName='T/(C+N)');
hold on;
plot(results.snr_psi.Psi_deg, results.snr_psi.TN_dB,  LineWidth=2, DisplayName='T/N');
plot(results.snr_psi.Psi_deg, results.snr_psi.TC_dB,  LineWidth=2, DisplayName='T/C');
xline(inputs.param_values(3), DisplayName="Operating Pt")
legend;
xlabel('Boresight Grazing Angle \psi (deg)');
ylabel('Power Ratio (dB)');
title('SNR Components vs Grazing Angle');
grid on;


% figure;
subplot(4,3,10);
plot(results.tcn_power.Power, results.tcn_power.TCN_dB, LineWidth=2, DisplayName='T/(C+N)');
xline(inputs.param_values(8), DisplayName="Operating Pt")
legend;
xlabel('Transmit Power P_t (W)');
ylabel('T/(C+N) (dB)');
title('T/(C+N) vs Transmit Power');
grid on;


% figure;
subplot(4,3,11);
plot(results.pd_power.Power, results.pd_power.Pd, LineWidth=2, DisplayName='P_d');
yline(0.80, 'r--', DisplayName='Spec (0.80)', LineWidth=1.5);
xline(inputs.param_values(8), DisplayName="Operating Pt")
legend;
xlabel('Transmit Power P_t (W)');
ylabel('P_d');
title('P_d vs Transmit Power');
grid on;


% figure;
subplot(4,3,12);
plot(results.pd_nom.Power, results.pd_nom.Pd_2of3, LineWidth=2, DisplayName='P_d (2-of-3)');
yline(0.80, 'r--', DisplayName='Spec (0.80)', LineWidth=1.5);
xline(inputs.param_values(8), DisplayName="Operating Pt")
legend;
xlabel('Transmit Power P_t (W)');
ylabel('Cumulative P_d (2-of-3 scans)');
title('Cumulative P_d(2-of-3) vs Transmit Power');
grid on;


% Design iteration plots — columns: Psi, Pt, PRF_max, RPM, Pd, PRF_ok, RPM_ok, Pd_ok
% figure;
% plot(results.design_iteration(:,1), results.design_iteration(:,6), LineWidth=2);
% xlabel('Boresight Grazing Angle \psi (deg)');
% ylabel('PRF_{max} OK (1=pass, 0=fail)');
% title('PRF_{max} Constraint vs Grazing Angle');
% grid on;
% 
% figure;
% plot(results.design_iteration(:,1), results.design_iteration(:,7), LineWidth=2);
% xlabel('Boresight Grazing Angle \psi (deg)');
% ylabel('Spin Rate OK (1=pass, 0=fail)');
% title('Spin Rate Constraint vs Grazing Angle');
% grid on;
% 
% figure;
% plot(results.design_iteration(:,1), results.design_iteration(:,8), LineWidth=2);
% xlabel('Boresight Grazing Angle \psi (deg)');
% ylabel('P_d OK (1=pass, 0=fail)');
% title('P_d Constraint vs Grazing Angle');
% grid on;
