clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generate the cloud masks for APP comparable to MYD35_L2 data.
% Produces three masks, one per criterion in the literature:
%   1- T4 < 245 K
%   2- |T34| > 2 K, where T34 = T3b - T4; 
%   3- T45 > 2 K or T45 < 0K, where T45 = T4 - T5.
% As explained in the manuscript, we lowered the criterion for mask 2 after 
% comparison with MYD35_L2, so now
%   2- |T34| > 1.5 K, where T34 = T3b - T4; 
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cd('/media/HDD2/Infrared/APP/')


for iyr=1982:2019
    cloud_tests=NaN(300,300,366,3); %lon x lat x doy x mask
    %1 if clear, 0 if cloud, NaN if not determined, as in MODIS
    
    cd([num2str(iyr) '/'])
    fileZ=dir('Polar-APP_*.nc');
    if ~isempty(fileZ)
        for ifile=1:length(fileZ)
            YYYY=str2double(fileZ(ifile).name(29:32));
            MM=str2double(fileZ(ifile).name(33:34));
            DD=str2double(fileZ(ifile).name(35:36));
            doy=day(datetime(YYYY,MM,DD),'dayofyear'); clear YYYY MM DD
            
            try
                %directly loading only polynya prone area (lon=-6:12; lat=-68:-60)
                temp_3b=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch3',[700 100 1],[300 300 1]);
                temp_4=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch4',[700 100 1],[300 300 1]);
                temp_5=ncread(fileZ(ifile).name,'fcdr_brightness_temperature_ch5',[700 100 1],[300 300 1]);
                
                % removing impossible values
                temp_3b(temp_3b<240 | temp_3b>280)=NaN;
                temp_4(temp_4<240 | temp_4>280)=NaN;
                temp_5(temp_5<240 | temp_5>280)=NaN;
                
                %first test
                pos0=find(~isnan(temp_4) & temp_4<245);
                pos1=find(~isnan(temp_4) & temp_4>=245);
                mask_temp=NaN(300,300); mask_temp(pos0)=0; mask_temp(pos1)=1;
                cloud_tests(:,:,doy,1)=mask_temp; clear pos0 pos1 mask_temp
                
                %second test
                T34=temp_3b-temp_4;
                pos0=find(~isnan(T34) & abs(T34)>1.5);
                pos1=find(~isnan(T34) & abs(T34)<=1.5);
                mask_temp=NaN(300,300); mask_temp(pos0)=0; mask_temp(pos1)=1;
                cloud_tests(:,:,doy,2)=mask_temp; clear pos0 pos1 mask_temp
                
                %third test
                T45=temp_4-temp_5;
                pos0=find(~isnan(T45) & (T45>2 | T45<0));
                pos1=find(~isnan(T45) & T45>=0 & T45<=2);
                mask_temp=NaN(300,300); mask_temp(pos0)=0; mask_temp(pos1)=1;
                cloud_tests(:,:,doy,3)=mask_temp; clear pos0 pos1 mask_temp
                
                clear temp_* T34 T45 doy
                
                
            catch
            % safeguard in case some files are corrupted / not correctly downloaded
            end
        end
    end %if folder not empty (download fail)
    cd ..
    clear fileZ
    
    save(['/media/HDD2/Infrared/cloud_APP_15_' num2str(iyr) '.mat'],'cloud_tests','-v7.3')
    
end %iyr



