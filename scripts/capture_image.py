import os
from camera import DualCamera
import params
import time

if not os.path.exists(params.OUT_DIR):
    os.makedirs(params.OUT_DIR)

cameras = DualCamera()
cameras.capture(params.OUT_DIR)

time.sleep(5)
