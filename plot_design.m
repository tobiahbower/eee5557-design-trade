load("trade_study_results.mat");

figure; 
plot(results.altitude.Altitude, abs(results.altitude.TCN_dB),LineWidth=2, DisplayName='T/(C+N)');
hold on; 
plot(results.altitude.Altitude, abs(results.altitude.TC_dB), LineWidth=2, DisplayName='T/C');
plot(results.altitude.Altitude, abs(results.altitude.TN_dB), LineWidth=2, DisplayName='T/N');
legend;
xlabel('Altitude (m)');
ylabel('Power Ratio Magnitude (dB)');
grid on;


figure; 
plot(results.tau.Tau, abs(results.tau.TCN_dB),LineWidth=2, DisplayName='T/(C+N)');
hold on; 
plot(results.tau.Tau, abs(results.tau.TC_dB), LineWidth=2, DisplayName='T/C');
plot(results.tau.Tau, abs(results.tau.TN_dB), LineWidth=2, DisplayName='T/N');
legend;
xlabel('Tau (s)');
ylabel('Power Ratio Magnitude (dB)');
grid on;


figure; 
plot(results.psi.Psi_deg, abs(results.psi.TCN_dB),LineWidth=2, DisplayName='T/(C+N)');
hold on; 
plot(results.psi.Psi_deg, abs(results.psi.TC_dB), LineWidth=2, DisplayName='T/C');
plot(results.psi.Psi_deg, abs(results.psi.TN_dB), LineWidth=2, DisplayName='T/N');
legend;
xlabel('Boresight (deg)');
ylabel('Power Ratio Magnitude (dB)');
grid on;


figure; 
plot(results.power.Power, abs(results.power.TN_dB), LineWidth=2, DisplayName='T/N');
hold on; 
plot(results.power.Power, abs(results.power.TC_dB), LineWidth=2, DisplayName='T/C');
plot(results.power.Power, abs(results.power.TCN_dB), LineWidth=2, DisplayName='T/(C+N)');
legend;
xlabel('Xmt Power');
ylabel('Power Ratio Magnitude (dB)');
grid on;


figure;
subplot(2,1,1);
plot(results.system.PRF, abs(results.system.TCN_dB), LineWidth=2, DisplayName='T/(C+N)');
legend;
xlabel('PRF (Hz)');
ylabel('Power Ratio Magnitude (dB)');
grid on;
subplot(2,1,2);
plot(results.system.PRF, abs(results.system.Pd), LineWidth=2, DisplayName='P_d');
legend;
xlabel('PRF (Hz)');
ylabel('Pd');
grid on;


figure;
plot(results.twarn_psi.Psi_deg,results.twarn_psi.Twarn_sec, LineWidth=2, DisplayName='T_{warn}');
legend

figure;
plot(results.pd_psi.Psi_deg, results.pd_psi.Pd, LineWidth=2, DisplayName='P_d');
legend

figure;
plot(results.snr_psi.Psi_deg, results.snr_psi.TCN_dB, LineWidth=2, DisplayName='T/(C+N)');
hold on;
plot(results.snr_psi.Psi_deg, results.snr_psi.TN_dB, LineWidth=2, DisplayName='T/N');
plot(results.snr_psi.Psi_deg, results.snr_psi.TC_dB, LineWidth=2, DisplayName='T/C');
legend

figure;
plot(results.tcn_power.Power, results.tcn_power.TCN_dB, LineWidth=2, DisplayName='T/(C+N)');
legend

figure;
plot(results.pd_power.Power, results.pd_power.Pd, LineWidth=2, DisplayName='P_d');
legend

figure;
plot(results.pd_nom.Power, results.pd_nom.Pd_NofM, LineWidth=2, DisplayName='P_d');
legend



% figure;
% plot(results.design_iteration.Psi_deg, results.design_iteration.PRF_ok);
% figure;
% plot(results.design_iteration.Psi_deg, results.design_iteration.RPM_ok);
% figure;
% plot(results.design_iteration.Psi_deg, results.design_iteration.Pd_ok);