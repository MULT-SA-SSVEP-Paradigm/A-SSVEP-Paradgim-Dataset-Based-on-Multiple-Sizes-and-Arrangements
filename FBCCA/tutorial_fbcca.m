% Sample codes for the filterbank canonical correlation analysis (FBCCA)-
% based steady-state visual evoked potential (SSVEP) detection method [1]. 
%
% Dataset (sample.mat):
%   A 12-target SSVEP dataset recorded from a single subject. The stimuli
%   were generated by the joint frequency-phase modulation (JFPM) [2]
%     - Stimulus frequencies    : 8.0 - 13.5 Hz with an interval of 0.5 Hz
%     - Stimulus phases         : 0-3.85pi with an interval of 0.35pi
%     - # of channels           : 9 (1: Pz, 2: PO5,3:  PO3, 4: POz, 5: PO4,
%                                    6: PO6, 7: O1, 8: Oz, and 9: O2)
%     - # of recording blocks   : 8
%     - Data length of epochs   : 4 [seconds]
%     - Sampling rate           : 250 [Hz]
%
% See also:
%   test_fbcca.m
%   filterbank.m
%   itr.m
%
% Reference:
%   [1] X. Chen, Y. Wang, S. Gao, T. -P. Jung and X. Gao,
%       "Filter bank canonical correlation analysis for implementing a 
%        high-speed SSVEP-based brain-computer interface",
%       J. Neural Eng., 12: 046008, 2015.
%   [2] X. Chen, Y. Wang, M. Nakanishi, X. Gao, T. -P. Jung, S. Gao,
%       "High-speed spelling with a noninvasive brain-computer interface",
%       Proc. Int. Natl. Acad. Sci. U. S. A, 112(44): E6058-6067, 2015.
%   
%   This code references: https://github.com/mnakanishi/TRCA-SSVEP/tree/master


%% Clear workspace
clear all
close all
clc
%% Set paths
addpath('D:\Matlab files\BCI');
%% Parameter for analysis (Modify according to your analysis)
fprintf('Results of the FBCCA-based method.\n');

%Setting the path to the folder where EEG data is saved
base_path = 'D:\Matlab files\BCI\Dataset\SUB\5';

all_file_path = fullfile(base_path,'*.mat');

file = dir(all_file_path);

%Extract the second digit of the filename into the array numsort
for i = 1 : numel(file)
    numsort(i) = str2num(file(i).name(2:eval('length(file(i).name)-6')));
end

[~,ind]=sort(numsort);
file = file(ind);
%%
sum_mu_accs = 0;
sum_muci_accs(1) = 0;
sum_muci_accs(2) = 0;
sum_mu_itr = 0;
sum_muci_itr(1) = 0;
sum_muci_itr(2) = 0;

mu_accs_list = [];
mu_itr_list = [];
%%
for file_i = 1:length(file)
    name = file(file_i).name;
    file_path = fullfile(base_path, name);   
    data = importdata(file_path);

    % Data length for target identification [s]
    len_gaze_s = 0.4;  
    
    % Visual latency being considered in the analysis [s]            
    len_delay_s = 0;

    % The number of sub-bands in filter bank analysis
    num_fbs = 5;
    
    % The number of harmonics in the canonical correlation analysis
    num_harms = 3;
    
    % 100*(1-alpha_ci): confidence intervals
    alpha_ci = 0.05;                 
    
    %% Fixed parameter (Modify according to the experimental setting)
    
    % Sampling rate [Hz]
    fs = 250;                  
    
    % Duration for gaze shifting [s]
    len_shift_s = 2;                  
    
    % List of stimulus frequencies
    list_freqs = [8:0.5:9.5 10:0.5:11.5 12:0.5:13.5];
%     list_freqs = [8:2:12 8.5:2:12.5 9:2:13 9.5:2:13.5];
                                            
    % The number of stimuli
    num_targs = length(list_freqs);    
    
    % Labels of data
     labels = [1:1:num_targs];         

    %% Preparing useful variables (DONT'T need to modify)
    
    % Data length [samples]
    len_gaze_smpl = round(len_gaze_s*fs);           
    
    % Visual latency [samples]
    len_delay_smpl = round(len_delay_s*fs);         
    
    % Selection time [s]
    len_sel_s = len_gaze_s + len_shift_s;
    
    % Confidence interval
    ci = 100*(1-alpha_ci);                  
    
    %% Performing the FBCCA-based SSVEP detection algorithm
    % Preparing data
    eeg=permute(data,[3,1,2,4]);
    [ ~, num_chans, ~, num_blocks] = size(eeg);
    segment_data = len_delay_smpl+1:len_delay_smpl+len_gaze_smpl;
    eeg = double(eeg(:,:,segment_data,:)); 
    
    % Estimate classification performance
    for block_i = 1:1:num_blocks
        % Test 
        testdata = squeeze(eeg(:, :, :,block_i));
        estimated = test_fbcca(testdata, list_freqs, fs, num_harms, num_fbs);
        % fprintf('%2d ',estimated);
    
        % Evaluation 
        is_correct = (estimated==labels);
        accs(block_i) = mean(is_correct)*100;
        itrs(block_i) = itr(num_targs, mean(is_correct), len_sel_s);

        fprintf('Block %d: Accuracy = %2.2f%%, ITR = %2.2f bpm\n',...
           block_i, accs(block_i), itrs(block_i));
        %block_i
        %fprintf('\n ',estimated);
    end 
    

   
    % Summarize
    fprintf('S%d.mat：',file_i);
    [mu_accs, ~, muci_accs, ~] = normfit(accs, alpha_ci);
    fprintf('Mean accuracy = %2.2f %% (%2d%% CI: %2.2f - %2.2f %%)\n',...
        mu_accs, ci, muci_accs(1), muci_accs(2));
    [mu_itr, ~, muci_itr, ~] = normfit(itrs, alpha_ci);
    fprintf('Mean ITR = %2.2f bpm (%2d%% CI: %2.2f - %2.2f bpm)\n',...
       mu_itr, ci, muci_itr(1), muci_itr(2));
    sum_mu_accs = sum_mu_accs + mu_accs;
    sum_muci_accs(1) = sum_muci_accs(1) + muci_accs(1);
    sum_muci_accs(2) = sum_muci_accs(2) + muci_accs(2);
    sum_mu_itr = sum_mu_itr + mu_itr;
    sum_muci_itr(1) = sum_muci_itr(1) + muci_itr(1);
    sum_muci_itr(2) = sum_muci_itr(2) + muci_itr(2);

    mu_accs_list = [mu_accs_list, mu_accs];
    mu_itr_list = [mu_itr_list, mu_itr];

end 

% Final Summarization
ma_mu_accs = sum_mu_accs / i;
ma_muci_accs(1) = sum_muci_accs(1) / i;
ma_muci_accs(2) = sum_muci_accs(2) / i;
ma_mu_itr = sum_mu_itr / i;
ma_muci_itr(1) = sum_muci_itr(1) / i;
ma_muci_itr(2) = sum_muci_itr(2) / i;
fprintf('Finally Mean accuracy = %2.2f %% (%2d%% CI: %2.2f - %2.2f %%)\n', ma_mu_accs, ci, ma_muci_accs(1), ma_muci_accs(2));
fprintf('Finally Mean ITR = %2.2f bmp (%2d%% CI: %2.2f - %2.2f bmp)\n', ma_mu_itr, ci, ma_muci_itr(1), ma_muci_itr(2));