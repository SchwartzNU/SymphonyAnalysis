function [X_flat, Y_flat, Z_flat_ON, Z_flat_OFF, CHATprogressName] = CHAT_analyzer(image_fname, Nchannels, CHAT_channel, resampleSquares, pixelRes_XY, filepath, basename)

imageData = bfopen(image_fname);
rawImageSequence = imageData{1,1};
CHATsequence_raw = rawImageSequence(CHAT_channel:Nchannels:end,1);

Nframes = length(CHATsequence_raw);
[pixX, pixY] = size(CHATsequence_raw{1});

if pixX > pixY
    
elseif pixY > pixX
    
end

resampleFactor = pixX / resampleSquares;
voxelsX = round(pixX/resampleFactor);
voxelsY = round(pixY/resampleFactor);
CHATsequence = zeros(voxelsX, voxelsY, Nframes);
CHATsequence_raw_mat = zeros(pixX, pixY, Nframes);
for i=1:Nframes
    CHATsequence(:,:,i) = imresize(CHATsequence_raw{i}, [voxelsX, voxelsY]);
    CHATsequence_raw_mat(:,:,i) = CHATsequence_raw{i};
end
CHAT_proj_full = squeeze(max(CHATsequence_raw_mat, [], 3));
figure;
imagesc(CHAT_proj_full);
projImageAx = gca;
clear('CHATsequence_raw_mat', 'CHATsequence_raw');

%% Load any previous CHAT marking work
CHATprogressName = fullfile(filepath, [basename '_CHATprogress.mat']);
CHAT_pos = ones(voxelsX, voxelsY, 2)*nan;
if exist(CHATprogressName, 'file')
   load(CHATprogressName, 'CHAT_pos');
else
   save(CHATprogressName, 'CHAT_pos');
end

loadSaveFlag = false;
numSavedBoxes = 0;
if any(any(~isnan(CHAT_pos(:,:,1))))
    numSavedBoxes = find(~isnan(CHAT_pos(:,:,1))', 1, 'last');
    loadSaveFlag = true;
end
%%

figure;
peaksAx = gca;
pixStepX = pixX / voxelsX;
pixStepY = pixY / voxelsY;
for i=1:voxelsX
    for j=1:voxelsY
        r = rectangle('Parent', projImageAx, 'Position', [(j-1)*pixStepY, (i-1)*pixStepX, pixStepY, pixStepX], 'EdgeColor', 'r');
        if numSavedBoxes < 1
            loadSaveFlag = false;
        end
        numSavedBoxes = numSavedBoxes - 1;
        
        %whichRect = whichRectangle(i, j, x, y, w, h, resampleFactor, pixelRes_XY);
        repeatPeakPick = true;
        while repeatPeakPick
            curProj = squeeze(CHATsequence(i,j,:));
            curProj = smooth(curProj, 9);
            hold(peaksAx, 'off');
            plot(peaksAx, curProj);
            ylabel('ChAT flourescence');
            xlabel('z-position (frame)')
            
            if loadSaveFlag
                px1 = CHAT_pos(i,j,1);
            else
                [px1, ~] = ginput(1);
            end
            hold(peaksAx, 'on');
            px1 = round(px1);
            if ~isempty(px1)
                if px1>0 && px1 < length(curProj)
                    scatter(peaksAx, px1, curProj(px1), 'rx');
                end
            end
            
            if loadSaveFlag
                px2 = CHAT_pos(i,j,2);
            else
               [px2, ~] = ginput(1);
            end
            px2 = round(px2);
            if ~isempty(px2)
                if px2 > 0 && px2 < length(curProj)
                    scatter(peaksAx, px2, curProj(px2), 'rx');
                end
            end
            
            if loadSaveFlag
                key = 'otherwise option';
            else
                key = input('ok?: [y=return, skip=s, redo=r]', 's');
            end
            
            switch key
                case 'r'
                    repeatPeakPick = true;
                case 's'
                    repeatPeakPick = false;
                    set(r, 'EdgeColor', 'g');
                otherwise
                    if isempty(px1) || isempty(px2)
                        repeatPeakPick = true;
                    else
                        chatFrames = sort([px1, px2]);
                        CHAT_pos(i,j,1) = chatFrames(1);
                        CHAT_pos(i,j,2) = chatFrames(2);
                        repeatPeakPick = false;
                        text((j-1)*pixStepY+1, (i-1)*pixStepX+pixStepX/2, [num2str(round(chatFrames(1))), ', ' num2str(round(chatFrames(2)))], 'Parent', projImageAx)
                        set(r, 'EdgeColor', 'k');
                        save(CHATprogressName, 'CHAT_pos');
                    end
            end
        end
        %curProj = curProj' - min(curProj);
        %[x_fit, proj_fit] = CHAT_fitter(curProj, 2); %fit 2 peaks
        %keyboard;
    end
end

%clean up outliers
im_std_1 = stdfilt(squeeze(CHAT_pos(:,:,1)));
im_std_2 = stdfilt(squeeze(CHAT_pos(:,:,2)));
im_med_1 = inpaint_nans(medfilt2(squeeze(CHAT_pos(:,:,1)), 'symmetric'));
im_med_2 = inpaint_nans(medfilt2(squeeze(CHAT_pos(:,:,2)), 'symmetric'));

for i=1:voxelsX
    for j=1:voxelsY
        if isnan(CHAT_pos(i,j,1)) || abs(CHAT_pos(i,j,1) - im_med_1(i,j)) > 2*im_std_1(i,j)
            % disp('replacing value')
            CHAT_pos(i,j,1) = im_med_1(i,j);
        end
        if isnan(CHAT_pos(i,j,2)) || abs(CHAT_pos(i,j,2) - im_med_2(i,j)) > 2*im_std_2(i,j)
            % disp('replacing value')
            CHAT_pos(i,j,2) = im_med_2(i,j);
        end
    end
end

%format into x,y,z, values
[Xvals, Yvals] = meshgrid(resampleFactor * [1:voxelsY] * pixelRes_XY, resampleFactor * [1:voxelsX] * pixelRes_XY);
X_flat = reshape(Xvals, 1, []);
Y_flat = reshape(Yvals, 1, []);
Z_flat_ON = reshape(squeeze(CHAT_pos(:,:,1)), 1, []);
Z_flat_OFF = reshape(squeeze(CHAT_pos(:,:,2)), 1, []);

end




