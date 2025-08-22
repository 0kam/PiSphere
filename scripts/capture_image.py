import os
from camera import DualCamera
import params
import time

if not os.path.exists(params.OUT_DIR):
    os.makedirs(params.OUT_DIR)

cameras = DualCamera()
cameras.capture(params.OUT_DIR, params.SAVE_RAW)

time.sleep(5)
