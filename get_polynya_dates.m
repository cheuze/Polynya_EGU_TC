clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generate the polynya start dates (and location) from NSIDC data, using a
% sea ice concentration threshold.
% This threshold can be modified by the user (currently 60%).
% Requires the user-generated stereographic horizontal grid.
%
% Also features an example code for visual verification of the presence of
% a polynya.
% Plotting requires m_map
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seaicethres=60; %sea ice concentration threshold to detect polynya


% loads the latitude and longitude grids and subselect the polynya-prone
% area 6W-12E, 68S to 60S 
lat=importdata('lat_nsdic.dat');
lon=importdata('lon_nsdic.dat');
lon(lon>180)=lon(lon>180)-360; %moves to a -180:180 grid

posnsidc=find(lon>=-6 & lon<=12 & lat>=-68 & lat<=-60);
lon1=lon(posnsidc); lat1=lat(posnsidc);


% Code really begins here
filensidc=dir('bt_*s.bin');
datensidc=NaN(length(filensidc),1);

compt=1; %counter for number of polynyas
savedate=0; %counter to indicate whether you already are in a polynya
for ifile=1:length(filensidc)
    
    % Load NSIDC data and make them human-readable (in %)
    fid=fopen(filensidc(ifile).name);
    step0=fread(fid);
    fclose(fid); clear fid
    step1(:,1)=step0(1:2:end); step1(:,2)=step0(2:2:end); clear step0
    for ip=1:size(step1,1)
    step1(ip,3)=typecast(uint8(step1(ip,1:2)),'uint16');
    end
    step2=reshape(step1(:,3),[316 332]); clear step1
    step2=flipud(step2'); %now it has the same dimensions as lat/lon
    
    step2(step2==1200)=NaN; %land
    step2=step2./10; %now it's in %
    
    % Produce the date informations
    date=str2double(filensidc(ifile).name(4:11));
    yr=floor(date./10000);
    mth=floor((date-10000*yr)./100); dd=date-10000*yr-100*mth; 
    doy=day(datetime(yr,mth,dd),'dayofyear'); clear dd

    if mth>=7 && mth<=10 && nanmin(step2(posnsidc))<=seaicethres
        if compt==1 || doy~=savedate+1
        pos=find(step2(posnsidc)<=seaicethres);
        datepol(compt)=date;            
        lonpol{compt}=lon1(pos);
        latpol{compt}=lat1(pos);
        compt=compt+1;
        clear pos            
        end
        savedate=doy;
        
       % Uncomment below for plotting 
%         junk2(junk2<=15)=NaN;
%         f=figure('Units','normalized','Outerposition',[0 0 1 1],'Visible','off');
%         m_proj('lambert','lat',[-72 -55],'lon',[-10 15])
%         m_pcolor(lon,lat,junk2); shading flat; colorbar
%         m_grid('linest','-')
%         m_coast('Color','k');
%         caxis([15 100])
%         title([num2str(date) ' NSIDC'])

    end    
    clear step2 date mth yr doy    
end


%I recommend you save only after visual verification



