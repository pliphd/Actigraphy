function intoFolder(parentNode, topFolder, expd, varargin)
% INTOFOLDER walk subfolders (1 level) and create child nodes to parent
%            node treeHandle
% 
%   It supports multiple topFolders, and the parentNode should have the
%     same numel return as topFolder
% 
%   VARARGIN
%       context menu: Open
% 
% $Author: Peng Li
% $Date:   Mar. 22, 2021
% 

for iF = 1:numel(topFolder)
    % if already parsed once, continue
    if ~isempty(get(parentNode(iF), 'Child'))
        continue;
    end
    
    % otherwise, parse folders
    subFolders = dir(topFolder(iF));
    subFolders(ismember({subFolders.name}, {'.', '..'})) = [];
    subFolders(contains({subFolders.name}, {'results', 'Results', 'figures', 'Figures'})) = [];
    subFolders([subFolders.isdir] ~= 1) = [];
    
    pNodeData = get(parentNode(iF), 'NodeData');
    pNodeData.SubFolders = {subFolders.folder} + string(filesep) + {subFolders.name};
    % pNodeData.ChildNodes = nan(numel(subFolders), 1); % this is not good
    % as it losses the class properties, the .SubFolders will only stores a
    % double numerical value
    
    for iS = 1:numel(subFolders)
        % sub nodes
        childNode = uitreenode('Parent', parentNode(iF), 'Text', subFolders(iS).name, ...
            'Icon', 'folderClosed.gif');
        
        cNodeData.Path  = fullfile(pNodeData.Path, subFolders(iS).name);
        cNodeData.Layer = [pNodeData.Layer, string(subFolders(iS).name)];
        childNode.NodeData = cNodeData;
        
        pNodeData.ChildNodes(iS) = childNode;
        
        switch nargin
            case 4
                childNode.ContextMenu = varargin{1};
        end
    end
    
    set(parentNode(iF), 'NodeData', pNodeData);
    
    % expand parent
    if expd
        expand(parentNode(iF));
    end
end