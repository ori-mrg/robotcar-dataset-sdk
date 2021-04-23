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
import cv2
from pathlib import Path
from tqdm import tqdm
import numpy as np

from datetime import datetime as dt
from road_boundary import load_road_boundary_image, load_road_boundary_mask


YELLOW = (255, 255, 0)
CYAN = (0, 255, 255)
RED = (255, 0, 0)


parser = argparse.ArgumentParser(description='Play back images from a given directory')

parser.add_argument('trial', type=str, help='Directory containing images.')
parser.add_argument('--camera_id', type=str, default='left', choices=['left', 'right'], help='(optional) Camera ID to display')
parser.add_argument('--type', type=str, default='uncurated', choices=['uncurated', 'curated'], help='(optional) Curated vs uncurated')
parser.add_argument('--masks_id', type=str, default='mask', choices=['mask', 'mask_classified'], help='(optional) Masks type to overlay')

parser.add_argument('--save_video',  action='store_true', help='Flag for saving a video')
parser.add_argument('--save_dir',  type=str, help='Where to save the images')

args = parser.parse_args()

image_path = Path(args.trial) / args.type / args.camera_id / 'rgb'
mask_path = Path(args.trial) / args.type / args.camera_id / args.masks_id

assert image_path.exists(), f'Image path {image_path} does not exist'
assert mask_path.exists(), f'Mask path {mask_path} does not exist'

images = sorted(image_path.glob('*.png'))
masks = sorted(mask_path.glob('*.png'))

fname = f"{args.trial}_{args.camera_id}_{args.type}_{args.masks_id}"

initialised = False
for image, mask in tqdm(zip(images, masks)):
    image = load_road_boundary_image(str(image))
    mask = load_road_boundary_image(str(mask))

    kernel = np.ones((5, 5), 'uint8')
    mask = cv2.dilate(mask, kernel, iterations=1)

    if args.masks_id == 'mask':
        image[mask > 0] = YELLOW
    else:
        image[mask == 1] = CYAN
        image[mask == 2] = RED

    image_ = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
    cv2.imshow('Video', image_)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    if args.save_video:
        if not initialised:
            framesize = (image.shape[1], image.shape[0])
            out = cv2.VideoWriter(str(Path(args.save_dir) / f'{fname}.avi'), \
                                  cv2.VideoWriter_fourcc(*'MPEG'),
                                  20, framesize, True)
            initialised = True

            cv2.imwrite(str(Path(args.save_dir) / f'{fname}.jpg'), image_)

        out.write(image_)

out.release()
