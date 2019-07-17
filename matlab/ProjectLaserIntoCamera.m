function ProjectLaserIntoCamera(image_dir, laser_dir, ins_file, models_dir, extrinsics_dir, image_timestamp)
  
% ProjectLaserIntoCamera - build a pointcloud from LIDAR scans and display it
%   projected into a camera image
%
% ProjectLaserIntoCamera(image_dir, laser_dir, ins_file, models_dir,
%   extrinsics_dir, image_timestamp)
%
% INPUTS:
%   image_dir: directory containing images. MUST be the actual directory that
%     the images are in (eg. <dataset>/stereo/centre)
%   laser_dir: directory containing LIDAR scans
%   ins_file: file containing INS data
%   models_dir: directory containing camera intrinsics and undistortion LUTs
%   extrinsics_dir: directory containing sensor-to-sensor extrinsics
%   image_timestamp: timestamp of image to use

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

  if image_dir(end) ~= '/'
    image_dir = [image_dir '/'];
  end
  
  if laser_dir(end) ~= '/'
    laser_dir = [laser_dir '/'];
  end
  
  if models_dir(end) ~= '/'
    models_dir = [models_dir '/'];
  end
  
  if extrinsics_dir(end) ~= '/'
    extrinsics_dir = [extrinsics_dir '/'];
  end
  
  if ~exist('image_timestamp', 'var')
    % Get timestamps from file, to avoid having to list whole image
    % directory
    camera = regexp(image_dir, 'stereo|mono_left|mono_right|mono_rear', 'match');
    timestamp_file = [image_dir '../' camera{end} '.timestamps'];
    if ~exist(timestamp_file, 'file')
      timestamp_file = [image_dir '../../' camera{end} '.timestamps'];
      if ~exist(timestamp_file, 'file')
        error('Timestamp file for camera not found');
      end
    end
    timestamps = dlmread(timestamp_file);
     % Search for first chunk with data
    for chunk = 1:timestamps(end,2)
      timestamp_index = find(timestamps(:,2) == chunk, 1, 'first');
      if isempty(timestamp_index)
        error('No laser scans found in specified directory');
      end
      image_timestamp = timestamps(timestamp_index, 1);
      if exist([image_dir num2str(image_timestamp) '.png'], 'file')
        break;
      end
    end
  end

  % Combine LIDAR scans into a single pointcloud
  % Use a 10 second window either side of the image
  [pointcloud, reflectance] = BuildPointcloud(laser_dir, ins_file, ...
    extrinsics_dir, image_timestamp-1e7, image_timestamp+1e7, image_timestamp);
  
  camera = ...
      regexp(image_dir, '(stereo|mono_left|mono_right|mono_rear)', 'match');
  camera = camera{end};
  extrinsics_path = [extrinsics_dir camera '.txt'];
  if ~exist(extrinsics_path, 'file')
    error(['Camera extrinsics not found at ' extrinsics_path]);
  end
  camera_extrinsics = dlmread(extrinsics_path);
  
  extrinsics_path = [extrinsics_dir 'ins.txt'];
  if ~exist(extrinsics_path, 'file')
    error(['Camera extrinsics not found a ' extrinsics_path]);
  end
  ins_extrinsics = dlmread(extrinsics_path);
  
  if (contains(ins_file, 'ins.csv') || contains(ins_file, 'rtk.csv'))
    G_camera_ins = SE3MatrixFromComponents(camera_extrinsics) * ...
      SE3MatrixFromComponents(ins_extrinsics);
  else
    G_camera_ins = SE3MatrixFromComponents(camera_extrinsics);
  end
  
  [fx, fy, cx, cy, G_camera_image, LUT] = ...
      ReadCameraModel(image_dir, models_dir);
  
  image = LoadImage(image_dir, image_timestamp, LUT);
  if ~image
    error(['No image found for timestamp: ' num2str(image_timestamp)]);
  end
  
  % Transform pointcloud into camera image frame
  xyz = (G_camera_image \ G_camera_ins ...
      * [pointcloud; ones(1, size(pointcloud,2))]).';
  xyz(:,4) = [];
  
  % Find which points lie in front of the camera
  in_front = find(xyz(:,3) >= 0);
  
  % Project points into image using a pinhole camera model
  uv = [ fx .* xyz(in_front,1) ./ xyz(in_front,3) + cx, ...
         fy .* xyz(in_front,2) ./ xyz(in_front,3) + cy];
    
  % Find which points have projected within the image bounds
  in_img = (uv(:,1) >= 0.5 & uv(:,1) < size(image,2)-0.5) & ...
    (uv(:,2) >= 0.5 & uv(:,2) < size(image,1)-0.5);
  
  if sum(in_img) == 0
    warning('No points project into image. Is the vehicle stationary?');
  elseif sum(in_img) < 1000
    warning('Very few points project into image. Is the vehicle stationary?');
  end
  
  uv = uv(in_img,:);
  
  % Colour pointcloud by depth. Alternately, could use reflectance
  colours = xyz(in_front(in_img), 3);
  
  clf;
  imshow(image);
  colormap jet;
  hold on;
  scatter(uv(:,1),uv(:,2), 90, colours, '.');

end
