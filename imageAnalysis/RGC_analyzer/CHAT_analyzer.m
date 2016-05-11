function [X_flat, Y_flat, Z_flat_ON, Z_flat_OFF] = CHAT_analyzer(image_fname, Nchannels, CHAT_channel, resampleSquares, pixelRes_XY)
imageData = bfopen(image_fname);
rawImageSequence = imageData{1,1};
CHATsequence_raw = rawImageSequence(CHAT_channel:Nchannels:end,1);

Nframes = length(CHATsequence_raw);
[pixX, pixY] = size(CHATsequence_raw{1})
resampleFactor = pixX / resampleSquares;
voxelsX = round(pixX/resampleFactor);
voxelsY = round(pixY/resampleFactor);
CHATsequence = zeros(voxelsX, voxelsY, Nframes);
CHATsequence_raw_mat = zeros(pixX, pixY, Nframes);
for i=1:Nframes
    CHATsequence(:,:,i) = imresize(CHATsequence_raw{i}, 1/resampleFactor);
    CHATsequence_raw_mat(:,:,i) = CHATsequence_raw{i};
end
CHAT_proj_full = squeeze(max(CHATsequence_raw_mat, [], 3));
figure;
imagesc(CHAT_proj_full);
projImageAx = gca;
clear('CHATsequence_raw_mat', 'CHATsequence_raw');

CHAT_pos = ones(voxelsX, voxelsY, 2)*nan;

figure;
peaksAx = gca;
pixStepX = pixX / voxelsX;
pixStepY = pixY / voxelsY;
for i=1:voxelsX
    for j=1:voxelsY
        r = rectangle('Parent', projImageAx, 'Position', [(i-1)*pixStepX, (j-1)*pixStepY, pixStepX, pixStepY], 'EdgeColor', 'r');
        
        %whichRect = whichRectangle(i, j, x, y, w, h, resampleFactor, pixelRes_XY);
        repeatPeakPick = true;
        while repeatPeakPick
            curProj = squeeze(CHATsequence(i,j,:));
            curProj = smooth(curProj, 9);
            hold(peaksAx, 'off');
            plot(peaksAx, curProj);
            ylabel('ChAT flourescence');
            xlabel('z-position (frame)')
            [px, ~] = ginput(1);
            hold(peaksAx, 'on');
            pos1 = px;
            px = round(px);
            if ~isempty(px)
                if px>0 && px < length(curProj)
                    scatter(peaksAx, px, curProj(px), 'rx');
                end
            end
            [px, ~] = ginput(1);
            pos2 = px;
            px = round(px);
            if ~isempty(px)
                if px>0 && px < length(curProj)
                    scatter(peaksAx, px, curProj(px), 'rx');
                end
            end
            
            key = input('ok?: [y=return, skip=s, redo=r]', 's');
            switch key
                case 'r'
                    repeatPeakPick = true;
                case 's'
                    repeatPeakPick = false;
                    set(r, 'EdgeColor', 'g');
                otherwise
                    chatFrames = sort([pos1, pos2]);
                    CHAT_pos(i,j,1) = chatFrames(1);
                    CHAT_pos(i,j,2) = chatFrames(2);
                    repeatPeakPick = false;
                    text((i-1)*pixStepX+1, (j-1)*pixStepY+pixStepY/2, [num2str(round(chatFrames(1))), ', ' num2str(round(chatFrames(2)))], 'Parent', projImageAx)
                    set(r, 'EdgeColor', 'k');
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
            % i
            % j
            CHAT_pos(i,j,1) = im_med_1(i,j);
        end
        if isnan(CHAT_pos(i,j,2)) || abs(CHAT_pos(i,j,2) - im_med_2(i,j)) > 2*im_std_2(i,j)
            % disp('replacing value')
            % i
            % j
            CHAT_pos(i,j,2) = im_med_2(i,j);
        end
    end
end

%format into x,y,z, values
[Xvals, Yvals] = meshgrid(resampleFactor * [1:voxelsX] * pixelRes_XY, resampleFactor * [1:voxelsY] * pixelRes_XY);
X_flat = reshape(Xvals, [1, (pixX./resampleFactor)^2]);
Y_flat = reshape(Yvals, [1, (pixX./resampleFactor)^2]);
Z_flat_ON = reshape(squeeze(CHAT_pos(:,:,1)), [1, (pixX./resampleFactor)^2]);
Z_flat_OFF = reshape(squeeze(CHAT_pos(:,:,2)), [1, (pixX./resampleFactor)^2]);

end




