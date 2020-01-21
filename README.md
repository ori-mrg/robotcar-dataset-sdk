RobotCar Dataset SDK
====================
This repo contains sample MATLAB and Python code for viewing and manipulating data from the [Oxford Robotcar Dataset](http://robotcar-dataset.robots.ox.ac.uk) and [Oxford Radar Robotcar Dataset](http://ori.ox.ac.uk/datasets/radar-robotcar-dataset).

Directories
-----------
`extrinsics`: Extrinsic calibrations between the sensors on the vehicle

`matlab`: Sample matlab code for viewing and manipulating data

`models`: Camera models. See the sample python or matlab code for how to use these

`python`: Sample python code for viewing and manipulating data

`tags`: Lists of tags for each dataset

Obtaining Data
--------------
### Oxford RobotCar Dataset

To obtain the data, please visit the dataset [website](http://robotcar-dataset.robots.ox.ac.uk).
Downloads are chunked into `.tar` files containing no more than 5GB each, where each chunk corresponds to the same
time window for all sensors.

It is recommended that you extract all tar files to the same directory - this will leave all the data in a sensible
heirarchical directory structure.

An example script for scraping the dataset website can be found at [RobotCarDataset-Scraper](https://github.com/mttgdd/RobotCarDataset-Scraper).

### Oxford Radar Robotcar Dataset

To obtain the data, please visit the dataset [website](http://ori.ox.ac.uk/datasets/radar-robotcar-dataset).
Downloads are separated into individual zip files for each sensor, for each traversal.

It is recommended that you extract all tar files to the same directory - this will leave all the data in a sensible
heirarchical directory structure.

An example script for scraping the dataset website can be found at [radar-robotcar-dataset-sdk](https://github.com/dbarnes/radar-robotcar-dataset-sdk).
