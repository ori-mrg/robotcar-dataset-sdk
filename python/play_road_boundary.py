################################################################################
#
# Copyright (c) 2017 University of Oxford
# Authors:
#  Daniele De Martini (daniele@robots.ox.ac.uk)
#
# This work is licensed under the Creative Commons
# Attribution-NonCommercial-ShareAlike 4.0 International License.
# To view a copy of this license, visit
# http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to
# Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#
################################################################################

import argparse
from matplotlib import pyplot as plt
from pathlib import Path
from tqdm import tqdm

from datetime import datetime as dt
from road_boundary import load_road_boundary_image, load_road_boundary_mask
from camera_model import CameraModel

parser = argparse.ArgumentParser(description='Play back images from a given directory')

parser.add_argument('dir', type=str, help='Directory containing images.')
parser.add_argument('--models_dir', type=str, default=None, help='(optional) Directory containing camera model. If supplied, images will be undistorted before display')
parser.add_argument('--scale', type=float, default=1.0, help='(optional) factor by which to scale images before display')

parser.add_argument('--camera_id', type=str, default='left', choices=['left', 'right'], help='(optional) Camera ID to display')
parser.add_argument('--masks_id', type=str, default='raw', choices=['raw', 'classified'], help='(optional) Masks type to overlay')

args = parser.parse_args()

image_path = Path(args.dir) / 'stereo'/ args.camera_id / 'rgb'
mask_path = Path(args.dir) / 'stereo' / args.camera_id / args.masks_id

assert image_path.exists(), f'Image path {image_path} does not exist'
assert mask_path.exists(), f'Mask path {mask_path} does not exist'

images = sorted(image_path.glob('*.png'))
masks = sorted(mask_path.glob('*.png'))

model = None
if args.models_dir:
    model = CameraModel(args.models_dir, args.dir)

plt.figure()
for image, mask in tqdm(zip(images, masks)):

    image = load_road_boundary_image(str(image))
    mask = load_road_boundary_image(str(mask))

    image[mask > 0] = [255, 0, 0]

    plt.imshow(image)
    plt.pause(0.01)
