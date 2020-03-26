function [TT] = GPRray(x,v,z,ploton,noise)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <<Multi Offset GPR Raytracing Forward Model in 1D>>
%
% This script traces rays and reports travel time for the WAARR or
% equivalent CMP style multi-offset GPR gather. 
%
% _INPUTS_
% 
% x = [# # #...]; % define receiver locations, [meters]
% v = [# # #...]; % define velocity for each layer, [m/ns]
% z = [# # #...]; % define thickness of each layer, [meters]
% ploton = 0; %set to "1" to show all raypaths. If ploton is selected, the
%      output will be instead in the format to go directly into inversion.
% noise  = 0; assign the noise level to be applied to each travel time.
%      Noise is assigned in units of nanoseconds; this value is used to
%      draw a pseudorandom value from a normal distributino (randn).
%
% The length of v must equal the length of z.  The receiver positions may
% be at any distances. The Tx is always at 0, therefore it is assumed all
% interfaces are horizontal. Reciever positions will be the same for each
% layer.
%
% _OUTPUT_
%
% TT, travel time matrix corrsiponding to each x, for n-layers, in [ns].
%
% Andrew D. Parsekian, June 2015. Upd. 28 March 2016, 16 March 2017.
% University of Wyoming, Geology & Geophysics, Laramie, WY
% GPRray, beta  v0.3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all

if length(v)~=length(z)
    error('There is not a velocity associated with each layer. Please check that the length of v = length of z.')
end

%% calculate all first layer reflections first
r_point = x./2; % reflection point for each ray
leg1 = sqrt(r_point.^2+z(1)^2); %triangle base for each raypath

for i = 1:length(x) %loop through all layer 1 rays based on number of Rx
    if ploton == 1
        plot([0 r_point(i) x(i)],[0 -z(1) 0],'-k'); hold on %plot full raypath
        xlabel('offset [m]')
        ylabel('depth [m]')
    end
    tt1(i) = leg1(i)*2/v(1); %travel time calculation for rays in layer 1
end

%% n-layers calculation

for i = 2:length(v)
    [TT(i,:), ~, ~] = nlayerrays(x,z(1:i),v(1:i),ploton);
end

TT(1,:) = tt1; % just add the tt's for layer 1 calculated above

if ploton ==1
    for ik = 1:length(z) %loop through to plot lines at each interface
        plot([0 max(x)],[-sum(z(1:ik)) -sum(z(1:ik))],'k','linewidth',2);
    end
end

% travel time figure
if ploton ==1
    figure
    plot(0,0,'-k');hold on
    plot(x,TT,'or');
    xlabel('offset[m]');
    ylabel('travel time [ns]')
    set(gca,'Ydir','reverse')
    
    for bg = 1:length(v) %if ploton is selected, output instead in the format to go into inversion
        
        if length(noise) == 1;
        noisevec = randn(1,length(TT(bg,:)))*noise;
        TT_{bg} = [x; TT(bg,:)+noisevec];
        elseif length(noise) ==2;
        noisevec = randn(1,length(TT(bg,:)))*noise(2);
        TT_{bg} = [x+noisevec; TT(bg,:)];
        end
    end
    TT = TT_;
end
end

%% nested functions
function [TT, Xout, Yout] = nlayerrays(x,z,v,ploton)

for i = 1:length(x) %loop through all Rx positions
    [ ~, ~, leg ] = rayObjective( z,v,x(i)); %x(i) input is the starting point for the inversion
    
    X(1) = 0; % Tx is always at (0,0) so this is hard coded
    legs = [leg fliplr(leg)]; %makes mirrior image of x positions where rays intersect interfaces
    for ii = 2:(length(z)*2+1);
        X(ii) = sum(legs(1:ii-1)); %calculates x vector for plotting based on legs
    end
    
    clear Y %clean up because of loop
    for ij = 2:ceil((length(z)*2+1)/2); % create vector of depths = length to x-positions
        Y(ij) = sum(z(1:ij-1));
    end
    Y = [Y fliplr(Y(1:end-1))]; %mirror image and combine
    
    if ploton == 1;
        plot(X,-Y,'k'); hold on %plot all raypaths linked to deepest reflection for one TxRx pair
    end
    
    %  the travel times for each raypath are calculated
    Vvec = [v fliplr(v)];
    for ik = 1:length(X)-1
        base = X(ik+1)-X(ik);
        hght = abs(Y(ik+1)-Y(ik));
        tt(ik)  = sqrt(base^2+hght^2)/Vvec(ik);
    end
    TT(i) = sum(tt);
    Yout(i,:) = Y;
    Xout(i,:) = X;
end
end


function [ x, fval, leg ] = rayObjective( z,v,x_in )

[x, fval] = fminsearch(@Objective,0); %find where the ray crosses each interface 
    %angles in degrees are not required, so all calculations remain in radians
    function x_diff = Objective(ang)
        x_diff = abs(nestObjective(ang)-x_in);
    end

    function [x_out] = nestObjective(ang)
        theta(1) = (ang);
        for k = 2:length(z) % calcuate the angles for each following layer based on theta 1
            theta(k) = asin((v(k)*sin(theta(k-1)))/v(k-1)); %Snell's law
        end
        
        for m = 1:length(z) %calculate where ray intersects each lower layer interface
            leg(m) = tan(theta(m))*z(m);
        end
        
        x_out = 2*(sum(leg)); %complete calculation of raypath lenth
        
    end

end

