function cart_img = RadarPolarToCartesian(radar_azimuth, radar_fft, ...
    radar_resolution, cart_resolution, cart_pixel_width, interpolate_crossover)
%
% RadarPolarToCartesian - Convert a polar radar scan to cartesian.
%
% [cart_img, sample_range, sample_angle] = RadarPolarToCartesian( ...
%     radar_azimuth, radar_fft, radar_resolution, cart_resolution, cart_min_range)
%
% INPUTS:
%   radar_azimuth: Rotation for each polar radar azimuth (radians)
%   radar_fft: Polar radar power readings
%   radar_resolution: Resolution of the polar radar data (metres per pixel)
%   cart_resolution: Output cartesian pixel resolution (metres per pixel)
%   cart_pixel_width: Width and height of the cartesian output (pixels)
%   interpolate_crossover: If true interpolates between the end and start
%       azimuth of the scan. In practice a scan before / after should be used.
%
% OUTPUTS:
%   cart_img: Cartesian radar power readings
% 
% NOTES:
%     The output radar cartesian is defined as as follows where
%     X and Y are the `real` world locations of the pixels in metres:
% 
%      If 'cart_pixel_width' is odd:
% 
%                     +------ Y = -1 * cart_resolution (m)
%                     |+----- Y =  0 (m) at centre pixel
%                     ||+---- Y =  1 * cart_resolution (m)
%                     |||+--- Y =  2 * cart_resolution (m)
%                     |||| +- Y =  floor(cart_pixel_width / 2) * cart_resolution (m) (at last pixel)
%                     |||| +-----------+
%                     vvvv             v
%      +---------------+---------------+
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      +---------------+---------------+ <-- X = 0 (m) at centre pixel
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      |               |               |
%      +---------------+---------------+
%      <------------------------------->
%          cart_pixel_width (pixels)
% 
% 
%      If 'cart_pixel_width' is even:
% 
%                     +------ Y = -0.5 * cart_resolution (m)
%                     |+----- Y =  0.5 * cart_resolution (m)
%                     ||+---- Y =  1.5 * cart_resolution (m)
%                     |||+--- Y =  2.5 * cart_resolution (m)
%                     |||| +- Y =  (cart_pixel_width / 2 - 0.5) * cart_resolution (m) (at last pixel)
%                     |||| +----------+
%                     vvvv            v
%      +------------------------------+
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      |                              |
%      +------------------------------+
%      <------------------------------>
%          cart_pixel_width (pixels)
% 
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

if rem(cart_pixel_width, 2) == 0 
    cart_min_range = (cart_pixel_width / 2 - 0.5) * cart_resolution;
else
    cart_min_range = floor(cart_pixel_width / 2) * cart_resolution;
end
sample_pos = linspace(-cart_min_range, cart_min_range, cart_pixel_width);

[Y, X] = meshgrid(sample_pos, -sample_pos);
sample_range = sqrt(X.^2 + Y.^2);
sample_angle = atan2(Y, X);
sample_angle(sample_angle<0) = sample_angle(sample_angle<0) + 2 * pi;

% Interpolate Radar Data Coordinates
sample_u = (sample_range + radar_resolution/2) / radar_resolution;
sample_v = (sample_angle - radar_azimuth(1)) / diff(radar_azimuth(1:2)) + 1;

% We clip the sample points to the minimum sensor reading range so that we
% do not have undefined results in the centre of the image. In practice
% this region is simply undefined.
sample_u(sample_u < 1) = 1;

if interpolate_crossover
    radar_fft = [radar_fft(end,:); radar_fft; radar_fft(1,:)];
    sample_v = sample_v + 1;
end

cart_img = interp2(radar_fft, sample_u, sample_v);

end
