%% Settings
frames_per_second = 12.20703125;
StimTime = 1;
PreTime = 1;
PostTime = 5;

total_time = StimTime + PreTime + PostTime;
CurrentFolder = dir();

ImageFolders = {};
for contents = 1:length(CurrentFolder)
    if strfind(CurrentFolder(contents).name, 'splitImage')
        ImageFolders = [ImageFolders, CurrentFolder(contents).name];
    end
end


for f_num = 1:length(ImageFolders)
    %% Identify images in folder
    ImageFolder = dir(ImageFolders{f_num});
    ImageNames = {};
    for contents = 1:length(ImageFolder)
        if strfind(ImageFolder(contents).name, 'trial')
            ImageNames = [ImageNames, ImageFolder(contents).name];
        end
    end
    
    %%  Load Images --- Images(X,Y,Z,Trial)
    PathName = [ImageFolders{f_num}, '/'];
    ImageName =  ImageNames{1};       
    info = imfinfo([PathName ImageName]);
    [Height, Width] = size(imread([PathName ImageName], 1));
    Zdepth = numel(info);
    Images = zeros(Height, Width, Zdepth, length(ImageNames));
    for img_num = 1:length(ImageNames)
        ImageName =  ImageNames{img_num};       
        for i=1:Zdepth
            Images(:,:,i,img_num) = imread([PathName ImageName], i);
        end
    end
    
    %% Find DeltaF/F
    PreStim = 1: floor(PreTime * frames_per_second);
    Stim = round(PreTime * frames_per_second) + 1 : round((PreTime+StimTime)*frames_per_second);
    
    F = median(Images(:,:,PreStim,:), 3);
    
    MeanResp = mean(Images(:,:,Stim,:), [1,2,4]);
    RespFilter = MeanResp / mean(MeanResp);
    
    StimResp = mean((Images(:,:,Stim,:) .* RespFilter),3);
    deltaF = StimResp - F;
    deltaF_over_F = deltaF ./ F;
    
    
    %% Write dF/F to image
    img_dFoF = uint16(deltaF_over_F*100000 + 32500);
    filename = ['deltFoverF_Size', ImageFolders{f_num}, '.tif'];
    imwrite(img_dFoF(:,:,1,1), filename)
    for NumZ = 2:length(img_dFoF(1,1,1,:))
        imwrite(img_dFoF(:,:,1,NumZ), filename, 'WriteMode', 'append')
    end    
    
    %% Write mean image
    mean_over_trials = mean(Images, 4);
    img_mean = uint16(mean_over_trials);
    filename = ['mean', ImageFolders{f_num}, '.tif'];
    imwrite(img_mean(:,:,1), filename)
    for NumZ = 2:length(img_mean(1,1,:))
        imwrite(img_mean(:,:,NumZ), filename, 'WriteMode', 'append')
    end     
end