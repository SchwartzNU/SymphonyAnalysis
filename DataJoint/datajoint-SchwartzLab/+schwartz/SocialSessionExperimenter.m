 %{
 # a table of people in a social-behavior experiment
 -> schwartz.SocialSession
 -> schwartz.Experimenter
 experimenter_start: timestamp     # date/time that experimenter joined
 ---
experimenter_end = NULL : timestamp     # date/time that experimenter left
 

%}
 classdef SocialSessionExperimenter < dj.Part
     properties(SetAccess=protected)
         master = schwartz.SocialSession
     end
 end