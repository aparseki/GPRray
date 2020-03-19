%% Example workflow for processing Multi-Offset GPR datasets 
% This workflow is designed around picks made in the ReflexW "*.PCK" file
% format saved in the same directory as the scripts.

%% Load the picks
% input is a pick file "*.PCK" from ReflexW with 7 columns. The important
% columns are 2, 4, and 7, x, t, and pick code respectively.  Air wave and
% ground wave must be picked, but are not used at this time. Airwave pick
% code must be 0 and ground wave must be 1.  Layers must be ascending pick
% code from the earliest times and increasing to later times.  Each
% reflector does NOT have to have the same number of picks.

DATA = importREFLEXpicks('ACMP100_pick.PCK');

% The resulting DATA structure is a cell array where each cell is a
% reflector and inside each cell is the offsets and travel times associated
% with each pick. This DATA structure is in the format required by
% GPRrayInv.

%% Perform a basic inversion on the dataset
%[describe the inputs]
%
% starting_mod = starting model. Currently set up to guess a reasonable
% starting model, under development.
%
% convergance_criteria tells lsqnonlin when to stop.  Generally 1e-3 has
% been found to be the most stable, but using smaller values may be
% appropriate in special cases.

starting_mod = []; % no input needed for now
convergance_criteria = 1e-3;

%result = GPRRayInv(DATA,starting_mod,convergance_criteria);

% The result is a vector in the form [v v ... t t ...] where v is velocity
% and t is layer thickness. The length of the vector is 2x# layers. 

%% Perform a boostrapping inversion to estimate uncertainty
%
% This component is parallelized, if you have the Parallel Computing
% Toolbox. For example, a 6 layer model that would take 1.4h to run 100
% bootsrraps on a single processor would take ~0.4h to run in parallel on a
% 4 core machine. The more cores, the better! Smaller numbers of layers
% take shorter in either case.
%
% This function assumes convergance criteria of 1e-3 and uses an automatic
% optimized starting model within reasonable bounds. Exceptional subsurface
% conditions (i.e., very thick layers, very large velocity contrasts) may
% require editing the GPRRayInv code.

strap = 0.5; %Proportion of the dataset that is used for bootstrapping.
             %This ultimately effects the size of the error bars that are
             %output; values closer to zero use less of the dataset, while
             %values closer to 1 use more of the dataset.  There is no 
             %perfect rule for choosing this value, and this is a
             %limitation of bootstrapping.  
             
resamps = 1000; %How many bootstrap resamplings are done. Ideally this
               %number will be as large as possible, hopefully >1,000,
               %however it is recognized that this is computationally
               %expenseive, particularly if you don't have the Parallel
               %Computing Toolbox. Another limitation of bootstrapping.

tic
[bootstrap_result,bs_d] = GPRray_unc(DATA,strap,resamps);
toc
% Outputs:
% 
% bootstrap_result = Top row: [v v ... t t ...] where v = layer velocity 
% and t = layer thickness. Bottom row [std_v std_v ... std_t std_t...].
%
% bs_d = results of all bootstraped simuations. Each row is a [v v ... t t
% ...] result.
