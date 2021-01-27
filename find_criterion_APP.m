clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The whole analysis of section 3.2 in one script:
%   1- computes the geographical statistics
%   2- computes the climatology - we show here also how to do it using only 
% the dates not affected by a polynya (not used in paper)
%   3- compute the 15-day minimum, maximum, sum and standard-deviation 
% The user can select the number of days before a polynya they will use by
% changing the value of daysprior
%
% Requires the brightness temperatures T3_map, T4_map and T5_map, and their 
% time timeZ_map as produced by prepare_APP.m;
% Requires the polynya start dates produced by get_polynya_dates (here
% referred to as start60 to remind the reader of the 60% threshold);
%
% Written by C. Heuzé (celine.heuze@gu.se)
% Last updated 27 January 2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

daysprior=15; %days before a polynya one is using

% load the *_map as produced by prepare_APP.m
% load the polynya dates start60, as produced by get_polynya_dates.m

%life will be easier with doy instead of just the dates
timeZ_map(:,4)=day(datetime(timeZ_map(:,1),timeZ_map(:,2),timeZ_map(:,3)),'dayofyear'); 


%% geographical statistics - not elegant at all, I know

%median
geomedianZ(:,1)=nanmedian(reshape(T3_map,[300*300 size(T3_map,3)]),1);
geomedianZ(:,2)=nanmedian(reshape(T4_map,[300*300 size(T3_map,3)]),1);
geomedianZ(:,3)=nanmedian(reshape(T5_map,[300*300 size(T3_map,3)]),1);
geomedianZ(:,4)=nanmedian(reshape(T3_map-T4_map,[300*300 size(T3_map,3)]),1);
geomedianZ(:,5)=nanmedian(reshape(T4_map-T5_map,[300*300 size(T3_map,3)]),1);
geomedianZ(:,6)=nanmedian(reshape(T3_map-T5_map,[300*300 size(T3_map,3)]),1);

%minimum
geominZ(:,1)=nanmin(reshape(T3_map,[300*300 size(T3_map,3)]),[],1);
geominZ(:,2)=nanmin(reshape(T4_map,[300*300 size(T3_map,3)]),[],1);
geominZ(:,3)=nanmin(reshape(T5_map,[300*300 size(T3_map,3)]),[],1);
geominZ(:,4)=nanmin(reshape(T3_map-T4_map,[300*300 size(T3_map,3)]),[],1);
geominZ(:,5)=nanmin(reshape(T4_map-T5_map,[300*300 size(T3_map,3)]),[],1);
geominZ(:,6)=nanmin(reshape(T3_map-T5_map,[300*300 size(T3_map,3)]),[],1);

%maximum
geomaxZ(:,1)=nanmax(reshape(T3_map,[300*300 size(T3_map,3)]),[],1);
geomaxZ(:,2)=nanmax(reshape(T4_map,[300*300 size(T3_map,3)]),[],1);
geomaxZ(:,3)=nanmax(reshape(T5_map,[300*300 size(T3_map,3)]),[],1);
geomaxZ(:,4)=nanmax(reshape(T3_map-T4_map,[300*300 size(T3_map,3)]),[],1);
geomaxZ(:,5)=nanmax(reshape(T4_map-T5_map,[300*300 size(T3_map,3)]),[],1);
geomaxZ(:,6)=nanmax(reshape(T3_map-T5_map,[300*300 size(T3_map,3)]),[],1);

%standard deviation
geostdZ(:,1)=nanstd(reshape(T3_map,[300*300 size(T3_map,3)]),[],1);
geostdZ(:,2)=nanstd(reshape(T4_map,[300*300 size(T3_map,3)]),[],1);
geostdZ(:,3)=nanstd(reshape(T5_map,[300*300 size(T3_map,3)]),[],1);
geostdZ(:,4)=nanstd(reshape(T3_map-T4_map,[300*300 size(T3_map,3)]),[],1);
geostdZ(:,5)=nanstd(reshape(T4_map-T5_map,[300*300 size(T3_map,3)]),[],1);
geostdZ(:,6)=nanstd(reshape(T3_map-T5_map,[300*300 size(T3_map,3)]),[],1);


%% Climatologies

% standard climatology as used in paper
clim_geomed=NaN(365,6); %doy x band T3b | T4 | T5 | T34 | T45 | T35
for doy=1:365
    posAPP=find(timeZ_map(:,4)==doy);
    clim_geomed(doy,:)=nanmedian(geomedianZ(posAPP,:),1);
end


% climatologies using only the days not affected by a polynya

% years affected = 1 | years not in an event range = 0
range60(:,1)=start60(:,1); %start60(:,1) contains the years; start60(:,4), the start doy
for ip=0:daysprior
    range60(:,ip+2)=start60(:,4)-ip;
end

yearsPOL=zeros(366,38);%0 if not in daysprior:polynya range, 1 if yes
for doy=1:366
    for iyr=1982:2019
        if ~isempty(find(range60(:,1)==iyr & range60(:,2:end)==doy, 1)) %if in polynya range
            yearsPOL(doy,iyr-1981)=1;
        end
    end
end

geomedian_nopol=NaN(6,366);  %6 bands, doy
for idoy=1:366
    geomedian_thatday=NaN(6,38); %at most one value per year
    compt_nopol=1;
    for iyr=1982:2019
        % get position in APP
        posAPP=find(timeZ_map(:,1)==iyr & timeZ_map(:,4)==idoy);
        if ~isempty(posAPP)
            % check value in yearsPOL
            if yearsPOL(doys_withpol(idoy),iyr-1981)==0 % not in polynya range
                geomedian_thatday(:,compt_nopol)=squeeze(geomedianZ(posAPP,:));
                compt_nopol=compt_nopol+1;
            end            
        end
        clear posAPP
    end
    geomedian_nopol(:,idoy)=nanmedian(geomedian_thatday,2);
    % as we show that the polynya values are lower than the climatology, we
    % recommend that you also try with a nanmin here instead of nanmedian
    clear geomedian_thatday compt_nopol
end

%save if needed


%% The daysprior-minimum, maximum, sum and standard deviation

%for each event
% critseries for daysprior:event, for e.g. Fig 7
% critminmax_* for daysprior:event, for Figs 4 and 5

% critminmax_withpol for days in range daysprior:start of event
% critminmax_no for same doys, in years not affected by polynya

%6 band/ano x 4 crit x daysprior+1 days x length(start60) events
critseries=NaN(6,4,daysprior+1,length(start60));
%6 bands x 4 geo statistics x 4 temporal criteria x length(start60)
critminmax_withpol=NaN(12,4,4,length(start60)); %3rd dim= min then max then sum then std
critminmax_nopol=critminmax_withpol;


for iev=1:length(start60)
    %find if date and 15 days prior are in the APP series
    pos2=find(start60(iev,1)==timeZ_map(:,1) & start60(iev,4)==timeZ_map(:,4)); %day of the polynya
    pos1=find(start60(iev,1)==timeZ_map(:,1) & start60(iev,4)-daysprior==timeZ_map(:,4));
    
    if ~isempty(pos2) && ~isempty(pos1)
        %for each criterion on each band, we need
        % a series where their position daysprior:pol is recorded
        critseries(:,1,:,iev)=geomedianZ(pos1:pos2,:)';
        critseries(:,2,:,iev)=geominZ(pos1:pos2,:)';
        critseries(:,3,:,iev)=geomaxZ(pos1:pos2,:)';
        critseries(:,4,:,iev)=geostdZ(pos1:pos2,:)';
        
        %just min and max for each
        critminmax_withpol(:,:,1,iev)=nanmin(squeeze(critseries(:,:,:,iev)),[],3);
        critminmax_withpol(:,:,2,iev)=nanmax(squeeze(critseries(:,:,:,iev)),[],3);
        critminmax_withpol(:,:,3,iev)=nansum(squeeze(critseries(:,:,:,iev)),3);
        critminmax_withpol(:,:,4,iev)=nanstd(squeeze(critseries(:,:,:,iev)),[],3);
        
        % but also for similar doy where yearsPOL=0
        compt_nopol=1;
        for iyr=1982:2019
            %locate position in APP
            posno2=find(iyr==timeZ_map(:,1) & start60(iev,4)==timeZ_map(:,4));
            posno1=find(iyr==timeZ_map(:,1) & start60(iev,4)-daysprior==timeZ_map(:,4));
            
            
            if isempty(find(yearsPOL(start60(iev,4)-daysprior:start60(iev,4),iyr-1981)~=0, 1))
                %sum does not work yet as depends on nb days where not empty
                
                storeme(1:6,1,1,compt_nopol)=squeeze(nanmin(geomedianZ(posno1:posno2,:),[],1));
                storeme(1:6,1,2,compt_nopol)=squeeze(nanmax(geomedianZ(posno1:posno2,:),[],1));
                storeme(1:6,1,3,compt_nopol)=squeeze(nansum(geomedianZ(posno1:posno2,:),1));
                storeme(1:6,1,4,compt_nopol)=squeeze(nanstd(geomedianZ(posno1:posno2,:),[],1));
                
                storeme(1:6,2,1,compt_nopol)=squeeze(nanmin(geominZ(posno1:posno2,:),[],1));
                storeme(1:6,2,2,compt_nopol)=squeeze(nanmax(geominZ(posno1:posno2,:),[],1));
                storeme(1:6,2,3,compt_nopol)=squeeze(nansum(geominZ(posno1:posno2,:),1));
                storeme(1:6,2,4,compt_nopol)=squeeze(nanstd(geominZ(posno1:posno2,:),[],1));
                
                storeme(1:6,3,1,compt_nopol)=squeeze(nanmin(geomaxZ(posno1:posno2,:),[],1));
                storeme(1:6,3,2,compt_nopol)=squeeze(nanmax(geomaxZ(posno1:posno2,:),[],1));
                storeme(1:6,3,3,compt_nopol)=squeeze(nansum(geomaxZ(posno1:posno2,:),1));
                storeme(1:6,3,4,compt_nopol)=squeeze(nanstd(geomaxZ(posno1:posno2,:),[],1));
                
                storeme(1:6,4,1,compt_nopol)=squeeze(nanmin(geostdZ(posno1:posno2,:),[],1));
                storeme(1:6,4,2,compt_nopol)=squeeze(nanmax(geostdZ(posno1:posno2,:),[],1));
                storeme(1:6,4,3,compt_nopol)=squeeze(nansum(geostdZ(posno1:posno2,:),1));
                storeme(1:6,4,4,compt_nopol)=squeeze(nanstd(geostdZ(posno1:posno2,:),[],1));
                
                compt_nopol=compt_nopol+1;
            end
            clear posno1 posno2
        end
        critminmax_nopol(:,:,1,iev)=nanmin(squeeze(storeme(:,:,1,:)),[],3);
        critminmax_nopol(:,:,2,iev)=nanmax(squeeze(storeme(:,:,2,:)),[],3);
        critminmax_nopol(:,:,3,iev)=nanmin(squeeze(storeme(:,:,3,:)),[],3); %min because we expect pol to be even lower
        critminmax_nopol(:,:,4,iev)=nanmin(squeeze(storeme(:,:,4,:)),[],3);
        clear storeme compt_nopol
        
    end %if period daysprior:day polynya begins is in APP
    clear pos1 pos2
end

% save if needed

