 %{
 # a table of people participating in injection
 -> schwartz.Injection
 -> schwartz.Experimenter
 experimenter_start: timestamp     # date/time that experimenter joined, GMT adjusted
 ---
experimenter_end = NULL : timestamp     # date/time that experimenter left, GMT adjusted
 

%}
 classdef InjectionExperimenter < dj.Part
     properties(SetAccess=protected)
         master = schwartz.Injection
     end
 end