function v = readl2data(prefix,file,file2,silent)
%v = readl2data(prefix,file,file2,silent)
%read L2 data and return v.lon v.lat v.data
% inputs:
%    prefix - string, path to directory with data files
%    file, file2 - strings, file names of geolocation and active fire dat,
%        respectively
%    silent - character to print output, optional
%
% output:
%    v      - struct, contains geolocation dat and fire mask.
fprintf('Reading l2 data\n')


pfile=[prefix,file];
pfile2=[prefix,file2];
%v=load(pfile);
if file(1) == 'M'
    fprintf('Reading Modis data\n')
    try
        v.lon = hdfread(pfile, 'MODIS_Swath_Type_GEO', 'Fields', 'Longitude');
        v.lat = hdfread(pfile, 'MODIS_Swath_Type_GEO', 'Fields', 'Latitude');
        v.data = hdfread(pfile2, '/fire mask', 'Index', {[1  1],[1  1],[size(v.lon)]});
        %v.frp = hdfread(pfile2, '/FP_power', 'Index', {[1  1],[1  1],[size(v.lon)]});
    catch
        warning('read error somewhere')
    end
else
    fprintf('Reading VIIRS data\n')
    fprintf('fires : %s \n',pfile2)
    fprintf('geo   : %s \n',pfile)
    try
        v.lon = h5read(pfile,'/HDFEOS/SWATHS/VNP_750M_GEOLOCATION/Geolocation Fields/Longitude');
        v.lat = h5read(pfile,'/HDFEOS/SWATHS/VNP_750M_GEOLOCATION/Geolocation Fields/Latitude');
        v.data = h5read(pfile2,'/fire mask');
    catch
        warning('read error somewhere')
    end
end


v.file=file2;
[v.time,v.timestr]=rsac2time(file);
if ~exist('silent','var'),
    fprintf('file name w/prefix    %s\n',pfile);
    fprintf('file name             %s\n',file);
    fprintf('image time            %s\n',datestr(v.time));
end


% from tif code
%[rows,cols]=size(v.data);
% geo=v.geotransform;
% Xpixel=[0:cols-1]+0.5;
% Ypixel=[0:rows-1]+0.5;
% v.lon = geo(1)+Xpixel*geo(2);
% v.lat = geo(4)+Ypixel*geo(6); %subtraction for camp

if any(v.data(:)<0 | v.data(:)>9),
    warning('Value out of range 0 to 9 for MODIS14 data')
end
for i=0:9,
    count(i+1)=sum(v.data(:)==i);
end


v.pixels.unknown= count(1)+count(2)+count(3)+count(7);
v.pixels.water  = count(4);
v.pixels.cloud  = count(5);
v.pixels.land   = count(6);
v.pixels.fire   = count(8:10);


if ~exist('silent','var'),
    % prints
%    fprintf('rows                  %i\n',rows)
%    fprintf('cols                  %i\n',cols)
%     fprintf('top left X            %19.15f\n',geo(1))
%     fprintf('W-E pixel resolution  %19.15f\n',geo(2))
%     fprintf('rotation, 0=North up  %19.15f\n',geo(3))
%     fprintf('top left Y            %19.15f\n',geo(4))
%     fprintf('rotation, 0=North up  %19.15f\n',geo(5))
%     fprintf('N-S pixel resolution  %19.15f\n',geo(6))
    fprintf('unprocessed/unknown   %i\n',v.pixels.unknown)
    fprintf('water                 %i\n',v.pixels.water)
    fprintf('land                  %i\n',v.pixels.land)
    fprintf('cloud                 %i\n',v.pixels.cloud)
    fprintf('low-confidence fire   %i\n',v.pixels.fire(1))
    fprintf('nominal-confid fire   %i\n',v.pixels.fire(2))
    fprintf('high-confidence fire  %i\n',v.pixels.fire(3))
end
% if geo(3)~=0 | geo(5)~=0,
%     error('rotation not supported')
%end
end