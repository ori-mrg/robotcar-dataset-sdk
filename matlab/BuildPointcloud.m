function [pointcloud, reflectance] = BuildPointcloud(laser_dir, ins_file, extrinsics_dir, start_timestamp, end_timestamp, origin_timestamp)
  
% BuildPointcloud - builds a 3-dimensional pointcloud from multiple 
%   2-dimensional LIDAR scans
%
% [pointcloud, reflectance] = BuildPointcloud(laser_dir, ins_file, extrinsics_dir,
%   start_timestamp, end_timestamp, origin_timestamp)
%
% INPUTS:
%   laser_dir: directory containing LIDAR scans in binary format
%   ins_file: csv file containing INS data
%   extrinsics_dir: directory containing sensor-to-sensor extrinsics
%   start_timestamp (optional): UNIX timestamp of start of window over which to build 
%     pointcloud. Defaults to the first timestamp in laser_dir.
%   end_timestamp (optional): UNIX timestamp of end of window. Defaults to 
%     start_timestamp + 20 seconds
%   origin_timestamp (optional): timestamp for origin of coordinate frame.
%     If no origin timestamp is supplied, the origin of the coordinate frame is
%     placed at the start of the window.
%
% OUTPUTS:
%   pointcloud: 3xN array containing XYZ values of pointcloud, relative to the
%     INS frame at origin_timestamp
%   reflectance: 1xN array containing reflectance values for each point in 
%     pointcloud
%
% NOTE:
%   If no outputs are specified, function will plot pointcloud to screen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (c) 2016 University of Oxford
% Authors: 
%  Geoff Pascoe (gmp@robots.ox.ac.uk)
%  Will Maddern (wm@robots.ox.ac.uk)
%  Dan Barnes (dbarnes@robots.ox.ac.uk)
%
% This work is licensed under the Creative Commons 
% Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit 
% http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if laser_dir(end) ~= '/'
    laser_dir = [laser_dir '/'];
  end
  
  if extrinsics_dir(end) ~= '/'
    extrinsics_dir = [extrinsics_dir '/'];
  end
  
  
  laser = regexp(laser_dir, ...
      '(lms_front|lms_rear|ldmrs|velodyne_left|velodyne_right)', 'match');
  laser = laser{end};
  laser_timestamps = dlmread([laser_dir '../' laser '.timestamps']);
  
  if ~exist('start_timestamp', 'var')
    % Search for first chunk with data
    for chunk = 1:laser_timestamps(end,2)
      timestamp_index = find(laser_timestamps(:,2) == chunk, 1, 'first');
      if isempty(timestamp_index)
        error('No laser scans found in specified directory');
      end
      start_timestamp = laser_timestamps(timestamp_index, 1);
      if exist([laser_dir num2str(start_timestamp) '.bin'], 'file')
        break;
      end
    end
  end
  
  if ~exist('end_timestamp', 'var')
    end_timestamp = start_timestamp + 10e6;
  end
  
  if ~exist('origin_timestamp', 'var')
    origin_timestamp = start_timestamp;
  end
  
  start_timestamp = max(start_timestamp, laser_timestamps(1,1));
  end_timestamp = min(end_timestamp, laser_timestamps(end,1));
  
  start_index = find(laser_timestamps(:,1) >= start_timestamp, 1, 'first');
  end_index = find(laser_timestamps(:,1) <= end_timestamp, 1, 'last');
  laser_timestamps = laser_timestamps(start_index:end_index, :);
  
  % Load transforms between laser/ins and vehicle
  laser_extrinisics = dlmread([extrinsics_dir laser '.txt']);
  ins_extrinsics = dlmread([extrinsics_dir 'ins.txt']);
  
  % Find pose for each LIDAR scan, relative to origin
  if (contains(ins_file, 'ins.csv') || contains(ins_file, 'rtk.csv'))
    ins_poses = InterpolatePoses(ins_file, laser_timestamps(:,1)', ...
      origin_timestamp, contains(ins_file, 'rtk.csv'));
    G_ins_laser = SE3MatrixFromComponents(ins_extrinsics) \ ...
      SE3MatrixFromComponents(laser_extrinisics);
  else
    ins_poses = RelativeToAbsolutePoses(ins_file, laser_timestamps(:,1)', ...
      origin_timestamp);
    G_ins_laser = SE3MatrixFromComponents(laser_extrinisics);
  end
  
  
  
  n = size(laser_timestamps,1);
  pointcloud = [];
  reflectance = [];
  for i=1:n
    scan_path = [laser_dir num2str(laser_timestamps(i,1)) '.bin'];
    if ~contains(laser, 'velodyne')
        if ~exist(scan_path, 'file')
          continue;
        end
        scan_file = fopen(scan_path);
        scan = fread(scan_file, 'double');
        fclose(scan_file);

        % The scan file contains repeated tuples of three values
        scan = reshape(scan, [3 numel(scan)/3]);
        if regexp(laser_dir, '(lms_rear|lms_front)')
          % LMS tuples are of the form (x, y, R)
          reflectance = [reflectance scan(3,:)];
          scan(3,:) = zeros(1, size(scan,2));
        end
    else
        if exist(scan_path, 'file')
            ptcld = LoadVelodyneBinary(laser_dir, num2str(laser_timestamps(i,1)));
        else
            scan_path = [laser_dir num2str(laser_timestamps(i,1)) '.png'];
            if ~exist(scan_path, 'file')
              continue;
            end
            [ranges, intensities, angles, ~] = ...
                LoadVelodyneRaw(laser_dir, num2str(laser_timestamps(i,1)));
            ptcld = VelodyneRawToPointcloud(ranges, intensities, angles);
        end
        scan = ptcld(1:3, :);
        reflectance = [reflectance ptcld(4, :)];
    end
    
    % Transform scan to INS frame, move to the INS pose at the scan's timestamp,
    % then transform back to LIDAR frame
    scan = ins_poses{i} * G_ins_laser * [scan; ones(1, size(scan,2))];
    pointcloud = [pointcloud scan(1:3,:)];
    
  end
  
  if size(pointcloud) == 0
    error(['No valid scans found. Missing chunk ' num2str(laser_timestamps(end,2))]);
  end
  
  % If nobody is saving the result, plot the pointcloud
  if nargout == 0
    if ~isempty(reflectance)
      % Increase contrast in reflectance values
      colours = (reflectance - min(reflectance)) / ...
          (max(reflectance) - min(reflectance));
      colours = 1 ./ (1 + exp(-10*(colours - mean(colours))));
    else
      colours = 0.5 * ones(1, size(pointcloud,2));
    end
    
    figure('name','Pointcloud Viewer');
    colormap gray;
    
    % Using these axes makes the plot easy to view in matlab
    scatter3(-pointcloud(2,:), -pointcloud(1,:), -pointcloud(3,:), 1, ...
      colours, '.');
    axis equal;
  end
end
