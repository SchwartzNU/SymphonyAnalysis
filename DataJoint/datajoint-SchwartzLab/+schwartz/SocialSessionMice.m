 %{
 # a table of mice in a social-behavior experiment
 -> schwartz.SocialSession
 -> schwartz.Mouse
 ---
 arm : enum('center','A','B','C')  # where is this mouse located?

%}
 classdef SocialSessionMice < dj.Part
     properties(SetAccess=protected)
         master = schwartz.SocialSession
     end
 end
 