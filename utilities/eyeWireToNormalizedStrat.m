function y = eyeWireToNormalizedStrat(x)
OFF_chat = 0.28;
ON_chat = 0.62;

x = x - ON_chat; %ON to zero;
x = -x; %flip axis;
y = x ./ (ON_chat - OFF_chat); %rescale

