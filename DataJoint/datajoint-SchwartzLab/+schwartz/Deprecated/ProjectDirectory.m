%{
 # project directory
 -> schwartz.Project
---
project_path: varchar(128)      #the path to the project directory, set automatically
%}

classdef ProjectDirectory < dj.Computed
    methods (Access=protected)
        function makeTuples(self,key)
            key.project_path=sprintf('\\\\fsmresfiles.fsm.northwestern.edu\\fsmresfiles\\Ophthalmology\\Research\\SchwartzLab\\Datajoint\\%s',key.project_name);
            upload_path=sprintf('%s\\upload',key.project_path);
            
            if exist(key.project_path,'dir')~=7
                mkdir(key.project_path);
                fprintf('Created main directory for %s on server\n',key.project_name);
            end
            if exist(upload_path,'dir')~=7
                mkdir(upload_path);
                fprintf('Created upload directory for %s on server\n',key.project_name);
            end
            self.insert(key);
        end
    end
end