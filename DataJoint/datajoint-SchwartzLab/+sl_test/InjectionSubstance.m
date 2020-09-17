%{
# injected substance (virus, beads, dye, etc)
substance_id : smallint auto_increment 
---
source : varchar(32)                 # vendor or lab
description: varchar(32)             # name of substance (e.g. AAV2-Cre)
catalog_number: varchar(32)          # catalog number (as text)
date_received: date                  # date received
date_expires: date                   # expiration date if it has one
storage_location: varchar(128)       # storage location in the lab
notes: varchar(256)                  # anything about this substance
tags: longblog
%}

classdef InjectionSubstance < dj.Lookup
    
end
