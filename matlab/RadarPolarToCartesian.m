function cart_img = RadarPolarToCartesian(azimuths, fft_data, ...
    radar_resolution, cart_resolution, cart_pixel_width, interpolate_crossover)
%
% RadarPolarToCartesian - Convert a polar radar scan to cartesian form.
%
% [cart_img, sample_range, sample_angle] = RadarPolarToCartesian( ...
%    azimuths, fft_data, radar_resolution, cart_resolution, cart_min_range)
%
% INPUTS:
%   azimuths: Rotation for each polar radar azimuth (radians)
%   fft_data: Polar radar power readings
%   radar_resolution: Resolution of the raw polar radar data 
%       (metres per pixel) as returned by LoadRadar. For the Oxford 
%       Radar RobotCar Dataset this will always be 0.0432.
%   cart_resolution: Output cartesian pixel resolution (metres per pixel)
%   cart_pixel_size: Width and height of the returned square cartesian 
%       output (pixels). Please see the Notes below for a full explanation
%       of how this is used. 
%   interpolate_crossover: If true interpolates between the end and start
%       azimuth of the scan. In practice a scan before / after should be 
%       used but this prevents nan regions in the return cartesian form.
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
sample_v = (sample_angle - azimuths(1)) / diff(azimuths(1:2)) + 1;

% We clip the sample points to the minimum sensor reading range so that we
% do not have undefined results in the centre of the image. In practice
% this region is simply undefined.
sample_u(sample_u < 1) = 1;

if interpolate_crossover
    fft_data = [fft_data(end,:); fft_data; fft_data(1,:)];
    sample_v = sample_v + 1;
end

cart_img = interp2(fft_data, sample_u, sample_v);

end
