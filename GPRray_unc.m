function [ bs_result,bs_d ] = GPRray_unc(DATA,strap,resamps)
%GPRray_unc = calculates uncertainty in velocity and layer thickness using
%bootstrapping statistics. 
% DATA    = GPR cmp data structure formatted for GPRrayINV
% strap   = size of bootstrap proportion; suggest to try 0.5
% resamps = number of resamples, should be large, ideally >1000. 
%
% NOTE! --> this function is SLOW. Due to repeating the inversion many
% times to complete the resampling, 1,000 resamplings may take several
% hours depending on the dataset.  More reflectors and more picks will take
% a LOT longer. Consider testing with 10 resamplings. Get it working, then
% set it to run overnight.
%
% A.Parsekian 17 March 2020

if license('test', 'parallel_computing_toolbox')==1
    disp('Parallel Processing enabled!')
else
    disp('You do not have the Parallel Processing Toolbox. The script will run, but it will take a long time. Consider moving the processing to a computer that has the toolbox and multiple cores.') 
end

for j = 1:resamps;
    
    for i = 1:length(DATA)
        rlen = length(DATA{i});
        p = strap;
        N = rlen;
        n = round(N*p); %// desired number of ones
        result = [ ones(1,n) zeros(1,N-n) ]; %// n ones and N-n zeros
        result = result(randperm(N)); %// random order
        bsDATA{j,i} = DATA{i}(:,find(result));
    end
end

parfor j=1:resamps
    
    [bs_d(j,:), ~] = GPRRayInv({bsDATA{j,:}},0,1e-3); % inversion done here
end

bs_result(1,:) = mean(bs_d,1);
bs_result(2,:) = std(bs_d,1);


%% Plotting
sz = size(bs_d);
for j = 1:sz(1)
    sz = size(bs_d(j,:));
    C = reshape(bs_d(j,:),sz(2)/2,2);
    C=C';
    dV = C(1,:) ;
    dZ = cumsum(C(2,:));
    for i = 1:2:length(dZ)*2;
        z(1) = 0;
        z(i+1:i+2,1) = dZ((i+1)/2);
        v(i:i+1,1)   = dV((i+1)/2);
    end
    plot(v,z(1:end-1),'-','color',[.5 .5 .5],'linewidth',1); hold on
end
% plot the mean values on top
sz = size(bs_result(1,:));
C = reshape(bs_result(1,:),sz(2)/2,2);
C=C';
dV = C(1,:) ;
dZ = cumsum(C(2,:));
for i = 1:2:length(dZ)*2;
    z(1) = 0;
    z(i+1:i+2,1) = dZ((i+1)/2);
    v(i:i+1,1)   = dV((i+1)/2);
end
figure
plot(v,z(1:end-1),'-r','linewidth',1.5); hold on


% plot the Dix result for comparison
[Vdix, depth] = dix_calc(DATA);
depth = cumsum(depth);
for i = 1:2:length(depth)*2;
    zd(1) = 0;
    zd(i+1:i+2,1) = depth((i+1)/2);
    vd(i:i+1,1)   = Vdix((i+1)/2);
end
plot(vd,zd(1:end-1),'--k'); hold on

%finsih plotting
set(gca,'ydir','reverse')
ylim([0 max([z; zd]+.2)])
xlabel('velocity [m ns^-^1]')
ylabel('depth [m]')
legend('bootstraps','mean result','Dix','location','northeast')
end

