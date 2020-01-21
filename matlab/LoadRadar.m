function [timestamps, azimuths, valid, fft_data, radar_resolution] = ...
    LoadRadar(directory, timestamp)
%
% LoadRadar - Decode a radar dataset example.
%
% INPUTS:
%   directory: directory containing radar data named <timestamp>.png
%   timestamp: timestamp of radar data to load
%
% OUTPUTS:
%   timestamps: Timestamp for each azimuth in int64 (UNIX time)
%   azimuths: Rotation for each polar radar azimuth (radians)
%   valid: Mask of whether azimuth data is an original sensor reading or
%       interpolated from adjacent azimuths
%   fft_data: Radar power readings along each azimuth
%   radar_resolution: Resolution of the polar radar data (metres per pixel)
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
    error("Radar file does not exist: %s", path);
end

% Hard coded configuration to simplify parsing code
radar_resolution = 0.0432;  % m / pixel
encoder_size = 5600;  % encoder ticks

% Parse data from image file
example_image_file = imread(path);
timestamps = typecast(reshape(example_image_file(:,1:8)', [], 1), 'int64');
valid = example_image_file(:,11) == 255;
fft_data = double(example_image_file(:,12:end)) / 255;
azimuths = typecast(reshape(example_image_file(:,9:10)', [], 1), 'uint16');

% Convert azimuths to radians
azimuths = double(azimuths) / encoder_size * 2 * pi;
end
