 %{
 # houses for mouses
 cage_id: varchar(64)           # cage number, string
 ---
 breeding = NULL : enum('Y','N')        # is this a breeding cage?
%}
 classdef Cage < dj.Manual
 end