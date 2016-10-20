function [date_time] = TimestampToString(t)

% TimestampToString - convert a UNIX timestamp to a human-readable string
%
% [date_time] = TimestampToString(t)
%
% INPUTS:
%   t: UNIX timestamp
%
% OUTPUTS:
%   date_time: string representing t in the format yyyy/mm/dd HH:MM:SS.FFF

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
  
  microseconds_per_day = 864e8; % 60 * 60 * 24 * 1000000
  unix_epoch = datenum('1970', 'yyyy');
  date_time = datestr(t / microseconds_per_day + unix_epoch, ...
    'yyyy/mm/dd HH:MM:SS.FFF');
  
end
