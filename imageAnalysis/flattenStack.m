%% read in image
fname = '081115Ac1_skel.tiff';
%fname = '081115Ac1_binClose_chat.tiff';


info = imfinfo(fname);
Nframes = length(info);
w = info(1).Width;
h = info(1).Height;
x_microns = info(1).XResolution;
y_microns = info(1).YResolution;
z_microns = 0.5;

im = false(h, w, Nframes);

for i=1:Nframes
   im(:,:,i) = logical(imread(fname, i));
end

%% trying a different strategy
% xv = linspace(0, w*x_microns, w);
% yv = linspace(0, h*y_microns, h);
% zv = linspace(0, Nframes*z_microns, Nframes);
% 
% [X,Y] = meshgrid(xv,yv);


startframe = 1;
filterW = 90;

Z_strat1 = zeros(h,w);
for i=1:h
    for j=1:w
        firstSpot = find(squeeze(im(i,j,startframe:end)), 1);
        if isempty(firstSpot)
            Z_strat1(i,j) = nan;
        else
            Z_strat1(i,j) = firstSpot;
        end
    end
end

z_filt = ndnanfilter(Z_strat1,@chebwin,[filterW filterW]);
%% getting separate sets of points for each surface
s = scatter3(x,y,z,10,'k','filled');
datacursormode('on');
dcm = datacursormode;

% set(dcm, 'UpdateFcn', @customDataCursorUpdateFcn, 'Enable', 'On'); 
layer = '';
global CUR_LAYER;

CUR_LAYER = layer;
row = dataTipTextRow('Layer',layer);
s.DataTipTemplate.DataTipRows(end+1) = row;

while ~strcmp(layer, 'done')
    layer = input('Choose points for layer: [on, off, exclude, pause, or done]: ', 's');
    switch layer
        case 'on'
            layer = 'on';
            allDT = findobj(s,'Type','datatip');
            for i=1:length(allDT)
                allDT(i).Tag = layer;
            end
            CUR_LAYER = layer;
        case 'off'
            layer = 'off';
            allDT = findobj(s,'Type','datatip');
            for i=1:length(allDT)
                allDT(i).Tag = layer;
            end
            CUR_LAYER = layer;
        case 'exclude'
            layer = 'exc';
            %row = dataTipTextRow('Layer',layer);
            %s.DataTipTemplate.DataTipRows(end) = row; 
        case 'pause'
            datacursormode('off');
            layer = '';
        case 'done'
            datacursormode('off');
            layer = '';            
            break;
    end
end



%%
%info = getCursorInfo(dcm);
P = {info.Position};

Npoints = length(P);
mask = false(size(im));
for i=1:Npoints
    mask(P{i}(1), P{i}(2), P{i}(3)) = 1;
end

distMap = bwdistgeodesic(im, mask);
a = distMap(~isnan(distMap));
figure;
scatter3(x,y,z,10,a,'filled')

%%
conformalJump = 1;
Nbins = 101;

[nodes,edges,radii,nodeTypes,abort] = readArborTrace('040419Ac3.swc',[-1 0 1 2 3 4 5]);
nodes = nodes + 1;
arborBoundaries(1) = min(nodes(:,1)); arborBoundaries(2) = max(nodes(:,1));
arborBoundaries(3) = min(nodes(:,2)); arborBoundaries(4) = max(nodes(:,2));

[Xvals, Yvals] = meshgrid([1:h] * x_microns, [1:w] * y_microns);
X_flat = reshape(Xvals, 1, []);
Y_flat = reshape(Yvals, 1, []);
Z_flat = reshape(z_filt, 1, []);
Z_flat_OFF = Z_flat + 10;

thisVZminmesh = fitSurfaceToSACAnnotation_fromPoints(X_flat,Y_flat,Z_flat);
thisVZmaxmesh = fitSurfaceToSACAnnotation_fromPoints(X_flat,Y_flat,Z_flat_OFF);
thisVZminmesh = thisVZminmesh*z_microns;
thisVZmaxmesh = thisVZmaxmesh*z_microns;

surfaceMapping = calcWarpedSACsurfaces(thisVZminmesh,thisVZmaxmesh,arborBoundaries,conformalJump);
warpedArbor = calcWarpedArbor(nodes,edges,radii,surfaceMapping);

ON_chat_pos = warpedArbor.medVZmin;
OFF_chat_pos = warpedArbor.medVZmax;

%%
Nbins = 301;
[strat_x, strat_density, allXYpos, allZpos, nodeDensity] = calc3dDist(warpedArbor.nodes,warpedArbor.edges,ON_chat_pos,OFF_chat_pos, Nbins);
strat_y = strat_density*x_microns; %now in units of microns length
strat_y_norm = strat_y./max(strat_y);
edges = warpedArbor.edges;



%% make stratification histogram
meanStrat = nanmean(z_filt(:));

[x,y,z] = ind2sub(size(im), find(im));
N = length(x);
depth = zeros(N,1);

for i=1:N
    depth(i) = z(i) - z_filt(x(i),y(i));
end

depth = depth + meanStrat;


%%
mean_depth = round(nanmean(z_filt(:)));


im_flat = zeros(w,h,Nframes-startframe);
im_flat(:,:,mean_depth) = 1;

im_warped = zeros(w,h,Nframes-startframe);
for i=1:h
    for j=1:w
        curZ = round(z_filt(i,j));
        if ~isnan(curZ)
            im_warped(i,j,curZ) = 1;
        end
    end
end

%im_warped = inpaint_nans(im_warped);

%%
D_field = imregdemons(im_warped,im_flat);

%%
im_unwarped = imwarp(im, D_field);


%%
Z_strat1_new = zeros(w,h);
for i=1:h
    for j=1:w
        firstSpot = find(squeeze(im_unwarped(i,j,:)), 1);
        if isempty(firstSpot)
            Z_strat1_new(i,j) = nan;
        else
            Z_strat1_new(i,j) = firstSpot;
        end
    end
end


%%
fname = 'unwarped_image.tif';
for i=1:size(im_unwarped,3)
    if i==1
        imwrite(squeeze(im_unwarped(:,:,i)), fname);
    else
        imwrite(squeeze(im_unwarped(:,:,i)), fname, 'WriteMode','append');
    end  
end

%% center of mass for each plane

frameCOM = zeros(Nframes,2);
for i=1:Nframes
    [r, c] = find(squeeze(im(:,:,i)));
    frameCOM(i,:) = [mean(r), mean(c)];
end

%% break into blocks and find COM of each one 
Nblocks = 8;
overlap = 0;

block_size_r = round(h / Nblocks);
block_size_c = round(w / Nblocks);

border_r = round(block_size_r * overlap);
border_c = round(block_size_c * overlap);

com = zeros(Nblocks,Nblocks*2,Nframes);

for i=1:Nframes
    com(:,:,i) = blockproc(squeeze(im(:,:,i)), ...
        [block_size_r, block_size_c], ...
        @COM, ...
        'BorderSize', [border_r, border_c],...
        'TrimBorder', false, ...
        'PadPartialBlocks', true, ...
        'PadMethod', 0);
end

com_x = com(:,1:2:end,:);
com_y = com(:,2:2:end,:);
[X,Y] = meshgrid([0:Nblocks-1]*block_size_r+block_size_r/2,[0:Nblocks-1]*block_size_c+block_size_c/2);

X_flat = reshape(X,Nblocks^2,1);
Y_flat = reshape(Y,Nblocks^2,1);

figure(1);
Uvec = zeros(Nframes,Nblocks^2);
Vvec = zeros(Nframes,Nblocks^2);
for i=1:Nframes
    Uvec(i,:) = reshape(squeeze(com_x(:,:,i)), Nblocks^2, 1) - block_size_r/2;
    Vvec(i,:) = reshape(squeeze(com_y(:,:,i)), Nblocks^2, 1) - block_size_c/2;
    quiver(X_flat,Y_flat,Uvec(i,:)',Vvec(i,:)');
    axis([0, w, 0, h])
    title(['frame ' num2str(i)]);
end

%% compute gradients of the UV surface
Umat = reshape(Uvec,Nframes,Nblocks,Nblocks);
Vmat = reshape(Vvec,Nframes,Nblocks,Nblocks);

Gx = zeros(size(Umat));
Gy = zeros(size(Vmat));
for i=1:Nblocks
    for j=1:Nblocks
        Gx(:,i,j) = gradient(Umat(:,i,j), z_microns/x_microns);
        Gy(:,i,j) = gradient(Vmat(:,i,j), z_microns/y_microns);
    end
end

% for i=1:Nframes
%     subplot(1,2,1);
%     imagesc(squeeze(Gx(i,:,:)), [-5 5]);
%     title(['frame ' num2str(i)]);
%     colorbar;
%     subplot(1,2,2);
%     imagesc(squeeze(Gy(i,:,:)), [-5, 5]);
%     colorbar;
%     pause;
% end

%% make random dot stack and its transform

Gx_upsampled = nan(size(im));
Gy_upsampled = nan(size(im));

for i=1:Nframes
    Gx_upsampled(:,:,i) = imresize(squeeze(Gx(i,:,:)), [h, w], 'method', 'nearest');
    Gy_upsampled(:,:,i) = imresize(squeeze(Gy(i,:,:)), [h, w], 'method', 'nearest');
end

sparsity = .00001;
start_image = rand(size(im)) < sparsity & ~isnan(Gx_upsampled) & ~isnan(Gx_upsampled);

Gx_upsampled(isnan(Gx_upsampled)) = 0;
Gy_upsampled(isnan(Gy_upsampled)) = 0;

spots_per_plane = squeeze(sum(sum(start_image,2),1));
minPlane = find(spots_per_plane>0,1);
maxPlane = find(spots_per_plane>0, 1, 'last' );

%start with nan after first plane
%start_image(:,:,minPlane+1:end) = false;

end_image = start_image;

source = [];
dest = [];
for i=1:maxPlane+1
    curPlane = squeeze(start_image(:,:,i));
    if i>1
        [r,c] = find(prevPlane);
%         minR = floor(min(r)/block_size_r)*block_size_r;
%         maxR = ceil(max(r)/block_size_r)*block_size_r;
%         minC = floor(min(c)/block_size_r)*block_size_c;
%         maxC = ceil(max(c)/block_size_r)*block_size_c;
%         curPlane(min(r):max(r), min(c):max(c)) = 0;
        N = length(r);
        newPlane = false(size(prevPlane));
        for p=1:N
            x = round(r(p)+Gx_upsampled(r(p),c(p),i));
            y = round(c(p)+Gy_upsampled(r(p),c(p),i));
            if x < w && x > 0 && y < h && y > 0 && ~newPlane(x,y)
                newPlane(x,y) = true;
                curPlane(r(p), c(p)) = true;
                source = [source, [r(p); c(p); i-1]];
                dest = [dest, [x; y; i]];
            end
        end
        end_image(:,:,i) = newPlane;
        start_image(:,:,i) = curPlane;    
    else
        end_image(:,:,i) = false(h,w);
    end
    if i==maxPlane+1
        start_image(:,:,i) = false(h,w);
    end
    subplot(1,2,1);
    imagesc(squeeze(start_image(:,:,i)));
    title(['frame ' num2str(i)]);
    subplot(1,2,2);
    imagesc(squeeze(end_image(:,:,i)));
    pause;
    prevPlane = curPlane;
end


% %%
% function txt = customDataCursorUpdateFcn(~, event)
%     keyboard;
%     pos = event.Position;
%     txt = {sprintf('X: %.5f', pos(1)), sprintf('Y: %.5f', pos(2))};
%     %disp([txt ' layer ' CUR_LAYER]);
% end % <- may not be needed
% 
% 




