%{
# injections
-> schwartz.Mouse
-> schwartz.Vector
inject_date: date          # date of injection
target: enum('LE','RE','LH','RH')
---
titer: float  # percent dilution?

%}

classdef Injection < dj.Imported
end
