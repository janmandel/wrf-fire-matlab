function p=detect_fit_linesearch(prefix)
% from a copy of barker2

disp('input data')
    % to create conus.kml:
    % download http://firemapper.sc.egov.usda.gov/data_viirs/kml/conus_hist/2012/conus_20120914.kmz
    % and gunzip 
    % 
    % to create w.mat:
    % run Adam's simulation, currently results in
    % /share_home/akochans/NASA_WSU/wrf-fire/WRFV3/test/em_barker_moist/wrfoutputfiles_live_0.25
    % then in Matlab
    % f='wrfout_d05_2012-09-15_00:00:00'; 
    % t=nc2struct(f,{'Times'},{});  n=size(t.times,2);  
    % w=nc2struct(f,{'TIGN_G','FXLONG','FXLAT','UNIT_FXLAT','UNIT_FXLONG','Times',NFUEL_CAT'},{'DX','DY'},n);
    % save ~/w.mat w    
    % 
    % fuels.m is created by WRF-SFIRE at the beginning of the run
    
    % ****** REQUIRES Matlab 2013a - will not run in earlier versions *******
    
    
    v=read_fire_kml('conus_viirs.kml');
    detection='VIIRS';        
    if ~exist('prefix','var'),
        prefix='viirs';
    end
    
    a=load('w');w=a.w;
    if ~isfield(w,'dx'),
        w.dx=444.44;
        w.dy=444.44;
        warning('fixing up w for old w.mat file from Barker fire')
    end
    dx=w.dx;
    dy=w.dy;
    
    fuel.weight=0; % just to let Matlab know what fuel is going to be at compile time
    fuels


disp('subset and process inputs')
    
    % establish boundaries from simulations
    
    sim.min_lat = min(w.fxlat(:));
    sim.max_lat = max(w.fxlat(:));
    sim.min_lon = min(w.fxlong(:));
    sim.max_lon = max(w.fxlong(:));
    sim.min_tign= min(w.tign_g(:));
    sim.max_tign= max(w.tign_g(:));
    
    % active
    act.x=find(w.tign_g(:)<sim.max_tign);
    act.min_lat = min(w.fxlat(act.x));
    act.max_lat = max(w.fxlat(act.x));
    act.min_lon = min(w.fxlong(act.x));
    act.max_lon = max(w.fxlong(act.x));
    
    % domain bounds
    margin=0.3;
    fprintf('enter relative margin around the fire (%g)',margin);
    in=input(' > ');
    if ~isempty(in),margin=in;end
    dis.min_lon=max(sim.min_lon,act.min_lon-margin*(act.max_lon-act.min_lon));
    dis.min_lat=max(sim.min_lat,act.min_lat-margin*(act.max_lat-act.min_lat));
    dis.max_lon=min(sim.max_lon,act.max_lon+margin*(act.max_lon-act.min_lon));
    dis.max_lat=min(sim.max_lat,act.max_lat+margin*(act.max_lat-act.min_lat));

    default_bounds{1}=[sim.min_lon,sim.max_lon,sim.min_lat,sim.max_lat];
    descr{1}='fire domain';
    default_bounds{2}=[dis.min_lon,dis.max_lon,dis.min_lat,dis.max_lat];
    descr{2}='around fire';
    default_bounds{3}=[-119.5, -119.0, 47.95, 48.15];
    descr{3}='Barker fire';
    for i=1:length(default_bounds),
        fprintf('%i: %s %8.5f %8.5f %8.5f %8.5f\n',i,descr{i},default_bounds{i});
    end
    bounds=input_num('bounds [min_lon,max_lon,min_lat,max_lat] or number of bounds above',2);
    if length(bounds)==1, 
        bounds=default_bounds{bounds};
    end
    fprintf('using bounds %8.5f %8.5f %8.5f %8.5f\n',bounds)
    display_bounds=bounds;
    
    [ii,jj]=find(w.fxlong>=bounds(1) & w.fxlong<=bounds(2) & w.fxlat >=bounds(3) & w.fxlat <=bounds(4));
    ispan=min(ii):max(ii);
    jspan=min(jj):max(jj);
    
    % restrict data
    fxlat=w.fxlat(ispan,jspan);
    fxlong=w.fxlong(ispan,jspan);
    tign_g=w.tign_g(ispan,jspan);
    nfuel_cat=w.nfuel_cat(ispan,jspan);
    
    min_lon = display_bounds(1);
    max_lon = display_bounds(2);
    min_lat = display_bounds(3);
    max_lat = display_bounds(4);
    
    % convert tign_g to datenum as tign, based zero at the end
    % assuming there is some place not on fire yet where tign_g = w.times
    % 
    w_time_datenum=datenum(char(w.times)'); % the timestep of the wrfout, in days
    max_sim_time=max(tign_g(:));          % max time in the simulation, in sec
    tign=(tign_g - max_sim_time)/(24*60*60) + w_time_datenum; % assume same
    
    % tign_g = max_sim_time + (24*60*60)*(tign - w_time_datenum)
    min_tign=min(tign(:));
    max_tign=max(tign(:));
    
    % rebase time on the largest tign_g = the time of the first frame with fire, in days
    base_time=min_tign;
        
    v.tim = v.tim - base_time;
    tign= tign - base_time; 
    
    % select fire detection within the domain and time
    bii=(v.lon > min_lon & v.lon < max_lon & v.lat > min_lat & v.lat < max_lat);
    
    tol=0.01;
    tim_in = v.tim(bii);
    u_in = unique(tim_in);
    fprintf('detection times from ignition\n')
    for i=1:length(u_in)
        detection_freq(i)=sum(tim_in>u_in(i)-tol & tim_in<u_in(i)+tol);
        fprintf('%8.5f days %s UTC %3i %s detections\n',u_in(i),...
        datestr(u_in(i)+base_time),detection_freq(i),detection);
    end
    [max_freq,i]=max(detection_freq);
%    detection_bounds=input_num('detection bounds as [upper,lower]',...
%        [u_in(i)-min_tign-tol,u_in(i)-min_tign+tol]);
    detection_bounds = [u_in(i)-tol,u_in(i)+tol];
    bi = bii & detection_bounds(1) <= v.tim & v.tim <= detection_bounds(2);
    % now detection selected in time and space
    lon=v.lon(bi);
    lat=v.lat(bi);
    res=v.res(bi);
    tim=v.tim(bi); 
    tim_ref = mean(tim);
    
    fprintf('%i detections selected\n',sum(bi))
    detection_time=tim_ref;
    detection_datenum=tim_ref+base_time;
    detection_datestr=datestr(tim_ref+base_time);
    fprintf('mean detection time %g days from ignition %s UTC\n',...
        detection_time,detection_datestr);
    fprintf('days from ignition  min %8.5f max %8.5f\n',min(tim)-min_tign,max(tim)-min_tign);
    fprintf('longitude           min %8.5f max %8.5f\n',min(lon),max(lon));
    fprintf('latitude            min %8.5f max %8.5f\n',min(lat),max(lat)); 

    % set up reduced resolution plots
    [m,n]=size(fxlong);
    m_plot=m; n_plot=n;
    
    m1=map_index(display_bounds(1),bounds(1),bounds(2),m);
    m2=map_index(display_bounds(2),bounds(1),bounds(2),m);
    n1=map_index(display_bounds(3),bounds(3),bounds(4),n);
    n2=map_index(display_bounds(4),bounds(3),bounds(4),n);    
    mi=m1:ceil((m2-m1+1)/m_plot):m2; % reduced index vectors
    ni=n1:ceil((n2-n1+1)/n_plot):n2;
    mesh_fxlong=fxlong(mi,ni);
    mesh_fxlat=fxlat(mi,ni);
    [mesh_m,mesh_n]=size(mesh_fxlat);

    % find ignition point
    [i_ign,j_ign]=find(tign == min(tign(:)));
    if length(i_ign)~=1,error('assuming single ignition point here'),end
    
    % set up constraint on ignition point being the same
    Constr_ign = zeros(m,n); Constr_ign(i_ign,j_ign)=1;

    %
    % *** create detection mask for data likelihood ***
    %
    detection_mask=zeros(m,n);
    detection_time=tim_ref*ones(m,n);

    % resolution diameter in longitude/latitude units
    rlon=0.5*res/w.unit_fxlong;
    rlat=0.5*res/w.unit_fxlat;

    
    lon1=lon-rlon;
    lon2=lon+rlon;
    lat1=lat-rlat;
    lat2=lat+rlat;
    for i=1:length(lon),
        square = fxlong>=lon1(i) & fxlong<=lon2(i) & ...
                 fxlat >=lat1(i) & fxlat <=lat2(i);
        detection_mask(square)=1;
    end
    
    % for display in plotstate
    C=0.5*ones(1,length(res));
    X=[lon1,lon2,lon2,lon1]';
    Y=[lat1,lat1,lat2,lat2]';
%    plotstate(1,detection_mask,['Fire detection at ',detection_datestr],[])
    % add ignition point
%    hold on, plot(w.fxlong(i_ign,j_ign),w.fxlat(i_ign,j_ign),'xw'); hold off
    % legend('first ignition at %g %g',w.fxlong(i_ign,j_ign),w.fxlat(i_ign,j_ign))
    
    fuelweight(length(fuel)+1:max(nfuel_cat(:)))=NaN;
    for j=1:length(fuel), 
        fuelweight(j)=fuel(j).weight;
    end
    W = zeros(m,n);
    for j=1:n, for i=1:m
           W(i,j)=fuelweight(nfuel_cat(i,j));
    end,end
 
%    plotstate(2,W,'Fuel weight',[])
        
disp('optimization loop')
h =zeros(m,n); % initial increment
plotstate(3,tign,'Forecast fire arrival time',detection_time(1));
print('-dpng','tign_forecast.png');

forecast=tign;
mesh_tign_detect(4,fxlong,fxlat,forecast,v,'Forecast fire arrival time')

fprintf('********** Starting iterations **************\n');

% can change the objective function here
alpha=input_num('penalty coefficient alpha',1/1000);
if(alpha < 0)
    error('Alpha is not allowed to be negative.')
end

% TC = W/(900*24); % time constant = fuel gone in one hour
TC = 1/24;  % detection time constants in hours
stretch=input_num('Tmin,Tmax,Tneg,Tpos',[0.5,10,5,10]);
nodetw=input_num('no fire detection weight',0.5);
power=input_num('negative laplacian power',1.02);

% storage for h maps
maxiter = 2;
maxdepth=2;
h_stor = zeros(m,n,maxiter);

for istep=1:maxiter
    
    fprintf('********** Iteration %g/%g **************\n', istep, maxiter);
    
    psi = detection_mask - nodetw*(1-detection_mask);

    % initial search direction, normed so that max(abs(search(:))) = 1.0
    [Js,search]=objective(tign,h); 
    search = -search/big(search); 

    plotstate(5,search,'Search direction',0);
    print('-dpng', sprintf('%s_search_dir_%d.png', prefix, istep));
    [Jsbest,best_stepsize] = linesearch(4.0,Js,tign,h,search,4,maxdepth);
%    plotstate(21,tign+h+3*search,'Line search (magic step_size=3)',detection_time(1));
    fprintf('Iteration %d: best step size %g\n', istep, best_stepsize);
    if(best_stepsize == 0)
        disp('Cannot improve in this search direction anymore, exiting now.');
        break;
    end
    h = h + best_stepsize*search;
    plotstate(10+istep,tign+h,sprintf('Analysis iteration %i [Js=%g]',istep,Jsbest),detection_time(1));
    print('-dpng',sprintf('%s_descent_iter_%d.png', prefix, istep));
    h_stor(:,:,istep) = h;
end
% rebase the analysis to the original simulation time
analysis=tign+h; 
% w.tign_g = max_sim_time + (24*60*60)*(tign - w_time_datenum)

mesh_tign_detect(6,fxlong,fxlat,analysis,v,'Analysis fire arrival time')
mesh_tign_detect(7,fxlong,fxlat,analysis-forecast,[],'Analysis - forecast difference')

[p.red.tign,p.red.tign_datenum] = rebase_time_back(tign+h);
% analysis = max_sim_time + (24*60*60)*(tign+h + base_time - w_time_datenum);
% err=big(p.tign_sim-analysis)
[p.time.sfire,p.time.datenum] = rebase_time_back(detection_bounds);
p.time.datestr=datestr(p.time.datenum);
p.tign_g=w.tign_g;
p.tign_g(ispan,jspan)=p.red.tign;

% max_sim_time + (24*60*60)*(tign+h + base_time - w_time_datenum);

disp('input the analysis as tign in WRF-SFIRE with fire_perimeter_time=detection time')

figure(9);
col = 'rgbck';
fill(X,Y,C,'EdgeAlpha',1,'FaceAlpha',0);
for j=1:maxiter
    contour(mesh_fxlong,mesh_fxlat,tign+h_stor(:,:,j),[detection_time(1),detection_time(1)],['-',col(j)]); hold on
end
hold off
title('Contour changes vs. step');
xlabel('Longitude');
ylabel('Latitude');
print('-dpng',sprintf( '%s_contours.png', prefix));

    function [time_sim,time_datenum]=rebase_time_back(time_in)
        time_datenum = time_in + base_time;
        time_sim = max_sim_time + (24*60*60)*(time_datenum - w_time_datenum);
    end

    function varargout=objective(tign,h,doplot)
        % [J,delta]=objective(tign,h,doplot)
        % J=objective(tign,h,doplot)
        % compute objective function and optionally gradient delta direction
        T=tign+h;
        [f0,f1]=like1(psi,detection_time-T,TC*stretch);
        F = f1;             % forcing
        % objective function and preconditioned gradient
        Ah = poisson_fft2(h,[dx,dy],power);
        % compute both parts of the objective function and compare
        J1 = 0.5*(h(:)'*Ah(:));
        J2 = -ssum(f0);
        J = alpha*J1 + J2;
        fprintf('Objective function J=%g (J1=%g, J2=%g)\n',J,J1,J2);
        if nargout==1,
            varargout={J};
            return
        end
        gradJ = alpha*Ah + F;
        fprintf('Gradient: norm Ah %g norm F %g\n', norm(Ah,2), norm(F,2));
        if exist('doplot','var'),
            plotstate(7,f0,'Detection likelihood',0.5,'-w');
            plotstate(8,f1,'Detection likelihood derivative',0);
            plotstate(9,F,'Forcing',0); 
            plotstate(10,gradJ,'gradient of J',0);
        end
        delta = solve_saddle(Constr_ign,h,F,0,@(u) poisson_fft2(u,[dx,dy],-power)/alpha);
        varargout=[{J},{delta}];
        % plotstate(11,delta,'Preconditioned gradient',0);
        %fprintf('norm(grad(J))=%g norm(delta)=%g\n',norm(gradJ,'fro'),norm(delta,'fro'))
    end

    function plotstate(fig,T,s,c,linespec)
        fprintf('Figure %i %s\n',fig,s)
        plotmap(fig,mesh_fxlong,mesh_fxlat,T(mi,ni),' ');
        hold on
        hh=fill(X,Y,C,'EdgeAlpha',1,'FaceAlpha',0);
        if ~exist('c','var') || isempty(c) || isnan(c),
            title(s);
        else
            title(sprintf('%s, contour=%g',s,c(1)))
            if ~exist('linespec','var'),
                linespec='-k';
            end
            contour(mesh_fxlong,mesh_fxlat,T(mi,ni),[c c],linespec)            
        end
        hold off
        ratio=[w.unit_fxlat,w.unit_fxlong];
        xlabel longtitude
        ylabel latitude
        ratio=[ratio/norm(ratio),1];
        daspect(ratio)
        axis tight
        drawnow
    end


    function [Jsmin,best_stepsize] = linesearch(max_step,Js0,tign,h,search,nmesh,max_depth)
        step_low = 0;
        Jslow = Js0;
        step_high = max_step;
        Jshigh = objective(tign,h+max_step*search);
        for d=1:max_depth
            step_sizes = linspace(step_low,step_high,nmesh+2);
            Jsls = zeros(nmesh+2,1);
            Jsls(1) = Jslow;
            Jsls(nmesh+2) = Jshigh;
            for i=2:nmesh+1
                Jsls(i) = objective(tign,h+step_sizes(i)*search);
            end
            
            figure(8);
            plot(step_sizes,Jsls,'+-');
            title(sprintf('Objective function Js vs. step size, iter=%d,depth=%d',istep,d), 'fontsize', 16);
            xlabel('step\_size [-]','fontsize',14);
            ylabel('Js [-]','fontsize',14);
            print('-dpng',sprintf('%s_linesearch_iter_%d_depth_%d.png',prefix,istep,d));
            
            [Jsmin,ndx] = min(Jsls);
            
            low = max(ndx-1,1);
            high = min(ndx+1,nmesh+2);
            Jslow = Jsls(low);
            Jshigh = Jsls(high);
            step_low = step_sizes(low);
            step_high = step_sizes(high);
        end
                
        best_stepsize = step_sizes(ndx);
    end

end % detect_fit

function i=map_index(x,a,b,n)
% find image of x under linear map [a,b] -> [1,m]
% and round to integer
i=round(1+(n-1)*(x-a)/(b-a));
end