clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% For the period common to MYD35_L2 and APP (2002-2018), compute:
%   1- the number of pixels where the comparison is possible;
%   2- the number of pixels that both methods detect as clear;
%   3- the number of pixels that both methods detect as cloudy;
%   4- the number of pixels that APP detects as clear but MYD35_L2 as cloudy
%   5- the number of pixels that APP detects as cloudy but MYD35_L2 as clear
%
% Also includes a plotting script for figures similar to supp Fig A1.
%
% Requires APP cloud masks produced by cloud_from_APP.m;
% Requires MYD35_L2 cloud masks, on same grid and at same time as APP cloud
% masks, produced by cloud_from_MYD35.m;
% Plotting requires the m_map package.
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mateval=NaN(17,366,5); % year x doy x 5 queries
for iyr=2002:2018

load(['/media/HDD2/Infrared/MYD35_L2/test00_' num2str(iyr) '.mat'])
load(['/media/HDD2/Infrared/cloud_APP_15_' num2str(iyr) '.mat'])

for chosendoy=1:366
    if ~isempty(find(squeeze(mat_cloudmask(:,:,chosendoy,1))~=0,1))
        statusflag=squeeze(mat_cloudmask(:,:,chosendoy,1));
        cloudMODIS=squeeze(mat_cloudmask(:,:,chosendoy,2));
        statusflag(statusflag==0)=NaN;
        cloudMODIS=cloudMODIS./statusflag;
        cloudMODIS(~isnan(cloudMODIS) & cloudMODIS~=0)=1;
        
        cloudAPP=squeeze(nansum(cloud_tests(:,:,chosendoy,:),4))./size(cloud_tests,4);
        cloudAPP(cloudAPP<1)=0; %<- even though T34 test not always here, looks better
        cloudAPP(isnan(statusflag))=NaN;
        
        mateval(iyr-2001,chosendoy,1)=numel(find(~isnan(statusflag)));
        mateval(iyr-2001,chosendoy,2)=numel(find(cloudMODIS==1 & cloudAPP==1));
        mateval(iyr-2001,chosendoy,3)=numel(find(cloudMODIS==0 & cloudAPP==0));
        mateval(iyr-2001,chosendoy,4)=numel(find(cloudMODIS==0 & cloudAPP==1));
        mateval(iyr-2001,chosendoy,5)=numel(find(cloudMODIS==1 & cloudAPP==0));

    end
end %doy

clear cloudMODIS cloudAPP cloud_tests statusflag mat_cloudmask 

end %iyr

%save here or directly analyse the output

%% plotting testing
clear all
close all

% user must decide on a day of year (doy) and year to plot:
chosendoy=253;
chosenyear=2014; 

% load the APP data of that day and remove impossible values

[yyyy,mm,dd]=datevec(datenum(chosenyear,1,chosendoy));
cd(['/media/HDD2/Infrared/APP/' num2str(yyyy) '/'])
fileAPP=dir(['Polar-APP_*d' num2str(10000*yyyy+100*mm+dd) '_*.nc']);

temp_3b=ncread(fileAPP(1).name,'fcdr_brightness_temperature_ch3',[700 100 1],[300 300 1]);
temp_4=ncread(fileAPP(1).name,'fcdr_brightness_temperature_ch4',[700 100 1],[300 300 1]);
temp_5=ncread(fileAPP(1).name,'fcdr_brightness_temperature_ch5',[700 100 1],[300 300 1]);

temp_3b(temp_3b<240 | temp_3b>280)=NaN;
temp_4(temp_4<240 | temp_4>280)=NaN;
temp_5(temp_5<240 | temp_5>280)=NaN;
T34=temp_3b-temp_4; T45=temp_4-temp_5;


% load the cloud masks

load(['/media/HDD2/Infrared/MYD35_L2/test00_' num2str(yyyy) '.mat'])
load(['/media/HDD2/Infrared/cloud_APP_' num2str(yyyy) '.mat'])

statusflag=squeeze(mat_cloudmask(:,:,chosendoy,1));
cloudMODIS=squeeze(mat_cloudmask(:,:,chosendoy,2));
statusflag(statusflag==0)=NaN;
cloudMODIS=cloudMODIS./statusflag;
% If investigating clouds and/or sources of errors, do not include the next
% 4 lines. If producing easier-to-interpret plots, keep them
cloudMODIS(~isnan(cloudMODIS) & cloudMODIS~=0)=1;
cloudAPP=squeeze(nansum(cloud_tests(:,:,chosendoy,:),4))./size(cloud_tests,4);
cloudAPP(cloudAPP<1)=0; 
cloudAPP(isnan(statusflag))=NaN;

% type of code to plot where the two methods agree and disagree
figure;
m_proj('lambert','lat',[-68 -60],'lon',[-6 12])
m_scatter(lon_APP(cloudMODIS==1 & cloudAPP==1),lat_APP(cloudMODIS==1 & cloudAPP==1),5,'c')
hold on
m_scatter(lon_APP(cloudMODIS==0 & cloudAPP==0),lat_APP(cloudMODIS==0 & cloudAPP==0),5,[.5 .5 .5])
m_scatter(lon_APP(cloudMODIS==0 & cloudAPP==1),lat_APP(cloudMODIS==0 & cloudAPP==1),5,'r')
m_scatter(lon_APP(abs(T34)>1.5 & abs(T34)<2 & cloudMODIS==0 & cloudAPP==1),lat_APP(abs(T34)>1.5 & abs(T34)<2 & cloudMODIS==0 & cloudAPP==1),4,[.8 0 0],'fill')
m_scatter(lon_APP(cloudMODIS==1 & cloudAPP==0),lat_APP(cloudMODIS==1 & cloudAPP==0),5,'k')
m_grid('linest','-')

% type of code to plot APP data (here T34) overlaid with a cloud mask
figure; hold on
m_proj('lambert','lat',[-68 -60],'lon',[-6 12])
m_pcolor(lon_APP,lat_APP,T34); shading flat; colorbar
caxis([-2 2])
colormap(gray)
m_scatter(lon_APP(cloudMODIS==0 & cloudAPP==1),lat_APP(cloudMODIS==0 & cloudAPP==1),1,'g','fill')
m_grid('linest','-')

