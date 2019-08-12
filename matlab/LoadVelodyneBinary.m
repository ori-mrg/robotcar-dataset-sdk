function pointcloud = LoadVelodyneBinary(directory, timestamp)
%
% LoadVelodyneBinary - Decode a binary Velodyne example.
%
% INPUTS:
%   directory: directory containing Velodyne binary data named
%       <timestamp>.bin
%   timestamp: timestamp of binary Velodyne scan to load
%
% OUTPUTS:
%   pointcloud: XYZI pointcloud generated from the raw Velodyne data Nx4
% 
% NOTES:
%   - The pre computed points are *NOT* motion compensated.
%   - Converting a raw velodyne scan to pointcloud can be done using the
%     `VelodyneRangesIntensitiesAnglesToPointcloud` function.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (c) 2019 University of Oxford
% Authors:
%  Dan Barnes (dbarnes@robots.ox.ac.uk)
%
% This work is licensed under the Creative Commons
% Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit
% http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

directory = char(directory);
if directory(end) ~= '/'
    directory = [directory '/'];
end

path = [char(directory) num2str(timestamp) '.bin'];
if ~exist(path, 'file')
    error("Velodyne file does not exist: %s", path);
end

velodyne_file = fopen(path);
data = fread(velodyne_file, 'single');
fclose(velodyne_file);
pointcloud = reshape(data, [numel(data)/4  4])';

end
