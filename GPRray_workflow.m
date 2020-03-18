%% Example workflow for processing Multi-Offset GPR datasets 
% This workflow is designed around picks made in the ReflexW "*.PCK" file
% format saved in the same directory as the scripts.


%% Load the picks
% [describe the dataset]

DATA = importREFLEXpicks('ACMP100_pick3.PCK');

%[describe the data structure]

%% Perform a basic inversion on the dataset
%[describe the inputs]
%result = GPRRayInv(DATA,[],1e-3);
%[describe the output]
%% Perform a boostrapping inversion to estimate uncertainty
%[describe the inputs]
tic
bootstrap_result = GPRray_unc(DATA,0.5,100);
toc
%[describe the output]