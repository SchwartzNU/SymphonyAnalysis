 %{
 # a table of all social behavior experiments
 session_id: smallint unsigned auto_increment  #unique session id
 ---
 sessionstart: timestamp     # date/time that session began, GMT adjusted
 sessionend: timestamp     # date/time that session ended, GMT adjusted

%}
 classdef SocialSession < dj.Manual
 end