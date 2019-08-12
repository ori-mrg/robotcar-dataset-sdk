function pointcloud = VelodyneRawToPointcloud(ranges, intensities, angles)
%
% VelodyneRawToPointcloud - Convert raw Velodyne HDL32E scan as provided by 
%       LoadVelodyneRaw to a pointcloud
%
% pointcloud = VelodyneRawToPointcloud(ranges, intensities, angles)
%
% INPUTS:
%   ranges: Raw Velodyne range readings
%   intensities: Raw Velodyne intensity readings
%   angles: Raw Velodyne angles
%
% OUTPUTS:
%   pointcloud: XYZI pointcloud generated from the raw Velodyne data Nx4
%
% NOTES:
%   - This implementation does *NOT* perform motion compensation on the
%     generated pointcloud. 
%   - Accessing the pointclouds in binary form via `LoadVelodynePointcloud` 
%     is approximately 2x faster at the cost of 8x the storage space
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

% Hard coded configuration to simplify parsing code
hdl32e_minimum_range = 1.0 ;
hdl32e_elevations = [ ...
    -0.1862, -0.1628, -0.1396, -0.1164, -0.0930, -0.0698, -0.0466, ...
    -0.0232, 0, 0.0232, 0.0466, 0.0698, 0.0930, 0.1164, 0.1396, ...
    0.1628, 0.1862, 0.2094,  0.2327, 0.2560, 0.2793, 0.3025, 0.3259, ...
    0.3491, 0.3723, 0.3957, 0.4189, 0.4421, 0.4655, 0.4887, 0.5119, 0.5353];
hdl32e_base_to_fire_height = 0.090805;

valid = ranges > hdl32e_minimum_range;
z = sin(hdl32e_elevations)' .* ranges - hdl32e_base_to_fire_height;
xy = cos(hdl32e_elevations)' .* ranges;
x = sin(angles) .* xy;
y = -cos(angles) .* xy;
pointcloud = [x(valid), y(valid), z(valid), double(intensities(valid))]';
