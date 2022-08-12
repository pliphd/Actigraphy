function dirNode(treeHandle, topFolder, varargin)
% DIRNODE generate parent node and walk subfolders (1 level) to create 
%    child nodes to parent node treeHandle
% 
%   VARARGIN
%       context menu: Open
% 
% $Author: Peng Li
% $Date:   Mar. 22, 2021
% 

% root node
[~, f] = fileparts(topFolder);
rnode  = uitreenode(treeHandle, 'Text', f, 'Icon', 'folderClosed.gif');

nodeData.Path  = topFolder;
nodeData.Layer = f;
rnode.NodeData = nodeData;

switch nargin
    case 3
        rnode.ContextMenu = varargin{1};
end

intoFolder(rnode, string(topFolder), 0, varargin{:});