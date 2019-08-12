function PlayVelodyne(directory, mode)

% PlayVelodyne - display velodyne from a given dataset
%
% PlayVelodyne(directory)
%
% INPUTS:
%   directory: directory containing velodyne data. This directory must be:
%     - A Velodyne data directory (eg. <dataset>/velodyne_left)
%   mode: Mode to run in, one of: (default: raw_interp)
%     - raw - visualise the raw velodyne data (intensities and ranges)
%       (files of the form  <timestamp>.png)
%     - raw_interp - visualise the raw velodyne data (intensities and 
%       ranges) interpolated to consistent azimuth angles between scans.
%       (files of the form  <timestamp>.png)
%     - raw_ptcld - visualise the raw velodyne data converted to a
%       pointcloud (converts files of the form <timestamp>.png to
%       pointcloud)
%     - bin_ptcld - visualise the precomputed velodyne pointclouds
%       (files of the form <timestamp>.bin). This is approximately 2x
%       faster than running the conversion from raw data `raw_ptcld` at the
%       cost of approximately 8x storage space.
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

if ~exist('mode', 'var')
    mode = 'raw_interp';
end
directory = char(directory);
if directory(end) == '/'
    directory = directory(1:end-1);
end
[~, path_end] = fileparts(directory);
directory = char(directory);
if ~any(contains({'velodyne_left', 'velodyne_right'}, path_end))
    error("Directory must be a velodyne data directory but you provided: %s", ...
        directory);
end

valid_modes = {'raw', 'raw_interp', 'raw_ptcld', 'bin_ptcld'};
if ~any(contains(valid_modes, mode))
    error('Invalid mode passed: %s', mode);
end

vel_timestamps = dlmread([directory '.timestamps']);
vel_timestamps = vel_timestamps(:, 1);

h = [];
interp_angles = wrapTo2Pi(linspace(pi, 3*pi, 720));
% Here we start at frame 2 so that we have a full 360 degree scan to start 
% at so that the visualisation code can be more optimal. 
for i = 2 : numel(vel_timestamps)
    
    % Decode velodyne example
    if strcmp(mode, 'bin_ptcld')
        ptcld = LoadVelodyneBinary(directory, vel_timestamps(i));
    else
        [ranges, intensities, angles, approximate_timestamps] = ...
            LoadVelodyneRaw(directory, vel_timestamps(i));
        % A pointcloud can be extracted directly from the raw scan, 
        % although it is approximately 2x slower, by running:
        if strcmp(mode, 'raw_ptcld')
            ptcld = VelodyneRawToPointcloud(ranges, intensities, angles);
        elseif strcmp(mode, 'raw_interp')
            % Account any overlap (could have spun more than 2 * pi)
            crossover = find(angles < angles(1), 1, 'last');
            if ~isempty(crossover)
                angles = angles(1:crossover);
                intensities = intensities(:, 1:crossover);
                ranges = ranges(:, 1:crossover);
            end
            ranges = interp1(angles, ranges', interp_angles)';
            intensities = uint8(interp1(angles, single(intensities'), interp_angles)');
            angles = interp_angles;
        end
    end
    
    if isempty(h)
        fig = figure(72327);
        clf;
        fig.Name = "Velodyne Visualisation Example";
        fig.NumberTitle = "off";
        
        if contains(mode, '_ptcld')
            h{1} = scatter3(ptcld(1, :), ptcld(2, :), ptcld(3, :), 20, ptcld(4, :), 'filled');
            set(gca, 'Ydir', 'reverse');
            set(gca, 'Zdir', 'reverse');
            axis('equal');
            axis([-50, 50, -50, 50, -5, 5]);
            title('Velodyne Pointcloud Visualisation', 'FontSize', 16);
        else
            % Intensity Plot
            subplot(2, 1, 1, 'align');
            h{1} = imagesc(intensities, [0, max(intensities(:))/3]);
            ylabel('Elevation (radians)', 'FontSize', 14);
            yticks([]);
            if strcmp(mode, 'raw_interp')
                xticklabels(angles(xticks));
            else
                xticks([]);
            end
            xlabel('Azimuth (radians)', 'FontSize', 14);
            title('Velodyne Intensity Visualisation', 'FontSize', 16);

            % Range Plot
            subplot(2, 1, 2, 'align');
            h{2} = imagesc(ranges, [0, max(ranges(:))/2]);
            ylabel('Elevation (radians)', 'FontSize', 14);
            if strcmp(mode, 'raw_interp')
                xticklabels(angles(xticks));
            else
                xticks([]);
            end
            xticklabels(angles(xticks));
            xlabel('Azimuth (radians)', 'FontSize', 14);
            title('Velodyne Range Visualisation', 'FontSize', 16);
        end
    else
        if contains(mode, '_ptcld')
            h{1}.XData = ptcld(1, :);
            h{1}.YData = ptcld(2, :);
            h{1}.ZData = ptcld(3, :);
            h{1}.CData = ptcld(4, :);
        else
            h{1}.CData = intensities;
            h{2}.CData = ranges;
        end
    end
    drawnow;
end
