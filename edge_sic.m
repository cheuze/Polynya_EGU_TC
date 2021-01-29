clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generate the polynya areas from NSIDC data, using a  sea ice concentration 
% threshold.
% This threshold can be modified by the user (currently 60%).
% Requires the user-generated stereographic horizontal grid.
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seaicethres=60; %sea ice concentration threshold to detect polynya

latsic=importdata('test_lat_nsdic.dat');
lonsic=importdata('test_lon_nsdic.dat');
lonsic(lonsic>180)=lonsic(lonsic>180)-360;

mask=zeros(size(latsic));
mask(latsic>-68 & latsic<-60 & lonsic>-6 & lonsic<12)=1; %polyanya-prone area

fileZ=dir('bt_*s.bin');

polarea_nsidc=zeros(length(fileZ),4);time_polarea_nsidc=zeros(length(fileZ),1);

for ifile=1:length(fileZ)
    date=str2double(fileZ(ifile).name(4:11));
    yr=floor(date./10000);
    mth=floor((date-10000*yr)./100);
    
    fid=fopen(fileZ(ifile).name);
    junk0=fread(fid);
    fclose(fid); clear fid
    junk1(:,1)=junk0(1:2:end); junk1(:,2)=junk0(2:2:end); clear junk0
    for ip=1:size(junk1,1)
        junk1(ip,3)=typecast(uint8(junk1(ip,1:2)),'uint16');
    end
    junk2=reshape(junk1(:,3),[316 332]); clear junk1
    junk2=flipud(junk2'); %now it has the same dimensions as lat/lon
    
    junk2(junk2==1200)=NaN; %land
    step0=junk2./10; %now it's in %, and the code can be same as Bremen
    clear junk0 junk1 junk2
    step1=step0;
    step1(step1<seaicethres)=1; %polynya set to 1
    step1(step1>=seaicethres)=0;%ice set to 0
    step1(isnan(step1))=0; %coast set to 0, like ice
    time_polarea_nsidc(ifile,1)=str2double(fileZ(ifile).name(4:11));
    
    if ~isempty(find(step1==1 & mask==1)) && mth>=7 && mth<=10
        step2=edge(step1,'log');
        step2=logical(step2.*mask);%new as of 10 April
        ipol=1;
        step3 = bwpropfilt(step2,'area',1);
        while ~isempty(find(step3==1,1))
            step4=imfill(step3,'holes'); %fills open ocean with 0 and ice with 1
            step4(step4==1 & step3==1)=0;
            step5=double(step4).*step1.*mask;
            if numel(find(step5==1))>0
                polarea_nsidc(ifile,ipol)=numel(find(step5==1)).*25^2; %area in km2
            end
            step2=logical(step2-step3);
            step3=bwpropfilt(step2,'area',1);
            ipol=ipol+1;
        end %while loop
    end
    
    clear step* date yr mth
end


clear mask latsic lonsic fileZ

%save the polynya extent timeseries

