function rootData = addWidthScalars(rootData, stimParam, paramlist, varargin)
%Adam 4/17/15
%based on addDSIandOSI

%If fixedVal has a value go with that, otherwise choose stimParam value
%that maximizes response. 
%examples: (two last ones use 'maximize')
%addWidthScalars(...,'spotSize', 'fixedVal', 300) 
%addWidthScalars(...,'spotSize', 'maximize', 'OFFSETspikes')
%addWidthScalars(...,'barAngle')


p = inputParser;
defaultMaximize = 'ONSETspikes';
addParameter(p,'maximize',defaultMaximize);
addParameter(p,'fixedVal',[]);
parse(p,varargin{:});

maximizeParamName = p.Results.maximize;
fixedVal = p.Results.fixedVal;


%NstimParamVec = length(rootData.(stimParam));
stimParamVec = rootData.(stimParam);

if isempty(fixedVal)
    useMaximize = 1;
    %determine fixedVal
    if isfield(rootData.(maximizeParamName), 'type')
        respVals = getRespVectors(rootData, {maximizeParamName});
        [~, fixedValInd] = max(respVals);
        fixedVal = stimParamVec(fixedValInd);
    end;
else
    useMaximize = 0;
    %fixedValInd = (stimParamVec == fixedVal); %Should be exactly one.
    [~, fixedValInd] = min(abs(stimParamVec - fixedVal));
    %MAKE SURE HAVE A VALUE OF stimParam CLOSE ENOUGH TO DESIRED VALUE!
end;



%fnames = fieldnames(rootData);
fnames = paramlist;
for i=1:length(fnames)
    curField = fnames{i};
    if isfield(rootData.(curField), 'type')
        respVals = getRespVectors(rootData, {curField});
        if ~isempty(respVals)
            if useMaximize
                rootData.([curField,'_',stimParam,'ByMax']) = respVals(fixedValInd);  %eg ONSETspikes_barAngleByMax
            else
                rootData.([curField,'_',stimParam,'Fixed',num2str(fixedVal)]) = respVals(fixedValInd);
                %e.g ONSETspikes_spotSizeFixed300
            end;
%             if (isnan(respVals(fixedValInd)) && ~strcmp(curField,'ONOFFindex')) && ~strcmp(curField,'ODBtest')
%                 keyboard;
%             end;
        end;
    end; 
end;

%Store the maximizing angle/spotSize (for lookup in cellData purpouses)
if useMaximize
    rootData.(['maximizing_',stimParam]) = fixedVal;
end;

end


   
   