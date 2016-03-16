function checkSpikeDetection(D,sp,minSpikePeakInd,maxNoisePeakTime,violation_ind,figH)

if isempty(figH);
    h = figure;
elseif strcmp(get(figH,'type'),'figure')    
    h = figH;
else
    h = figH;
    h_fig = get(figH,'parent');    
end
set(h,'KeyPressFcn',@keyPressCallBack);
set(h,'WindowScrollWheelFcn',@scrollWheelCallBack);

[Nepochs,L] = size(D);

UserData.i = 1;
UserData.Nepochs = Nepochs;
UserData.L = L;
UserData.D = D;
UserData.bufferStart = 20;
UserData.bufferEnd = 20;
UserData.sp = sp;
UserData.minSpikePeakInd = minSpikePeakInd;
UserData.maxNoisePeakTime = maxNoisePeakTime;
UserData.violation_ind = violation_ind;

set(h,'UserData',UserData);

displayEpoch(h);

end

function displayEpoch(h)
UserData = get(h,'UserData');
i = UserData.i;
Nepochs = UserData.Nepochs;
L = UserData.L;
D = UserData.D;
bufferStart = UserData.bufferStart;
bufferEnd = UserData.bufferEnd;
sp = UserData.sp;
minSpikePeakInd = UserData.minSpikePeakInd;
maxNoisePeakTime = UserData.maxNoisePeakTime;
violation_ind = UserData.violation_ind;

if minSpikePeakInd(i) > 0%if there is a trace at all
    trace = D(i,:);
    sp_trial = sp{i};
    temp_bufferStart_spike = min(bufferStart,sp_trial(minSpikePeakInd(i))-1);
    temp_bufferStart_noise = min(bufferStart,maxNoisePeakTime(i)-1);
    temp_bufferEnd_spike = min(bufferEnd,L-sp_trial(minSpikePeakInd(i)));
    temp_bufferEnd_noise = min(bufferEnd,L-maxNoisePeakTime(i));
    
    Xnoise = -temp_bufferStart_noise:temp_bufferEnd_noise;
    Xspike = -temp_bufferStart_spike:temp_bufferEnd_spike;
    
    ax_noise = subplot(2,2,1);
    set(ax_noise,'parent',h);    
    plot(ax_noise,Xnoise,trace(maxNoisePeakTime(i)-temp_bufferStart_noise:maxNoisePeakTime(i)+temp_bufferEnd_noise));
    hold(ax_noise,'on');
    plot(ax_noise,0,trace(maxNoisePeakTime(i)),'gx');
    title(ax_noise,'Max Noise Peak');
    hold(ax_noise,'off');
    
    ax_spike = subplot(2,2,2); 
    set(ax_spike,'parent',h);   
    plot(ax_spike,Xspike,trace(sp_trial(minSpikePeakInd(i))-temp_bufferStart_spike:sp_trial(minSpikePeakInd(i))+temp_bufferEnd_spike));
    hold(ax_spike,'on');
    plot(ax_spike,0,trace(sp_trial(minSpikePeakInd(i))),'rx');
    title(ax_spike,'Min Spike Peak');
    hold(ax_spike,'off');
    
    set(ax_noise,'Ylim',get(ax_spike,'Ylim'));
    
    ax_trace = subplot(2,2,[3 4]);    
    set(ax_trace,'parent',h); 
    plot(ax_trace,trace);
    hold(ax_trace,'on');
    plot(ax_trace,sp_trial,trace(sp_trial),'rx');
%    if ~isempty(violation_ind(i))
%        plot(ax_trace,sp_trial(violation_ind(i)),trace(sp_trial(violation_ind(i))),'gx');
%    end
    title(ax_trace,['Epoch ' num2str(i)]);
    hold(ax_trace,'off');    
    set(ax_trace,'ButtonDownFcn',@axisZoomCallback);
end %end if good trace

%    waitfor(h,'CurrentCharacter');
%     w = 0;
%     while ~w %wiat for key press, not button press
%         w = waitforbuttonpress;
%     end
%     key = double(get(h,'CurrentCharacter'));
%     if strcmp(char(key),'q')
%         close(h);
%         return;
%     elseif key==28 %left arrow
%         i = max(i-1,1);
%     elseif key == 29 %right arrow
%         i = min(i+1,Nepochs);

end %end func

function keyPressCallBack(hObject,eventData)
%disp(eventData.Key);
UserData = get(hObject,'UserData');
Nepochs = UserData.Nepochs;
i = UserData.i;
if strcmp(eventData.Key,'rightarrow')
    i = min(i+1,Nepochs);
    UserData.i = i;
    set(hObject,'UserData',UserData);
    displayEpoch(hObject);
elseif strcmp(eventData.Key,'leftarrow')
    i = max(i-1,1);
    UserData.i = i;
    set(hObject,'UserData',UserData);
    displayEpoch(hObject);
elseif strcmp(eventData.Key,'q')
    close(hObject);
end
end

function scrollWheelCallBack(hObject,eventData)
%disp(eventData.VerticalScrollCount);
UserData = get(hObject,'UserData');
Nepochs = UserData.Nepochs;
i = UserData.i;
if eventData.VerticalScrollCount > 0
    i = min(i+1,Nepochs);
    UserData.i = i;
    set(hObject,'UserData',UserData);
    displayEpoch(hObject);
elseif eventData.VerticalScrollCount < 0
    i = max(i-1,1);
    UserData.i = i;
    set(hObject,'UserData',UserData);
    displayEpoch(hObject);
end
end
