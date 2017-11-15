figure(700 + paramSetIndex);clf;
set(gcf, 'Name',['Stimulus Frames paramSetIndex: ' num2str(paramSetIndex)],'NumberTitle','off');

dim1 = ceil(sqrt(stim_numOptions));
dim2 = ceil(stim_numOptions / dim1);
outputAxes = tight_subplot(dim1, dim2, .05, .04);

for optionIndex = 1:stim_numOptions
    axes(outputAxes(optionIndex));
    plotSpatialData(mapX,mapY,squeeze(stim_lightMatrix_byOption{optionIndex}(ti, :, :)));
    colormap gray
    caxis([-1,1])
%     colorbar
    axis tight
end