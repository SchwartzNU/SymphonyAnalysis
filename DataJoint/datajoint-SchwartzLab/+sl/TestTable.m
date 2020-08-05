%{
# TestTable
mouse_id: int                  # unique mouse id
---
dob: date                      # mouse date of birth
sex: enum('M', 'F', 'U')       # sex of mouse - Male, Female, or Unknown/Unclassified
%}

classdef TestTable < dj.Manual
end