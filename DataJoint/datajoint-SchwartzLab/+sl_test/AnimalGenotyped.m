%{
# animal genotyped
-> sl_test.Animal
genotype_date: date                                               # date of genotype
result: enum('het', 'homo', 'non-carrier', 'positive', 'unknown') # positive means positive for multiple genes if double or triple trans., het or homo only if we know 
---
notes: varchar(128)                                               # comment if the result was ambiguous or any additional notes
-> sl_test.User(genotyped_by='name')                              # who did the genotye
%}

classdef AnimalGenotyped < dj.Manual
    
end

