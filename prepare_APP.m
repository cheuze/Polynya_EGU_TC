clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generate one file combining all APP T3b, T4 and T5 brightness temperatures.
% Mask as cloud if one of these three criteria is true:
%   1- T4 < 245 K
%   2- |T34| > 1.5 K, where T34 = T3b - T4;
%   3- T45 > 2 K or T45 < 0K, where T45 = T4 - T5.
% This code does not do much more but puts the data in the right format for
% the whole section 3.2 analysis.
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


comptT=1; %time counter
%initiate matrices to store data; maybe more than 365 days *38 years points
T3_map=NaN(300,300,365*38); T4_map=T3_map; T5_map=T3_map;
timeZ_map=NaN(365*38,3);

for iyr=1982:2019
    cd([num2str(iyr) '/'])
    fileZ=dir('Polar-APP_*.nc');
    if ~isempty(fileZ)
        for ifile=1:length(fileZ)
            date=str2double(fileZ(ifile).name(29:36));
            
            
            %directly load only polynya prone area (lon=-6:12; lat=-68:-60)
            temp_3b=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch3',[700 100 1],[300 300 1]);
            temp_4=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch4',[700 100 1],[300 300 1]);
            temp_5=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch5',[700 100 1],[300 300 1]);
            if comptT==1 %if this is the first instance, load latitude and longitude
                lat_map=double(ncread(fileZ(ifile).name,'latitude',[700 100],[300 300]));
                lon_map=double(ncread(fileZ(ifile).name,'longitude',[700 100],[300 300]));
            end
            
            % remove impossible values
            temp_3b(temp_3b<240 | temp_3b>280)=NaN;
            temp_4(temp_4<240 | temp_4>280)=NaN;
            temp_5(temp_5<240 | temp_5>280)=NaN;
            
            %Applies cloud masks
            temp_3b(temp_4<245)=NaN;
            temp_5(temp_4<245)=NaN;
            temp_4(temp_4<245)=NaN;
            T34=temp_3b-temp_4; T45=temp_4-temp_5;
            temp_3b(abs(T34)>1.5 & ~isnan(T34))=NaN;temp_4(abs(T34)>1.5 & ~isnan(T34))=NaN;temp_5(abs(T34)>1.5 & ~isnan(T34))=NaN;
            temp_3b(T45>2 & ~isnan(T45))=NaN;temp_4(T45>2 & ~isnan(T45))=NaN;temp_5(T45>2 & ~isnan(T45))=NaN;
            temp_3b(T45<0 & ~isnan(T45))=NaN;temp_4(T45<0 & ~isnan(T45))=NaN;temp_5(T45<0 & ~isnan(T45))=NaN;
            
            T3_map(:,:,comptT)=temp_3b;
            T4_map(:,:,comptT)=temp_4;
            T5_map(:,:,comptT)=temp_5;
            
            % generate a time matrix for later use
            timeZ_map(comptT,1)=iyr;
            timeZ_map(comptT,2)=floor((date-iyr*10000)./100);
            timeZ_map(comptT,3)=date-iyr*10000-timeZ_map(comptT,2)*100;
            comptT=comptT+1;
            %                 end
            
            clear temp_* T34 T45 pos
            
            clear date time_dec hours
            
        end
    end %if folder not empty (e.g. download fail)
    cd ..
    clear fileZ
    
    % I personally saved at the end of each year, but you do what you want
end %iyr

        
        




