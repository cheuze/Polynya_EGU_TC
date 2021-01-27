clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generate the cloud masks comparable to APP from MYD35_L2 data:
%   - cloud criterion (as per MYD35_L2 userguide) = 00;
%   - select the local solar time interval 23-5 (3h either side of 2 am);
%   - interpolate onto APP horizontal grid;
%   - produce for each APP pixel number of MYD35_L2 images and number that
%   have a cloud.
% Requires that MYD35_L2 has undergone bit stripping using readmodis.py
% Requires geolocation files MYD03
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


year_select=2018;

addpath('~/codes_Infrared')

lon_APP=double(ncread('/media/HDD2/Infrared/APP/2002/Polar-APP_v02r00_Shem_0200_d20020101_c20180501.nc','longitude',[700 100],[300 300]));
lat_APP=double(ncread('/media/HDD2/Infrared/APP/2002/Polar-APP_v02r00_Shem_0200_d20020101_c20180501.nc','latitude',[700 100],[300 300]));

mat_cloudmask=zeros(size(lon_APP,1),size(lon_APP,2),366,2); % lon lat doy totalpoints/nbclouds

cd('/media/HDD2/Infrared/MYD35_L2/')

fileZ=dir(['MYD35_L2.A' num2str(year_select) '*.nc']); 

for ifile=1:length(fileZ) 
    YYYY=fileZ(ifile).name(11:14);
    doy=fileZ(ifile).name(15:17);
    %convert doy to MM/DD
    [~,MM,DD]=datevec(datenum(str2double(YYYY),1,str2double(doy)));
    if MM>9
    MM=num2str(MM);
    else
    MM=['0' num2str(MM)];    
    end    
    hh=fileZ(ifile).name(19:20);
    min=fileZ(ifile).name(21:22);
    
    %convert UTC to solar time
    UTC=[YYYY '/' MM '/' num2str(DD) ' ' hh ':' min ':00'];
    
    [SAT,~] = UTC2SolarApparentTime(UTC,3);
    clear UTC MM DD YYYY hh min 
    
    [~,MM,DD,hh,~]=datevec(SAT); clear SAT
    
    if hh>=23 && (MM~=12 && DD~=31) %31st december problematic and out of our study period -> ignore
        savedoy=str2double(doy)+1;
    elseif hh<5 
        savedoy=str2double(doy);
    else
        savedoy=0;
    end
    
    if savedoy~=0             
        try 
            lon=ncread(fileZ(ifile).name,'longitude');
            lat=ncread(fileZ(ifile).name,'latitude');
        catch
            filegeo=dir(['MYD03.A' fileZ(ifile).name(11:22) '.*.hdf']);
            if ~isempty(filegeo) %add geolocation lon and lat to MYD35_L2....nc
            lat=hdfread(filegeo(1).name,'Latitude');
            lon=hdfread(filegeo(1).name,'Longitude');
            nccreate(fileZ(ifile).name,'latitude','Dimensions',{'x',size(lon,1),'y',size(lon,2)});
            nccreate(fileZ(ifile).name,'longitude','Dimensions',{'x',size(lon,1),'y',size(lon,2)});
            ncwrite(fileZ(ifile).name,'latitude',double(lat));
            ncwrite(fileZ(ifile).name,'longitude',double(lon));
            end
        end
        
        if exist('lon','var')
        status_flag=double(ncread(fileZ(ifile).name,'status_flag'))'; %must be 1, determined
        cloud1=double(ncread(fileZ(ifile).name,'cloudmask_flag_bit1'))';%must be 0, cloudy
        cloud2=double(ncread(fileZ(ifile).name,'cloudmask_flag_bit2'))'; %must also be 0, cloudy
        %the others bits we do not need for this study
        
        if size(lon,1)==size(cloud1,2)
            lon=lon';
            lat=lat';
        end
        
        countme=status_flag; countme(countme==0)=NaN;
        cloud00=ones(size(cloud1));
        cloud00(find(status_flag==0 | (cloud1==0 & cloud2==0)))=NaN;      

        %interpolation onto APP grid
        fonfon=scatteredInterpolant(double(lon(:)),double(lat(:)),double(cloud00(:)),'linear','none');
        newcloud=fonfon(lon_APP,lat_APP);
        newcloud(isnan(newcloud))=0;
        mat_cloudmask(:,:,savedoy,2)=mat_cloudmask(:,:,savedoy,2)+newcloud;
        clear fonfon
        fonfon=scatteredInterpolant(double(lon(:)),double(lat(:)),double(countme(:)),'linear','none');
        countmeint=fonfon(lon_APP,lat_APP);
        countmeint(isnan(countmeint))=0;
        mat_cloudmask(:,:,savedoy,1)=mat_cloudmask(:,:,savedoy,1)+ceil(countmeint);       
        end %if we have geolocation info
        clear lat lon status_flag cloud1 fonfon newcloud countme countmeint cloud00 cloud2 filegeo 
        
    end %if at the right time   

    clear doy MM DD hh savedoy
end

save(['test00_' num2str(year_select) '.mat'],'mat_cloudmask','lon_APP','lat_APP','-v7.3')

