function [Vdix, depth] = dix_calc(DATA)
%% GPR CMP 1D Velocity Sounding Plot~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Returns velocity
% strucure as a function of depth with calculated confidence intervals based
% on Jacob and Hermance (2004), JEEG.
%
% <<Instructions>>
%
% <<Output variable definitions>>
%
% DE = depth intervals (meters)
% Derr = depth uncertainty
% VE = interval velocity, for plotting (m/ns)
% VErr =velocity uncertainty, for plotting (m/ns)
% Vdix = velocity after dix correction, same as VE but not for plotting (m/ns)
% depthE = depth uncertainty, for plotting
% vel_uncorr = velocity before Dix (m/ns)
%
% A. Parsekian, 2/28/2012, 10/28/2013  8/13/15 
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rflx=length(DATA);      %counts the number of reflectors


%% Determine padding needed to make vectors equal length
count=0;                    %just a counter for the loop
for i=1:rflx;               %cycle through each relfector
ind=length(DATA{i});    %find how many picks made for each reflector
count=count+1;              %advance counter
hsz(i)=(ind);         %padding length
clear ind                   %clear unneeded variable
end

%% creates a time matrix and distance matrix with columns for each reflector
count=0;                    %just a counter
for i=1:rflx;               %cycle through each reflector
    ind=length(DATA{i});%how many data points in each reflector
    count=count+1;          %advance counter
    dist=[DATA{i}(1,:)'; zeros((max(hsz)-hsz(i)),1)];%creates an offset/distance value column for each reflector with padding as caluclated above
    time=[DATA{i}(2,:)'; zeros((max(hsz)-hsz(i)),1)];%creates an time value column for each reflector with padding as caluclated above
    D(:,i)=dist;            %collects vectors into one new variable
    T(:,i)=time;            %collects vectors into one new variabe 
    clear ind               %clear unneeded variable
end

%% calculate slope and intercept for each reflector
for i=1:rflx;               %cycle through each reflector
    
    n0=find(D(:,i));        %finds number of picks in the reflector
    m(:,i)=polyfit(D(min(n0):max(n0),i).^2,T(min(n0):max(n0),i).^2,1); %find slope/intercept of X^2 T^2
    y=m(1,i).*D(min(n0):max(n0),i).^2+m(2,i);                          %calculate model
    s(i)=sqrt((sum(((T(min(n0):max(n0),i).^2)-y).^2)/(length(n0)-2))); %least squares misfit
    V95(i)=s(i)*(2.27/(sum((D(min(n0):max(n0),i).^2-mean((D(min(n0):max(n0),i).^2))).^2))^.5); %95% C.I. for velocity
    Vel(i,1)=1/sqrt(m(1,i));                                           %converts slope of regression to velocity
    v1=(.5*(V95(i)/m(1,i)))*sqrt(m(1,i));                              %propagation of uncertainty
    Vel(i,2)=(1*(v1/sqrt(m(1,i))))*Vel(i,1);                           %propagation of uncertainty
%     T95(i)=2.27*((sum(T(min(n0):max(n0),i).^2)^2)/(length(T(min(n0):max(n0)))*(sum((T(min(n0):max(n0),i).^2-mean((T(min(n0):max(n0),i).^2))).^2))))^.5; %95% C.I. on time
    T95(i)=2.27*s(i)*(sum(D(min(n0):max(n0),i).^2)/(length(D(min(n0):max(n0)))*(sum((D(min(n0):max(n0),i)-mean((D(min(n0):max(n0),i)))).^2))))^.5; %95% C.I. on time
    Time(i,1)=sqrt(m(2,i));                                            %calculate travel time based on y-int
%     Time(i,2)=(T95(i)/m(2,i))*Time(i,1);                               %propagate uncertainty
    Time(i,2)=0.5*(T95(i)/m(2,i))*Time(i,1);
end

%% Dix velocity conversion
Vdix=zeros(rflx,1);                 %create an empty variabe for Vdix
Vdix(1)=Vel(1);                     %layer 1 velocity does not need Dix correction
depth=zeros(rflx,1);                %create an empty variable for depth
depth(1)=Vel(1)*(Time(1)/2);        %depth of first reflection interface does not need dix correction    
for i=1:rflx-1                      %cycle through reflectors
    Vdix(i+1)=(((Vel(i+1,1)^2*Time(i+1,1))-(Vel(i,1)^2*Time(i,1)))/(Time(i+1,1)-Time(i,1)))^.5;  %Dix equation correctio for velocity
    depth(i+1)=Vdix(i+1)*(Time(i+1,1)-Time(i,1))/2;                                            %Dix corrected depths
end

%out = [10.*Vdix' depth'];
Vdix = Vdix';
depth = depth';


