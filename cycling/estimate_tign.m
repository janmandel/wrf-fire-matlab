function tign = estimate_tign(ps)
%tries to draw a reasonable tign based on locations and times of detections
% inputs - locations nd times of detections, sorted by increasing time
%          ps = graph_dets(w,0) or ps = cluster_paths(w,0)


times = ps.points(:,3);
% lats = ps.idx(:,1);
% lons = ps.idx(:,2);
lats = ps.points(:,1);
lons = ps.points(:,2);

%sort detections by time
[st_1,st_2]=sort(times);
lats = lats(st_2);
lons = lons(st_2);
times = times(st_2);


n = length(times);
end_time = max(max(times),ps.red.end_datenum);
start_time = min(times);
total_time = ceil(end_time-start_time);

tign = end_time*ones(size(ps.red.fxlong));
temp_tign = tign;
lons_set = [];
lats_set = [];
times_set = [];

% for i = 1:total_time
%     pt_set = (times-start_time) < i;
%     lons_set = [lons_set;lons(pt_set)];
%     lats_set = [lats_set;lats(pt_set)];
% %    times_set = [times_set;times(pt_set)];
% %     lons_set = lons(pt_set);
% %     lats_set = lats(pt_set);
%     times_set = times(pt_set);
%     %figure,scatter3(lons_set,lats_set,times_set)
%     [in,on] = inpolygon(ps.red.fxlat,ps.red.fxlong,lats_set,lons_set);
%     temp_tign(in) = max(times_set);
%     temp_tign(~in) = end_time;
%     tign = min(tign,temp_tign);
%     %tign = imgaussfilt(tign,3);
%     mesh(ps.red.fxlong,ps.red.fxlat,tign)
% end

%going by every 30 detections
for i = 1:30:n
    pt_set = times <= times(i);
    lons_set = [lons_set;lons(pt_set)];
    lats_set = [lats_set;lats(pt_set)];
%    times_set = [times_set;times(pt_set)];
%     lons_set = lons(pt_set);
%     lats_set = lats(pt_set);
    times_set = times(pt_set);
    %figure,scatter3(lons_set,lats_set,times_set)
    [in,on] = inpolygon(ps.red.fxlat,ps.red.fxlong,lats_set,lons_set);
    temp_tign(in) = max(times_set);
    temp_tign(~in) = end_time;
    tign = min(tign,temp_tign);
    %tign = imgaussfilt(tign,1/8);
    
end

tign = imgaussfilt(tign,1)-0.25;
figure,mesh(ps.red.fxlong,ps.red.fxlat,tign);
hold on
scatter3(lons,lats,times,'*r')

end %function