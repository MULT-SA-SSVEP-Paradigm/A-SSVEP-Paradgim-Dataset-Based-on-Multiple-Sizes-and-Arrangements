function model = train_trca(eeg, fs, num_fbs)
% Training stage of the task-related component analysis (TRCA)-based 
% steady-state visual evoked potentials (SSVEPs) detection [1].
%
% function model = train_trca(eeg, fs, num_fbs)
%
% Input:
%   eeg         : Input eeg data 
%                 (# of targets, # of channels, Data length [sample])
%   fs          : Sampling rate
%   num_fbs     : # of sub-bands
%
% Output:
%   model       : Learning model for tesing phase of the ensemble 
%                 TRCA-based method
%     - traindata   : Training data decomposed into sub-band components 
%                     by the filter bank analysis
%                     (# of targets, # of sub-bands, # of channels, 
%                      Data length [sample])
%     - W           : Weight coefficients for electrodes which can be 
%                     used as a spatial filter.
%     - num_fbs     : # of sub-bands
%     - fs          : Sampling rate
%     - num_targs   : # of targets
%
% See also:
%   test_trca.m

% Reference:
%   [1] M. Nakanishi, Y. Wang, X. Chen, Y. -T. Wang, X. Gao, and T.-P. Jung,
%       "Enhancing detection of SSVEPs for a high-speed brain speller using 
%        task-related component analysis",
%       IEEE Trans. Biomed. Eng, 65(1):104-112, 2018.
%   
%   This code references: https://github.com/mnakanishi/TRCA-SSVEP/tree/master


if nargin < 2
    error('stats:train_trca:LackOfInput', 'Not enough input arguments.'); 
end

if ~exist('num_fbs', 'var') || isempty(num_fbs), num_fbs = 3; end

[num_targs, num_chans, num_smpls, ~] = size(eeg);
trains = zeros(num_targs, num_fbs, num_chans, num_smpls);
W = zeros(num_fbs, num_targs, num_chans);
for targ_i = 1:1:num_targs
    eeg_tmp = squeeze(eeg(targ_i, :, :, :));
    for fb_i = 1:1:num_fbs
        eeg_tmp = filterbank(eeg_tmp, fs, fb_i);%滤波器组
        trains(targ_i,fb_i,:,:) = squeeze(mean(eeg_tmp, 3));%将处理后的数据储存
        w_tmp = trca(eeg_tmp);%权重系数
        W(fb_i, targ_i, :) = w_tmp(:,1);%将权重系数储存
    end % fb_i
end % targ_i
model = struct('trains', trains, 'W', W,...
    'num_fbs', num_fbs, 'fs', fs, 'num_targs', num_targs);


function W = trca(eeg)
% Task-related component analysis (TRCA). This script was written based on
% the reference paper [1].
%
% function W = trca(eeg)
%
% Input:
%   eeg         : Input eeg data 
%                 (# of channels, Data length [sample], # of trials)
%
% Output:
%   W           : Weight coefficients for electrodes which can be used as 
%                 a spatial filter.
% Reference:
%   [1] H. Tanaka, T. Katura, H. Sato,
%       "Task-related component analysis for functional neuroimaging and 
%        application to near-infrared spectroscopy data",
%       NeuroImage, vol. 64, pp. 308-327, 2013.
%   
%   This code references: https://github.com/mnakanishi/TRCA-SSVEP/tree/master

[num_chans, num_smpls, num_trials]  = size(eeg);
S = zeros(num_chans);
for trial_i = 1:1:num_trials-1
    x1 = squeeze(eeg(:,:,trial_i));
    x1 = bsxfun(@minus, x1, mean(x1,2));
    for trial_j = trial_i+1:1:num_trials
        x2 = squeeze(eeg(:,:,trial_j));
        x2 = bsxfun(@minus, x2, mean(x2,2));
        S = S + x1*x2' + x2*x1';
    end % trial_j
end % trial_i
UX = reshape(eeg, num_chans, num_smpls*num_trials);
UX = bsxfun(@minus, UX, mean(UX,2));
Q = UX*UX';
[W,~] = eigs(S, Q);