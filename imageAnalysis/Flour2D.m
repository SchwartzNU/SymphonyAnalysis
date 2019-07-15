%% Settings
frames_per_second = 12.20703125;
StimTime = 1;
PreTime = 1;
PostTime = 5;
total_time = StimTime + PreTime + PostTime;
NumEpochs = 14;

%% Load Image
PathName = '';
ImageName =  '20190524_13_47_46_052519A_superficial_pericytes_3_XYT_ch_1.tif';
info = imfinfo([PathName ImageName]);
[Height, Width] = size(imread([PathName ImageName], 1));
Zdepth = numel(info);
pixel_per_second = frames_per_second * Height * Width;

OriginalImage = zeros(Height, Width, Zdepth);
for i=1:numel(info)
    OriginalImage(:,:,i) = imread([PathName ImageName], i);
end

%% Cut out artifact above threshold
Permuted = permute(OriginalImage, [2,1,3]);
dimensions = size(Permuted);
oneD = reshape(Permuted,[],1);
time = 1:length(oneD);
time = time / 1/pixel_per_second;

figure(1) %Plot original intensity trace to aid in selecting the threshold
plot(time,oneD) 

th = input('What should threshold be? Hit enter for default 34.5k. - ');
if isempty(th)
    th = 34500;
end

Ind_Up = getThresCross(oneD,th,1);
Ind_Down = getThresCross(oneD,th,-1);

oneD_naned = oneD;
for i=1:length(Ind_Up)
    oneD_naned(Ind_Up(i)-80:Ind_Down(i)+80) = NaN;
end

figure(1) %Plot original trace vs. 1st pixel of each stimulus onset
plot(time,oneD)
hold on
plot(time,oneD_naned)

Reshaped = reshape(oneD_naned, dimensions);
Naned_Image = permute(Reshaped, [2,1,3]);

%% Creat a stimulus mask image - this will be useful to indicate if the stimulus is on
oneD_mask = zeros(1, length(oneD));
start = 2 * pixel_per_second; % start 1.5 seconds into the recording to avoid the initial brightness

for NumEpoch = 1:NumEpochs
    Ind_Stim = Ind_Up( find(Ind_Up > start, 1, 'first') );
    start = Ind_Stim + 1.5 * pixel_per_second;
    
    oneD_mask(Ind_Stim : Ind_Stim + (Height * Width) - 1) = 1;
end

Reshaped_mask = reshape(oneD_mask, dimensions);
threeD_mask = permute(Reshaped_mask, [2,1,3]);

figure(2) %Plot the original trace against the stimulus indicator to show we correctly identified when the stim was on.
plot(time, oneD)
hold on
scatter(time(find(oneD_mask)), oneD(find(oneD_mask)))

%% Interpolate NaN Pixels and split into epochs
epoch_len = ceil (total_time * frames_per_second);
interp_image = zeros(Height, Width, epoch_len, NumEpochs);
for Column = 1:Height
    for Row = 1:Width
        % Perform Interpolation
        pixel_through_time = Naned_Image(Column,Row,:);
        BadTimes = find(isnan(pixel_through_time));
        AllTimes = 1:length(pixel_through_time);
        GoodTimes = setdiff(AllTimes,BadTimes);
        F=griddedInterpolant(GoodTimes,pixel_through_time(GoodTimes));
        InterpData = F(AllTimes);
        
        % Split into epochs
        StimStart = find(threeD_mask(Column, Row, :));
        for epoch = 1:length(StimStart)
            epoch_start = StimStart(epoch) - round((PreTime * frames_per_second));
            epoch_end = epoch_start + epoch_len - 1;
            interp_image(Column,Row,:,epoch) = InterpData(epoch_start:epoch_end);
        end
    end
end

%% Write to image
newFile = 'splitImage';
mkdir(newFile)
interp_image = uint16(interp_image);
for epoch = 1:NumEpochs
    filename = [newFile, filesep,'trial', num2str(epoch), '.tif'];
    imwrite(interp_image(:,:,1,epoch), filename)
    for NumZ = 2:epoch_len
        imwrite(interp_image(:,:,NumZ,epoch), filename, 'WriteMode', 'append')
    end
end
