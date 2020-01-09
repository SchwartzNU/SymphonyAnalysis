

%% Generate stimulus movie
% format frames x (X * Y)
stimulus = [];

seed = epoch.get('noiseSeed');
preFrames = round(frameRate * (epoch.get('preTime')/1e3));
stimFrames = round(frameRate * (epoch.get('stimTime')/1e3));
postFrames = round(frameRate * (epoch.get('tailTime')/1e3));
locations = 1:(epoch.get('resolutionX') * epoch.get('resolutionY'));

mn = epoch.get('meanLevel');
contrast = epoch.get('contrast');
noiseStream = RandStream('mt19937ar', 'Seed', seed);

for fi = 1:floor((stimFrames + postFrames + preFrames)/epoch.get('frameDwell'))
    for location = locations
        if fi > preFrames && fi <= preFrames + stimFrames
            
            stim = mn + contrast * mn * noiseStream.randn();
            if stim < 0
                stim = 0;
            elseif stim > mn * 2
                stim = mn * 2; % probably important to be symmetrical to whiten the stimulus
            elseif stim > 1
                stim = 1;
            end
        else
            stim = mn;
        end
        
        % convert to contrast
        stim = (stim ./ mn) - 1;
        
        stimulus(fi, location) = stim;
    end
end