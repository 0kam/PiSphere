
# Created by Ryotaro Okamoto on 2024/12/07
# This module defines a camera control class for VirtualNetZeroCamera.
# It is confirmed to work on RaspberryPi 5 (with RaspberryPi OS 64bit debian bookworm).
# Since the camera preview requires a GUI, it only works on the RaspberryPi OS desktop environment.
# For picamera2, see the following documents.
# picamera2: https://datasheets.raspberrypi.com/camera/picamera2-manual.pdf

from picamera2 import Picamera2
from time import sleep
from datetime import datetime

class DualCamera:
    """
    A class for controlling two cameras.
    Attributes:
    -----------
    camera0: picamera2.Picamera2
        The first camera object.
    camera1: picamera2.Picamera2
        The second camera object.
    """
    def __init__(self) -> None:
        """
        Initialize the camera objects.
        """
        self.camera0 = Picamera2(camera_num=0)
        self.config0 = self.camera0.create_still_configuration({"size": (4056, 3040)})
        self.camera1 = Picamera2(camera_num=1)
        self.config1 = self.camera1.create_still_configuration({"size": (4056, 3040)})

    def _capture(self, file0: str, file1: str) -> None:
        """
        Capture images from two cameras.
        Parameters
        ----------
        file0: str
            The file name of the image captured by the first camera.
        file1: str
            The file name of the image captured by the second camera.
        """
        self.camera0.start()
        self.camera1.start()
        sleep(1)
        self.camera0.switch_mode_and_capture_file(self.config0, file0)
        self.camera1.switch_mode_and_capture_file(self.config1, file1)
        self.camera0.stop()
        self.camera1.stop()
        sleep(1)

    def capture(self, out_dir: str) -> None:
        """
        Capture images from two cameras.
        Parameters
        ----------
        out_dir: str
            The directory where the images are saved.
            In out_dir, the images are saved as YYYYMMDD_HHMMSS_camera0.jpg and YYYYMMDD_HHMMSS_camera1.jpg.
        """
        now = datetime.now()
        file0 = f"{out_dir}/{now.strftime('%Y%m%d_%H%M%S')}_camera0.jpg"
        file1 = f"{out_dir}/{now.strftime('%Y%m%d_%H%M%S')}_camera1.jpg"
        self._capture(file0, file1)

    def __del__(self):
        # Close the camera objects when an instance is deleted
        self.camera0.close()
        self.camera1.close()
