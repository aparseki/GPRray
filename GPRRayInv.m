function [d, RESNORM,RESIDUAL] = GPRRayInv(DATA,st,crit)

%% ------------------------------------------------------------------------
%
% <<Inversion for multi-offset GPR using ratracing.>>
%
% Optimization between measured and ray-trace modeled data using the trust
% region reflective algorithm.
% %
% % DATA = The inversion accepts a cell array where each reflector is a
% % sequentially numbered cell starting with the smallest travel time and
% % then increasing. Each cell should have two rows; on the top row will be
% % the offset distance in METERS and the lower row will be the travel time
% % in NANOSECONDS. For example:
% %
% % Mod for Example below: x = [1:10] | v = [.1 .09 .065] | z=[1 1.5 2]
% %
% % DATA{1} = [1 2 3 4 5; 22.4 28.3 36.1 44.7 53.8];
% % DATA{2} = [1 3 4 5; 54.4 62.2 68.2 75.3];
% % DATA{3} = [1 2 3 4 5 6 7; 115.6 117.6 120.8 125.3 130.7 137 144];
% %
% % As shown, each reflector can have any number of picks and the number of
% % picks does not need to be consistant.
%
% %st = Starting model. By leaving "0", it will automatically use dix as a
% starting model. If dix fails, automatically switches to uniform velocity.
%
% %crit = convergence criteria. Suggest 1e-3.
%
% Please note constraints on velocity and layer thickness.  These should be
% fine for most cases, but it is possible that under unusual circumstances
% they may need to be revised.  Also note that velocity constraints must be
% multiplied by 10 to work well with lsqnonlin.
% %
% % OUTPUT
% %
% % d, inversion result.  The first n-values are velocity. The last
% % n-values are layer thicknesses.
% %
% % fval, output of lsqnonlin.
%
% Andy Parsekian, August 2015
%
%% ------------------------------------------------------------------------
[~, nlay] = size(DATA);

%% do the dix calcuation, if it fails, just use standard values for start

if isempty('st')==0;
    [Vdix, depth] = dix_calc(DATA);
    if isreal([10.*Vdix depth]) ==1;
        st = [10.*Vdix depth];
    else
        st = [ones(1,nlay).*1 ones(1,nlay)];
    end
end


cnt=0;

%% Optimization setup

% note: velocity constraints are already mulitplied by 10 as needed by
% lsqnonlin.

lbv = ones(1,nlay).*.32; %lower velocity, physically based on water
ubv = ones(1,nlay).*3; %upper bound velocity, physically based on free space
lbz = ones(1,nlay).*.05; %lower bound thickness, could be smaller for very high frequency data
ubz = ones(1,nlay).*6; %upper bound, could be larger for very low frequency data

lb = [lbv lbz];       % Lower bound
ub = [ubv ubz];       % Upper bound


% Find all offsets to be modeled as "X." Allows for non-uniform x-spacing.
X=[]; data = [];
for i = 1:length(DATA)
    rfl = [cell2mat(DATA(i)); i.*ones(1,length(cell2mat(DATA(i))))];
    data = [data rfl]; %->create "data" vector that has only time information. Row1:offset,row2:time,row3:reflector#.
    offsets = [X rfl(1,:)];
end
X = unique(offsets);


%% Do optimization

x_diff_log = [];
options = optimset('TolX',crit,'TolFun',crit,'FinDiffRelStep',crit);
[d,RESNORM,RESIDUAL] = lsqnonlin(@ObjectiveMisfit,st,lb,ub,options);


    function x_diff = ObjectiveMisfit(params)
        fwd = nestObjectiveInv(params);
        x_diff = data(2,:)-fwd;
        %x_diff = norm(data(2,:)-fwd,2);
        cnt=cnt+1;
        x_diff_log(cnt) = norm(x_diff);
        if rem(cnt/10,1)==0;
            disp([norm(x_diff)/sqrt(length(x_diff)) params])
        end
    end

    function [TT_] = nestObjectiveInv(params)
        sz = size(params);
        C = reshape(params,sz(2)/2,2);
        C=C';
        V = C(1,:).*.1; %convert parameters out of 10 multiplier as required by lsqnonlin
        Z = C(2,:);
        [TT] = GPRray(X,V,Z,0);
        %-> extract only models that have data
        for i=1:length(data)
            [~,ofst_indx] = min(abs(data(1,i)-X)); %find the index of the corect offset
            TT_(i) = TT(data(3,i),ofst_indx);  %extract the travel time from the correct reflector and offset
        end
    end


%% scale d
% due to how lsqnonlin deals with inmputs, the first three values of "d" need
% to be scaled by 0.1.

d(1:(0.5*length(d))) = d(1:(0.5*length(d))).*.1;
[TFinal] = GPRray(X,d(1:(0.5*length(d))),d(1+(0.5*length(d)):length(d)),0);


%% plots
figure
subplot(1,2,1)
plot(x_diff_log)

subplot(1,2,2)
plot(0,0,'-k');hold on
plot(X,TFinal,'or');
for gg = 1:length(DATA)
    plot(DATA{gg}(1,:),DATA{gg}(2,:),'xk')
end

xlabel('offset[m]');
ylabel('travel time [ns]')
set(gca,'Ydir','reverse')

end

