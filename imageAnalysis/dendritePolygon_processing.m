% dbFileName = '~/Google Drive/research/retina/datasets/dendritePolygonDatabase.mat';
% % outFileName = 'analysisTrees/automaticdata/dendritePolygonDatabaseAutodata.mat';
% 
% if exist(dbFileName, 'file')
%     load(dbFileName)
%     fprintf('Loaded %g cells from db\n', size(dendritePolygonDatabase, 1));
% else
%     disp('no db found')
%     return
% end

db = dendritePolygonDatabase;
colors = distinguishable_colors(size(db,1));

figure(1)

for ci = 1:size(db,1)

    cellName = db.Properties.RowNames{ci};
    
%     if isempty(dendritePolygonDatabase{ci,'cellType'}{1})
        try
            load([CELL_DATA_FOLDER cellName '.mat']);
            cellType = cellData.cellType;
        catch
            cellType = '';
        end
        cellType
        dendritePolygonDatabase{ci,'cellType'} = {cellType};
%     end
    
%     % detect rig and date
%     if contains(cellName(1:9), 'A')
%         scalingFactor = 0.42;% µm/pixel
%     else
%         scalingFactor = 0.4;
%     end
    scalingFactor = db{ci, 'scalingFactor'};

    soma = db{ci, 'soma'} * scalingFactor;
    dendriticPolygon = db{ci, 'polygon'}{1} * scalingFactor;
    dendriticPolygon = dendriticPolygon - soma;
    dendriticPolygonResampled = resamplePolygon(dendriticPolygon,1000);

    center = centroid(dendriticPolygonResampled); %find center of major axis
%     rectangle('Position',10 * [-.5, -.5, 1, 1] + [center(1), center(2), 0, 0],'Curvature',1, 'FaceColor', [.3 .5 0]);

    drawPolygon(dendriticPolygonResampled(:,1), dendriticPolygonResampled(:,2), 'Color',colors(ci,:), 'LineWidth',2);

    %DSI and OSI
    [theta,rho] = cart2pol(dendriticPolygonResampled(:,1),dendriticPolygonResampled(:,2)); %rad
    R=0;
    RDirn=0;
    ROrtn=0;
    for j=1:length(theta)
        R=R+rho(j);
        RDirn = RDirn + rho(j)*exp(sqrt(-1)*theta(j));
        ROrtn = ROrtn + rho(j)*exp(2*sqrt(-1)*theta(j));
    end

    DSI = abs(RDirn/R);
    OSI = abs(ROrtn/R);
    DSang = angle(RDirn/R)*180/pi; %deg
    OSang = angle(ROrtn/R)*90/pi; %deg

    if DSang < 0
        DSang = DSang + 360;
    end
    if OSang < 0
        OSang = OSang + 360;
    end

    %DS
%     [x,y] = pol2cart(DSang*pi/180, max(rho)*DSI); %rad
%     line([0 x] + center(1), [0 y] + center(2), 'Color', 'r', 'LineWidth', 3);
    %OS
%     [x,y] = pol2cart(OSang*pi/180, max(rho)*OSI); %rad
%     line([-x x] + center(1), [-y y] + center(2), 'Color', 'g', 'LineWidth', 3);

    %Area
    Area = abs(polygonArea(dendriticPolygonResampled));

    [COM_angle, COM_length] = cart2pol((center(1) - soma(1)), (center(2) - soma(2)));
    COM_angle = mod(COM_angle * 180/pi, 360);
    
    pseudoRadius = sqrt(Area/pi);
    
    db{ci, 'angle_somaToCenterOfMass'} = round(COM_angle);
    db{ci, 'COM_length'} = COM_length;
    db{ci, 'offset_ratioToPseudoradius'} = COM_length / pseudoRadius;
%     line([x_soma center(1)], [y_soma center(2)], 'Color', 'blue', 'LineWidth', 3)
end