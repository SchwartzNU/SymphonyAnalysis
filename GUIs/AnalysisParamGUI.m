classdef AnalysisParamGUI < handle
    properties
        fig
        handles
        analysisClass
        Nparams
        paramsRoot
        name = 'default';
    end
    
    properties (Constant)
        immutableProps = {'filename', 'filepath', 'name', 'Node', 'Parent'};
    end
    
    methods
        function obj = AnalysisParamGUI(analysisClass)
            global ANALYSIS_FOLDER            
            obj.paramsRoot = [ANALYSIS_FOLDER 'analysisParams' filesep];
            global ANALYSIS_CODE_FOLDER
            analysisClassesFolder = [ANALYSIS_CODE_FOLDER filesep 'analysisTreeClasses' filesep];

            %part here for choosing analysisClass if none is entered
            if nargin<1 %choose analysis class
                fname = uigetfile([analysisClassesFolder '*.m'], 'Select analysis class');    
                analysisClass = strtok(fname,'.');
            end
            obj.analysisClass = analysisClass;           
            
            obj.buildUI();
        end
        
        function buildUI(obj)
            bounds = screenBounds;
            obj.fig = figure( ...
                'Name',         ['Analysis Parameter GUI: ' obj.analysisClass ': ' obj.name], ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none',...
                'Menubar',      'none', ...
                'Position', [0 0.4*bounds(4), 0.25*bounds(3), 0.6*bounds(4)]);
            
            L_main = uiextras.VBoxFlex('Parent', obj.fig);
            
            L_params = uiextras.Grid('Parent', L_main);
            propertySet = setdiff(properties(obj.analysisClass), obj.immutableProps);
            L = length(propertySet);
            obj.Nparams = L;
            
            for i=1:L
                obj.handles.paramText(i) = uicontrol('Parent', L_params, ...
                    'Style', 'text', ...
                    'String', propertySet{i});
            end
            for i=1:L
                obj.handles.paramEdit(i) = uicontrol('Parent', L_params, ...
                    'Style', 'edit');
            end
            
            L_params.set('RowSizes', 50*ones(1,L), 'ColumnSizes', [-1 -1]);
            
            L_buttons = uiextras.HButtonBox('Parent', L_main, ...
                'ButtonSize', [100 50]);
            obj.handles.loadButton = uicontrol('Parent', L_buttons, ...
                'Style', 'pushbutton', ...
                'String', 'load', ...
                'Callback', @(uiobj, evt)obj.loadParams());
            obj.handles.saveButton = uicontrol('Parent', L_buttons, ...
                'Style', 'pushbutton', ...
                'String', 'save', ...
                'Callback', @(uiobj, evt)obj.saveParams());
            set(L_main, 'Sizes', [-5, -1], ...
                'Spacing', 10, ...
                'Padding', 5, ...
                'MinimumSizes', [120 120]);
            
        end
        
        function loadParams(obj)
            [fname,fpath] = uigetfile('*.mat','Load params file...', [obj.paramsRoot obj.analysisClass filesep]);
            if fname %if user did not cancel
                obj.name = strtok(fname, '.');
                set(obj.fig, 'Name', ['Analysis Parameter GUI: ' obj.analysisClass ': ' obj.name]);
                load(fullfile(fpath, fname), 'params');
                fields = fieldnames(params);
                for i=1:obj.Nparams
                    ind = strmatch(get(obj.handles.paramText(i), 'String'), fields, 'exact');
                    if ~isempty(ind)
                        set(obj.handles.paramEdit(i), 'String', params.(fields{ind}));
                    end
                end
            end
        end
        
        function saveParams(obj)
            params = struct;
            for i=1:obj.Nparams                
               paramStr = get(obj.handles.paramEdit(i), 'String');
               if evalsToNumeric(paramStr)
                   params.(get(obj.handles.paramText(i), 'String')) = eval(paramStr);
               else
                   params.(get(obj.handles.paramText(i), 'String')) = paramStr;
               end
            end
            [fname,fpath] = uiputfile([obj.paramsRoot filesep obj.analysisClass filesep '*.mat'],'Save params file...',  [obj.paramsRoot filesep obj.analysisClass filesep obj.name]); 
            if fname %user did not cancel
                save(fullfile(fpath, fname), 'params'); 
                obj.name = strtok(fname, '.');
                set(obj.fig, 'Name', ['Analysis Parameter GUI: ' obj.analysisClass ': ' obj.name]);
            end
        end
        
    end
    
    
end