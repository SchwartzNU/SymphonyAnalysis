function [] = convertHdf5ImagesToTiff()
folder = uigetdir(pwd,'Image folder:');
cd(folder);
fileList = dir;

if ~isfolder('tiff')
    mkdir('tiff');
end
    
for i=1:length(fileList)
    [fname, ext] = strtok(fileList(i).name, '.');
    if strcmp(ext, '.h5')
        info = h5info([fname ext]);
        dataSet = info.Datasets(1);
        dataSetName = dataSet.Name;
        dimensions = dataSet.Dataspace.Size;
        pixelSize = dataSet.Attributes.Value;
        
        disp(['Reading file ' fname]);
        disp(['Dimensions: ' num2str(dimensions(1)) 'x' num2str(dimensions(2)) 'x' num2str(dimensions(3))]);
        disp(['Pixel size (um): ' num2str(pixelSize(1)) 'x' num2str(pixelSize(2)) 'x' num2str(pixelSize(3))]);
        
        D = h5read([fname '.h5'], ['/' dataSetName]);
        imwrite(squeeze(D(:,:,1)), ['tiff' filesep fname '.tif']);
        for j=2:dimensions(3)
             imwrite(squeeze(D(:,:,j)), ['tiff' filesep fname '.tif'], 'WriteMode', 'append');
        end
    end
end


