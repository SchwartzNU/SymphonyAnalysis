%{
# User: Lab member
name : varchar(32)                  # Lab member name
---
user_name_for_var : varchar(32)     # short version with no spaces or punctuation for a variable name
%}
classdef User < dj.Lookup
    
end