function [localMass,newNodes] = segmentLengths(nodes,edges)
% assign new nodes at the center of mass of each edge and calculate the mass (length) of each edge
% localMass = zeros(size(nodes,1),1); newNodes = zeros(size(nodes,1),3);
% for kk=1:size(nodes,1);
%   parent = edges(find(edges(:,1)==kk),2);
%   if ~isempty(parent)
%     localMass(kk) = norm(nodes(parent,:)-nodes(kk,:));
%     newNodes(kk,:) = (nodes(parent,:)+nodes(kk,:))/2;
%   else
%     localMass(kk) = 0; newNodes(kk,:) = nodes(kk,:);
%   end
% end

localMass = zeros(size(edges,1),1);
newNodes = zeros(size(edges,1),3);
for kk = 1:size(edges,1)
    localMass(kk) = norm(nodes(edges(kk,1),:) - nodes(edges(kk,2),:));
    newNodes(kk,:) = (nodes(edges(kk,1),:) + nodes(edges(kk,2),:)) / 2;
end
