%{
# session of any kind of behavior, even handling
-> sl_test.Animal
session_date: date                                                #date of this session
result: enum('het', 'homo', 'non-carrier', 'positive', 'unknown') # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
---
notes: varchar(128)                                               # comment if the result was ambiguous or any additional notes
-> sl_test.User(genotyped_by='name')                              # who did it
%}

classdef BehavioralSession < dj.Manual
    
end

