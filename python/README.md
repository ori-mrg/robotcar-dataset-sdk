RobotCar Dataset Python Tools
=============================

This directory contains sample python code for viewing and manipulating data from the [Oxford Robotcar Dataset](http://robotcar-dataset.robots.ox.ac.uk) and [Oxford Radar Robotcar Dataset](http://ori.ox.ac.uk/datasets/radar-robotcar-dataset).

Requirements
------------
The python tools have been tested on Python 2.7. 
Python 3.* compatibility has not been verified.

The following packages are required:
* numpy
* matplotlib
* colour_demosaicing
* pillow
* opencv-python
* open3d-python

These can be installed with pip:

```
pip install numpy matplotlib colour_demosaicing pillow opencv-python open3d-python
```

Command Line Tools
------------------

### Viewing Images
The `play_images.py` script can be used to view images from the dataset.

```bash
python play_images.py --images_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/stereo/centre
```

If you wish to undistort the images before viewing them, pass the camera model directory as a second argument:

```bash
python play_images.py --images_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/stereo/centre --models_dir /path/to/camera/models
```

### Viewing Radar Scans
The `play_radar.py` script can be used to view radar scans.

```bash
python play_radar.py --images_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/radar
```

### Viewing Velodyne Scans
The `play_velodyne.py` script can be used to view velodyne scans from raw or binary form.

```bash
python play_velodyne.py --images_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/velodyne_left
```

### Building Pointclouds
The `build_pointcloud.py` script builds and displays a 3D pointcloud by combining multiple LIDAR scans with a pose source.
The pose source can be either INS data or the supplied visual odometry data. For example:

```bash
python build_pointcloud.py --laser_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/lms_front --extrinsics_dir ../extrinsics --poses_file /path/to/data/yyyy-mm-dd-hh-mm-ss/vo/vo.csv'
```

### Projecting pointclouds into images
The `project_laser_into_camera.py` script first builds a pointcloud, then projects it into a camera image using a pinhole camera model.
For example:

```bash
python project_laser_into_camera.py --image_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/stereo/centre --laser_dir /path/to/data/yyyy-mm-dd-hh-mm-ss/ldmrs --poses_file /path/to/data/yyyy-mm-dd-hh-mm-ss/vo/vo.csv --models_dir /path/to/models --extrinsics_dir ../extrinsics --image_idx 200
```

Usage from Python
-----------------
The scripts here are also designed to be used in your own scripts.

* `build_pointcloud.py`: function for building a pointcloud from LIDAR and odometry data
* `camera_model.py`: loads camera models from disk, and provides undistortion of images and projection of pointclouds
* `interpolate_poses.py`: functions for interpolating VO or INS data to obtain pose estimates at arbitrary timestamps
* `transform.py`: functions for converting between various transform representations
* `image.py`: function for loading, Bayer demosaicing and undistorting images
* `load_velodyne_raw.py`: reads a raw Velodyne scan from a specified directory and at a specified timestamp
* `velodyne_raw_to_pointcloud.py`: takes the ranges(m), intensities (uint8), and azimuth angles (rad) from a decoded raw Velodyne scan and produce a pointcloud in cartesian form including per-point intensity values
* `load_velodyne_binary.py`: reads a binary Velodyne scan from a specified directory and at a specified timestamp and returns a pointcloud in cartesian form including per-point intensity values
* `load_radar.py`: reads a raw radar scan from a specified directory and at a specified timestamp, and returns the per-azimuth UNIX timestamps (microsec), azimuth angles (rad), and power returns (dB) as well as the range resolution (cm)
* `radar_polar_to_cartesian.py`: takes the azimuth angles (rad), power returns (dB) and radar range resolution (cm) from a decoded radar scan and converts the polar scan into cartesian form according to a desired cartesian resolution (m) and cartesian size (px)

For examples of how to use these functions, see the command line tools above.
