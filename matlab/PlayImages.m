function PlayImages(directory, models_dir, scale)
  
% PlayImages - display images from a given dataset
%
% PlayImages(directory, models_dir, scale)
%
% INPUTS:
%   directory: directory containing images. This directory can be:
%     - Top level dataset directory: all images (stereo and mono) will be played
%     - Single camera directory (eg. <dataset>/stereo)
%     - Single sensor directory (eg. <dataset>/stereo/left)
%   models_dir (optional): directory containing camera models. If supplied,
%     images will be undistorted before display
%   scale (optional): factor by which to scale images before display

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

  if ~exist('scale', 'var')
    scale = 1;
  end
  
  if ~exist('models_dir','var')
    rectify = false;
  else
    rectify = true;
    if models_dir(end) ~= '/'
      models_dir = [models_dir '/'];
    end
  end
  
  if directory(end) ~= '/'
    directory = [directory '/'];
  end
  
  if exist([directory 'stereo'],'file') ...
      || exist([directory 'mono_left'], 'file') ...
      || exist([directory 'mono_right'], 'file') ...
      || exist([directory 'mono_rear'], 'file')
    % Top level log directory, play all
    directories = {};
    stereo_dirs = {};
    models = {};
    stereo_models = {};
    timestamps = {};
    
    % Find stereo directories and optionally load models
    stereo_sensors = {'left', 'centre', 'right'};
    for i=1:numel(stereo_sensors)
      if exist([directory 'stereo/' stereo_sensors{i}], 'file')
        stereo_dirs{numel(stereo_dirs) + 1} = ...
            [directory 'stereo/' stereo_sensors{i} '/'];
        if numel(directories) == 0
          directories{1} = stereo_dirs{end};
          timestamps{1} = dlmread([directory 'stereo.timestamps']);
        end
        if rectify
          [~, ~, ~, ~, ~, stereo_models{numel(stereo_dirs)}] = ...
              ReadCameraModel(stereo_dirs{end}, models_dir);
        end
      end
    end
    
    % Find mono directories and optionally load models
    mono_cameras = {'left', 'rear', 'right'};
    for i=1:numel(mono_cameras)
      if exist([directory 'mono_' mono_cameras{i}], 'file')
        directories{numel(directories) + 1} = ...
            [directory 'mono_' mono_cameras{i} '/'];
        timestamps{numel(directories)} = ...
            dlmread([directory 'mono_' mono_cameras{i} '.timestamps']);
        if rectify
          [~, ~, ~, ~, ~, models{numel(directories)}] = ...
              ReadCameraModel(directories{end}, models_dir);
        end
      end
    end
    
    next_index = ones(numel(directories),1);
    next_timestamp = zeros(numel(directories),1);
    for i = 1:numel(directories)
      next_timestamp(i) = timestamps{i}(1,1);
    end
    
    while min(next_index) > 0
      cameras = find(next_timestamp == min(next_timestamp));
      
      for c = 1:numel(cameras)
        camera = cameras(c);
        if regexp(directories{camera}, 'stereo')
          image = cell(numel(stereo_dirs),1);
          for j = 1:numel(stereo_dirs)
            if rectify
              image{j} = LoadImage(stereo_dirs{j}, next_timestamp(camera), ...
                  stereo_models{j});
            else
              image{j} = LoadImage(stereo_dirs{j}, next_timestamp(camera));
            end
          end
          image = cat(2, image{:});
          if numel(directories) > 1 && size(image, 1) > 1
            subplot(2, numel(directories)-1, 1:(numel(directories)-1));
          end
        else
          if rectify
            image = LoadImage(directories{camera}, next_timestamp(camera), ...
                models{camera});
          else
            image = LoadImage(directories{camera}, next_timestamp(camera));
          end
          path = [directories{camera} num2str(next_timestamp(camera)) '.png'];
          if size(image,1) > 1
            if numel(stereo_dirs) > 1
              subplot(2, numel(directories)-1, numel(directories) + camera - 2);
            else
              subplot(1, numel(directories), camera);
            end
          end
        end
        
        if size(image,1) > 1
          timestamp = next_timestamp(camera);
          imshow(image);
          xlabel(TimestampToString(timestamp));
        end
        
        next_index(camera) = next_index(camera) + 1;
        next_timestamp(camera) = timestamps{camera}(next_index(camera), 1);
        while ~exist( ...
              [directories{camera} num2str(next_timestamp(camera)) '.png'], ...
              'file')
          chunk = timestamps{camera}(next_index(camera),2);
          fprintf('Chunk %d not found in directory %s\n', chunk, ...
              directories{camera});
          next_index(camera) = find(timestamps{camera}(:,2) == chunk + 1, 1, ...
              'first');
          next_timestamp(camera) = timestamps{camera}(next_index(camera), 1);
          if isempty(next_index(camera))
            next_index(camera) = -1;
          end
        end
        
      end
      drawnow;
    end 
    
  else
    % Single log directory
    disp('Single Log');
    if exist([directory 'left'],'file') ...
        || exist([directory 'centre'], 'file') ...
        || exist([directory 'right'], 'file')
      % Stereo directory
      directories = {};
      models = {};
      timestamps = dlmread([directory '../stereo.timestamps']);
      
      % find which sensors are present and optionally load models
      stereo_sensors = {'left', 'centre', 'right'};
      for i=1:numel(stereo_sensors)
        if exist([directory  stereo_sensors{i}], 'file')
          directories{numel(directories) + 1} = ...
              [directory stereo_sensors{i} '/'];
          if rectify
            [~, ~, ~, ~, ~, models{numel(directories)}] = ...
                ReadCameraModel(directories{end}, models_dir);
          end
        end
      end
      
      n = numel(timestamps);
      next_chunk = ones(size(directories));
      i = 1;
      while i <= n;
        image = cell(numel(directories),1);
        timestamp = timestamps(i,1);
        for j = 1:numel(directories)
          path = [directories{j} num2str(timestamp) '.png'];
          if ~exist(path, 'file')
            if timestamps(i,2) >= next_chunk(j)
              fprintf('Chunk %d not found in directory %s\n', ...
                  timestamps(i, 2), directories{j});
              next_chunk(j) = timestamps(i,2) + 1;
              i = find(timestamps(:,2) == next_chunk(j), 1, 'first') - 1;
              if isempty(i)
                i = n+1;
              end
            end
            continue;
          end
          image{j} = demosaic(imread(path), 'gbrg');
          if rectify
            image{j} = UndistortImage(image{j}, models{j});
          end
          if scale ~= 1
            image{j} = imresize(image{j}, scale);
          end
        end
        image = cat(2, image{:});
        imshow(image);
        xlabel(TimestampToString(timestamp));
        drawnow;
        i = i+1;
      end
    else
      % Single camera
      camera = regexp(directory, '(stereo|mono_(left|right|rear))', 'match');
      if exist([directory '../' camera{end} '.timestamps'], 'file')
        timestamps = dlmread([directory '../' camera{end} '.timestamps']);
      else
        timestamps = dlmread([directory '../../' camera{end} '.timestamps']);
      end
      n = numel(timestamps);
      if regexp(directory, 'stereo')
        bayer_pattern = 'gbrg';
      else
        bayer_pattern = 'rggb';
      end
      if rectify
        [~, ~, ~, ~, ~, model] = ReadCameraModel(directory, models_dir);
      end
      next_chunk = 1;
      i = 1;
      while i <= n
        filename = [directory num2str(timestamps(i,1)) '.png'];
        if exist(filename, 'file')
          image = imread(filename);
          image = demosaic(image, bayer_pattern);
          if scale ~= 1
            image = imresize(image, scale);
          end
          if rectify
            image = UndistortImage(image, model);
          end
          imshow(image);
          xlabel(TimestampToString(timestamps(i,1)));
          drawnow;
        elseif timestamps(i,2) >= next_chunk
          fprintf('Image not found. Missing chunk %d\n', timestamps(i,2));
          next_chunk = timestamps(i,2) + 1;
          i = find(timestamps(:,2) == next_chunk, 1, 'first') - 1;
          if isempty(i)
            i = n+1;
          end
        end
        i = i+1;
      end
    end
  end
end
