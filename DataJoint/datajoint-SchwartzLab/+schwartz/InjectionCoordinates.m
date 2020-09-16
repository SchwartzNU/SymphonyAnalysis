 %{
 # a table of injection coordinates for the injection
 -> schwartz.Injection
 axis: enum('X','Y','Z')
 ---
 coordinate: float
 rotation_degrees = NULL : float

%}
 classdef InjectionCoordinates < dj.Part
     properties(SetAccess=protected)
         master = schwartz.Injection
     end
 end