%{
# Session in 3 chamber circular social behavior device. Animal here is the TEST (center) animal
-> sl_test.AnimalEvent                               # includes date of session
--- 
-> sl_test.User.proj(experimenter='name')                    # who did it
recorded : tinyint unsigned                          # 0 = false or 1 = true
fname : varchar(128)                                 # root filename if session was recorded
session_time : time                                  # session time
duration_mins : smallint unsigned                    # approximate duration (minutes)
notes : varchar(256)                                 # notes about the animal's state and comfort level, other people involvd, etc. 
social_behavior_session_tags : longblob              # extra tags
purpose : varchar(64)                                # type of experiment, like social dominace, mate preference familiarity with rig, etc.  
%}

classdef AnimalEventSocialBehaviorSession < dj.Part
     properties(SetAccess=protected)
        master = sl_test.AnimalEvent
    end
end

% -> [nullable] sl_test.Animal(animal_in_A='animal_id')           # animal at position A (null for empty)
% -> [nullable] sl_test.Animal(animal_in_B='animal_id')           # animal at position B (null for empty)
% -> [nullable] sl_test.Animal(animal_in_C='animal_id')           # animal at position C (null for empty)

%-> sl_test.User(experimenter='name')                 # who did it

