function [undistorted] = UndistortImage(image, LUT)
  
% UndistortImage - undistort an image using a lookup table
% 
% [undistorted] = UndistortImage(image, LUT)
%
% eg.
% [ ~, ~, ~, ~, ~, LUT] = ...
%     ReadCameraModel('<models_dir>/stereo_wide_left_undistortion.bin');
% image = imread('<image_dir>/<timestamp>.png');
% undistorted = UndistortImage(image, LUT);
%
% INPUTS:
%   image: distorted image to be rectified
%   LUT: lookup table mapping pixels in the undistorted image to pixels in the
%     distorted image, as returned from ReadCameraModel
%
% OUTPUTS:
%   undistorted: image after undistortion

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

undistorted = zeros(size(image), class(image));

for channel = 1:size(image,3)
  % Interpolate pixels from distorted image using lookup table
  channel_data = cast(reshape(interp2(cast(image(:,:,channel), 'single'), ...
                               LUT(:,1)+1, ...
                               LUT(:,2)+1, ...
                               'bilinear'), ...
                     fliplr(size(image(:,:,channel)))).', class(image));
  
  undistorted(:,:,channel) = channel_data;
end

end
