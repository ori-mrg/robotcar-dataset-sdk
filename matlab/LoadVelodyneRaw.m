function [ranges, intensities, angles, approximate_timestamps] = ...
    LoadVelodyneRaw(directory, timestamp)
%
% LoadVelodyneRaw - Decode a raw Velodyne example.
%
% INPUTS:
%   directory: directory containing Velodyne raw data named <timestamp>.png
%   timestamp: timestamp of Velodyne data to load
%
% OUTPUTS:
%   ranges: Range of each measurement in meters where 0 == invalid, 
%       (32 x N)
%   intensities: Intensity of each measurement where 0 == invalid, (32 x N)
%   angles: Angle of each measurement in radians (1 x N)
%   approximate_timestamps: Approximate linearly interpolated timestamps of 
%       each mesaurement (1 x N). Approximate as we only receive timestamps 
%       for each packet. The timestamp of the next frame was used to 
%       interpolate the last packet timestamps. If there was no next frame, 
%       the last packet timestamps was extrapolated. The original packet
%       timestamps can be recovered with:
%           approximate_timestamps(:, 1:12:end) 
%           (12 is the number of azimuth returns in each packet)
%
% NOTES:
%   Reference: https://velodynelidar.com/lidar/products/manual/63-9113%20HDL-32E%20manual_Rev%20E_NOV2012.pdf
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

path = [char(directory) num2str(timestamp) '.png'];
if ~exist(path, 'file')
    error("Velodyne file does not exist: %s", path);
end

% Hard coded configuration to simplify parsing code
hdl32e_range_resolution = 0.002;  % m / pixel
                      
% Parse data from image file
example_image_file = imread(path);
intensities = example_image_file(1:32, :);
ranges_raw = example_image_file(33:96, :);
angles_raw = example_image_file(97:98, :);
approximate_timestamps_raw = example_image_file(99:end, :);
ranges = double(reshape(typecast(reshape(ranges_raw, [], 1), 'uint16'), 32, [])) * hdl32e_range_resolution;
angles = double(reshape(typecast(reshape(angles_raw, [], 1), 'uint16'), 1, [])) * 2 * pi / 36000;
approximate_timestamps = reshape(typecast(reshape(approximate_timestamps_raw, [], 1), 'int64'), 1, []);

end
