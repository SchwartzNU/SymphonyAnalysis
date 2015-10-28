function [X_flat, Y_flat, Z_flat_ON, Z_flat_OFF] = CHAT_analyzer(image_fname, Nchannels, CHAT_channel, resampleSquares, pixelRes_XY)
imageData = bfopen(image_fname);
rawImageSequence = imageData{1,1};
CHATsequence_raw = rawImageSequence(CHAT_channel:Nchannels:end,1);

Nframes = length(CHATsequence_raw);
[pixX, pixY] = size(CHATsequence_raw{1});
resampleFactor = pixX / resampleSquares;
voxelsX = round(pixX/resampleFactor);
voxelsY = round(pixY/resampleFactor);
CHATsequence = zeros(voxelsX, voxelsY, Nframes);

for i=1:Nframes
    CHATsequence(:,:,i) = imresize(CHATsequence_raw{i}, 1/resampleFactor);
end

CHAT_pos = ones(voxelsX, voxelsY, 2)*nan;
figure;
for i=1:voxelsX
    i
    for j=1:voxelsY
        j
        %whichRect = whichRectangle(i, j, x, y, w, h, resampleFactor, pixelRes_XY);
        repeatPeakPick = true;
        while repeatPeakPick
            curProj = squeeze(CHATsequence(i,j,:));
            curProj = smooth(curProj, 9);
            hold('off');
            plot(curProj);
            ylabel('ChAT flourescence');
            xlabel('z-position (frame)')
            [px, ~] = ginput(1);
            hold('on');
            pos1 = px;
            px = round(px);
            scatter(px, curProj(px), 'rx');
            [px, ~] = ginput(1);
            pos2 = px;
            px = round(px);
            scatter(px, curProj(px), 'rx');
            
            key = input('ok?: [y=return, skip=s, redo=r]', 's');
            switch key
                case 'r'
                    repeatPeakPick = true;
                case 's'
                    repeatPeakPick = false;
                otherwise
                    chatFrames = sort([pos1, pos2]);
                    CHAT_pos(i,j,1) = chatFrames(1);
                    CHAT_pos(i,j,2) = chatFrames(2);
                    repeatPeakPick = false;
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




