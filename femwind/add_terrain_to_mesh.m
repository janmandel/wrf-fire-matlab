function XX=add_terrain_to_mesh(X, kind, how, val)
% XX=add_terrain_to_mesh(X, kind, how, val) 
% Modify 3D mesh vertically to follow terrain
% in:
%      kind  'hill'  add hill
%            numeric uniform shift up
%      how   'shift' move up each column the same
%            'squash' keep top flat
%      val   relative height of the hill
% out:
%      XX    modified mesh

check_mesh(X);

x = X{1}(:,:,1); y=X{2}(:,:,1);z=X{3};
kmax=size(X{1},3);
if ischar(kind),
    switch kind
        case 'hill'
            cx = mean(x(:));
            cy = mean(y(:));
            hz = max(z(:))-min(z(:));
            rx = mean(abs((x(:)-cx)));
            ry = mean(abs((y(:)-cy)));
            a = ((x-cx)./rx).^2 + ((y-cy)./ry).^2 ;
            t = hz*exp(-a*2)*val;
        case 'xhill'
            cx = mean(x(:));
            cy = mean(y(:));
            hz = max(z(:))-min(z(:));
            rx = mean(abs((x(:)-cx)));
            a = ((x-cx)./rx).^2;
            t = hz*exp(-a*2)*val;
        otherwise
            error('add_terrain_to_mesh: unknown kind')
    end
elseif isnumeric(kind),
    t=kind;
else
    error('kind must be string or numeric')
end
switch how
    case {'shift','s'}
        disp('shifting mesh by terrain vertically')
        XX=X;
        for k=1:kmax
            XX{3}(:,:,k)=X{3}(:,:,k)+t;
        end
    case {'compress','c','squash'}
        if any(any(t > X{3}(:,:,end))),
            error('shift values are too large to be compressed')
        end
        disp('compressing mesh keeping top unchanged')
        XX=X;
        for k=1:kmax
            XX{3}(:,:,k)=X{3}(:,:,k)+t*(XX{3}(1,1,kmax) - XX{3}(1,1,k)) / XX{3}(1,1,kmax);
        end
    otherwise
        error('add_terrain_to_mesh: unknown how')
end
check_mesh(XX)
end