function [] = makeIgorPlotLinesCommands(Nlines)
for i=1:Nlines
   disp(['AppendToGraph waveY0[][' num2str(i-1) '] vs ' 'waveX0[][' num2str(i-1) ']']); 
end
