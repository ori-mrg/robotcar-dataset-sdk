function PlayRadar(directory)

% PlayRadar - display radar from a given dataset
%
% PlayRadar(directory)
%
% INPUTS:
%   directory: directory containing radar data. This directory can be:
%     - Top level dataset directory
%     - Radar data directory (eg. <dataset>/radar)


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
if directory(end) == '/'
    directory = directory(1:end-1);
end
[~, path_end] = fileparts(directory);
if ~strcmp(path_end, "radar")
    directory = [directory '/radar'];
end

% Cartesian Visualsation Setup
% Resolution of the cartesian form of the radar scan in metres per pixel
cart_resolution = .25; 
% Cartesian visualisation size (used for both height and width)
cart_pixel_size = 501; % pixels
interpolate_crossover = true;

radar_timestamps = dlmread([directory '.timestamps']);
radar_timestamps = radar_timestamps(:, 1);

h = [];
for i = 1 : numel(radar_timestamps)
    
    % Decode radar example
    [timestamps, azimuths, valid, fft_data, radar_resolution] = ...
        LoadRadar(directory, radar_timestamps(i));
    
    % Convert radar example to cartesian
    cart_img = RadarPolarToCartesian( ...
        azimuths, fft_data, radar_resolution, cart_resolution, ...
        cart_pixel_size, interpolate_crossover);
    
    % Downsample radar data to speed up visualisation
    downsample_rate = 4;
    fft_data_vis = fft_data(:, 1:downsample_rate:end);
    if isempty(h)
        fig = figure(72327);
        fig.Name = "Radar Visualisation Example";
        fig.NumberTitle = "off";
        
        range_ticks = ((1:size(fft_data_vis, 2))-0.5) * ...
            radar_resolution * downsample_rate;
        
        % Polar Plot
        colormap gray;
        subplot(1, 2, 1, 'align');
        h{1} = imagesc(fft_data_vis, [0, 0.5]);
        yticklabels(azimuths(yticks));
        ylabel('Azimuth (radians)', 'FontSize', 12);
        xticklabels(range_ticks(xticks));
        xlabel('Range (metres)', 'FontSize', 12);
        title('Polar Radar Visualisation', 'FontSize', 14);
        
        % Cartesian Plot
        pixel_range = floor(cart_pixel_size / 2);
        tick_labels = (-pixel_range:pixel_range) * cart_resolution;
        tick_locs = [1, pixel_range+1, cart_pixel_size];
        subplot(1, 2, 2, 'align');
        h{2} = imagesc(cart_img, [0, 0.5]);
        xticks(tick_locs);
        yticks(tick_locs);
        axis image;
        ylabel('X (metres)', 'FontSize', 12);
        yticklabels(-tick_labels(yticks));
        xlabel('Y (metres)', 'FontSize', 12);
        xticklabels(tick_labels(xticks));
        title('Cartesian Radar Visualisation', 'FontSize', 14);
        
    else
        h{1}.CData = fft_data_vis;
        h{2}.CData = cart_img;
    end
    drawnow;
end
