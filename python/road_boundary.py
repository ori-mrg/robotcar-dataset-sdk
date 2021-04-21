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

import numpy as np
from PIL import Image


def load_road_boundary_image(image_path):
    img = Image.open(image_path)
    return np.array(img).astype(np.uint8)


def load_road_boundary_mask(mask_path, model):
    return load_road_boundary_image(mask_path)
