%% Split 2 - DS
MB_ONandOO_temp = ditchTypes(MB_ONandOO, {'F-mini ON', 'F-mini OFF'});

DS_types = {'ON-OFF DS dorsal' ,'ON-OFF DS nasal', 'ON-OFF DS temporal', 'ON-OFF DS ventral', 'ON DS dorsonasal', 'ON DS ventronasal', 'ON DS temporal'};
MB_ONandOO = addParamForCellTypes(MB_ONandOO, 'DS', DS_types, 'true', 'false');
[crossValModel, errorRate, resultTable_2_DS] = CellSeparator_2D(MB_ONandOO, 'DSI', 'dumbDSI',...
    'DS', 'true')
%% 

%% % Splits 2 and 3 (assuming they work)
DS_OS_types = {'ON-OFF DS dorsal' ,'ON-OFF DS nasal', 'ON-OFF DS temporal', 'ON-OFF DS ventral', 'ON DS dorsonasal', 'ON DS ventronasal', 'ON DS temporal', 'ON OS horizontal', 'ON OS vertical'};
LS_nonOFF_nonDSOS = ditchTypes(LS_ONandOO, DS_OS_types);

%% Split 4 - late ON cells vs. rest
lateTypes = {'LED', 'ON delayed'};
LS_nonOFF_nonDSOS = addParamForCellTypes(LS_nonOFF_nonDSOS, 'latencyType', lateTypes, 'late', 'early');
[crossValModel, errorRate, resultTable_4_ONlate] = CellSeparator_1D(LS_nonOFF_nonDSOS, 'ONSET_latencyToMax', 'latencyType', 'late')
%ON bursty gets split 
%4 LEDs end up in the early side. They should probably be checked.
LS_nonOFF_nonDSOS_early = ditchTypes(LS_nonOFF_nonDSOS, lateTypes);
LS_nonOFF_nonDSOS_late = keepTypes(LS_nonOFF_nonDSOS, [lateTypes, 'ON bursty']);

%% Split 5 - sustained ON vs. trans ON and ON-OFF cells
susTypes = {'ON alpha', 'PixON', 'M2', 'ON delayed', 'ON bursty'};
LS_nonOFF_nonDSOS_early = addParamForCellTypes(LS_nonOFF_nonDSOS_early, 'kinetics', susTypes, 'sustained', 'transient');
[crossValModel, errorRate, resultTable_5_ONsus] = CellSeparator_2D(LS_nonOFF_nonDSOS_early, 'ONSET_duration', 'stimInt_spikes', 'kinetics', 'sustained')

LS_nonOFF_nonDSOS_early_sus = keepTypes(LS_nonOFF_nonDSOS_early, susTypes);
LS_nonOFF_nonDSOS_early_trans = ditchTypes(LS_nonOFF_nonDSOS_early, susTypes);
nonOFF_nonDSOS_early_trans_types = unique(LS_nonOFF_nonDSOS_early_trans.cellType);

%% Split 6 - OFF cells - high baseline and low maxFR to split off OFF sus alpha
[crossValModel, errorRate, resultTable_6_baselineFiring] = CellSeparator_2D(LS_OFF, 'baseline_firing', 'afterstim_maxHz', 'cellType', 'OFF sustained alpha')
%off bursty split and a few bad ones, but otherwise works fine
LS_OFF_nonOFF_susAlpha = ditchTypes(LS_OFF, {'OFF sustained alpha'});

%% Split 7 - split out OFF OS and the like
lowFR_types = {'OFF OS - JAMB', 'OFF OS - symmetric'};
LS_OFF_nonOFF_susAlpha = addParamForCellTypes(LS_OFF_nonOFF_susAlpha, 'OFF_OS_like', lowFR_types, 'true', 'false');
[crossValModel, errorRate, resultTable_7_OFFOS] = CellSeparator_2D(LS_OFF_nonOFF_susAlpha, 'OFFSET_avgHz', 'afterstim_maxHz', 'OFF_OS_like', 'true')
%6 OFF OS symmetric in the wrong place... check them. Too high FR
LS_OFF_OFF_OS_like = keepTypes(LS_OFF_nonOFF_susAlpha, lowFR_types);
LS_OFF_trans_and_med = ditchTypes(LS_OFF_nonOFF_susAlpha, lowFR_types);

%% Split 8 - split OFF trans. alpha and OFF med sus by baseline FR and high offset spike count
baseline_firing_types = {'SbC bursty (OFF bursty)', 'OFF transient alpha', 'OFF medium sustained'};
LS_OFF_trans_and_med = addParamForCellTypes(LS_OFF_trans_and_med, 'baselineActive', baseline_firing_types, 'true', 'false');
[crossValModel, errorRate, resultTable_8_OFFTA] = CellSeparator_2D(LS_OFF_trans_and_med, 'baseline_firing', 'OFFSET_spikes', 'baselineActive', 'true')
LS_OFF_trans_and_med_withBaseline = keepTypes(LS_OFF_trans_and_med, baseline_firing_types);
LS_OFF_trans_and_med_noBaseline = ditchTypes(LS_OFF_trans_and_med, baseline_firing_types);

%% Split 9 - shelf vs. trans trans split by duration and offset spikes
[crossValModel, errorRate, resultTable_9_OFFHSS] = CellSeparator_2D(LS_OFF_trans_and_med_noBaseline, 'OFFSET_duration', 'OFFSET_spikes', 'cellType', 'OFF transient transient')

%% Split 10 - OFF trans. alpha vs. OFF med sus. Should be easy - maybe use SMS

%% Split 11 - back to ON cells: first early sus types: M2, ON alpha, PixON
%separate PixON by strong suppression
ON_early_sus_types = {'M2', 'PixON', 'ON alpha'};
SMS_ON_early_sus = keepTypes(sms_all, ON_early_sus_types);
[crossValModel, errorRate, resultTable_11_EarlyS] = CellSeparator_1D(SMS_ON_early_sus, 'suppression_by1200um', 'cellType', 'PixON')

%% Split 12 - now we are left with only M2 and ON alpha
SMS_early_sus_weakSupp_types = {'M2', 'ON alpha'};
SMS_ON_early_sus_weakSupp_types = keepTypes(SMS_ON_early_sus, SMS_early_sus_weakSupp_types);
[crossValModel, errorRate, resultTable_12_weakSupp] = CellSeparator_1D(SMS_ON_early_sus_weakSupp_types, 'maxONresponse_spikes', 'cellType', 'M2')
%doesn't work as well as I think it should'

%% Split 13 - back to the early trans. small cells (mostly)
%start by picking off ON trans. trumpet and HD1
SMS_nonOFF_nonDSOS_early_trans = keepTypes(sms_all, nonOFF_nonDSOS_early_trans_types);
[crossValModel, errorRate, resultTable_13_earlyTrans] = CellSeparator_2D_polynomial(SMS_nonOFF_nonDSOS_early_trans, 'suppression_by600um', 'maxONresponse_spikes', 'cellType', 'HD1')

%% Split 14 - ON trans. trumpet
SMS_nonOFF_nonDSOS_early_trans_nonHD1 = ditchTypes(SMS_nonOFF_nonDSOS_early_trans, {'HD1'});
[crossValModel, errorRate, resultTable_14_ONTT] = CellSeparator_2D(SMS_nonOFF_nonDSOS_early_trans_nonHD1, 'suppression_by600um', 'maxONresponse_spikes', 'cellType', 'ON transient trumpet')

%% Split 14 - ON trans. low spike count types
SMS_nonOFF_nonDSOS_early_trans_lowSpike = ditchTypes(SMS_nonOFF_nonDSOS_early_trans_nonHD1, {'ON transient trumpet'});
% get F-mini OFF
[crossValModel, errorRate, resultTable_14_Fmini] = CellSeparator_2D(SMS_nonOFF_nonDSOS_early_trans_lowSpike, 'minONOFFRatio', 'maxResponse_spikesBaselineSubtracted', 'cellType', 'F-mini OFF')

%% Split 15
% get HD2
SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF = ditchTypes(SMS_nonOFF_nonDSOS_early_trans_lowSpike, {'F-mini OFF'});
[crossValModel, errorRate, resultTable_15_HD2] = CellSeparator_2D_polynomial(SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF, 'maxOFFresponse_spikes', 'maxONresponse_spotSize', 'cellType', 'HD2')

%% Split 16
SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF_noHD2 = ditchTypes(SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF, {'HD2'});
% UHDs are totally suppressed by 600 um
[crossValModel, errorRate, resultTable_16_UHD] = CellSeparator_2D_polynomial(SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF_noHD2, 'suppression_by600um', 'maxONresponse_ONOFFRatio', 'cellType', 'UHD')
% this can be done as a hard cut because CellSeparator_1D is too
% conservative here and includes some almost suppressed F-minis and ON
% trans. slides

%% Split 17 ON trans. slide vs. F-mini ON
LS_split17 = keepTypes(LS_ONandOO, {'F-mini ON', 'ON transient slide'});

[crossValModel, errorRate, resultTable_16_UHD] = CellSeparator_2D_polynomial(SMS_nonOFF_nonDSOS_early_trans_lowSpike_noFmOFF_noHD2, 'suppression_by600um', 'maxONresponse_ONOFFRatio', 'cellType', 'UHD')

%could be tricky











