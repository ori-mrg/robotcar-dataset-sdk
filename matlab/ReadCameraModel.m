function [fx, fy, cx, cy, G_camera_image, LUT] = ReadCameraModel(image_dir, models_dir)
  
% ReadCameraModel - load camera intrisics and undistortion LUT from disk
%
% [fx, fy, cx, cy, G_camera_image, LUT] = ReadCameraModel(image_dir, models_dir)
%
% INPUTS:
%   image_dir: directory containing images for which camera model is required
%   models_dir: directory containing camera models
%
% OUTPUTS:
%   fx: horizontal focal length in pixels
%   fy: vertical focal length in pixels
%   cx: horizontal principal point in pixels
%   cy: vertical principal point in pixels
%   G_camera_image: transform that maps from image coordinates to the base
%     frame of the camera. For monocular cameras, this is simply a rotation.
%     For stereo camera, this is a rotation and a translation to the left-most
%     lense.
%   LUT: undistortion lookup table. For an image of size w x h, LUT will be an
%     array of size [w x h, 2], with a (u,v) pair for each pixel. Maps pixels
%     in the undistorted image to pixels in the distorted image

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
  
  if models_dir(end) ~= '/'
    models_dir = [models_dir '/'];
  end
  
  camera = regexp(image_dir, '(stereo|mono_left|mono_right|mono_rear)', ...
      'match');
  camera = camera{end};
  
  if strcmp(camera, 'stereo')
    sensor = regexp(image_dir, '(left|centre|right)', 'match');
    sensor = sensor{end};
    
    if strcmp(sensor, 'left')
      model = 'wide_left';
    elseif strcmp(sensor, 'right')
      model = 'wide_right'; % narrow_right also applies to this sensor
    elseif strcmp(sensor, 'centre')
      model = 'narrow_left';
    else
      error('Unknown camera model for given directory');
    end
    
    intrinsics_path = [models_dir camera '_' model '.txt'];
    lut_path = [models_dir camera '_' model '_distortion_lut.bin'];
    
  else
    intrinsics_path = [models_dir camera '.txt'];
    lut_path = [models_dir camera '_distortion_lut.bin'];
  end
  
  if ~exist(intrinsics_path, 'file')
    error(['Camera intrinsics not found at ' intrinsics_path]);
  end
  intrinsics = dlmread(intrinsics_path);
  
  % First line of intrinsics file: fx fy cx xy
  fx = intrinsics(1, 1);
  fy = intrinsics(1, 2);
  cx = intrinsics(1, 3);
  cy = intrinsics(1, 4);
  
  % Lines 2-5 of intrinsics file: 4x4 matrix that transforms between 
  % x-forward coordinate frame at camera origin, and image frame for
  % the specific lense
  G_camera_image = intrinsics(2:5, 1:4);
  
  if nargout > 5
    if ~exist(lut_path, 'file') == -1
      error(['Distortion LUT not found at ' lut_path]);
    end
    lut_file = fopen(lut_path);
    LUT = fread(lut_file, 'double');
    fclose(lut_file);
    
    % LUT consists of a (u,v) pair for each pixel
    LUT = reshape(LUT, [numel(LUT)/2, 2]);
  end
  
end
