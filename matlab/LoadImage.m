function [image] = LoadImage(directory, timestamp, LUT)
  
% LoadImage - load a rectified image from disk
%
% [image] = LoadImage(directory, timestamp, LUT)
%
% eg.
% timestamps = dlmread('<dataset_root>/stereo.timestamps');
% [ ~, ~, ~, ~, ~, LUT] = ...
%     ReadCameraModel('<models_dir>/stereo_wide_left_undistortion.bin');
% image = LoadImage('<dataset_root>/stereo/left', timestamps(100,1), LUT);
%
% INPUTS:
%   directory: directory containing images named <timestamp>.png
%   timestamp: timestamp of image to load
%   LUT (optional): lookup table for image rectification, as returned from 
%     ReadCameraModel. If not supplied, original distorted image will be 
%     returned.
%     See ReadCameraModel and UndistortImage
%   
% OUTPUTS:
%   image: image at the given timestamp. If an undistortion lookup table is
%     supplied, image will be undistorted.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (c) 2016 University of Oxford
% Authors: 
%  Geoff Pascoe (gmp@robots.ox.ac.uk)
%  Will Maddern (wm@robots.ox.ac.uk)
%
% This work is licensed under the Creative Commons 
% Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit 
% http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if directory(end) ~= '/'
    directory = [directory '/'];
  end
  
  path = [directory num2str(timestamp) '.png'];
  if ~exist(path, 'file')
    image = false;
    return;
  end
  
  if regexp(directory, 'stereo')
    bayer_pattern = 'gbrg';
  else
    bayer_pattern = 'rggb';
  end
  
  image = demosaic(imread(path), bayer_pattern);
  
  if exist('LUT', 'var')
    image = UndistortImage(image, LUT);
  end
  
end
