 %{
 # experiment session
 -> sl.Neuron
 session_date: date            # session date
 ---
 experiment_setup: int         # experiment setup ID
 experimenter: varchar(128)    # name of the experimenter
 %}

 classdef TestTable2 < dj.Manual
 end