# PiSphere: RaspberryPi 5-based time-lapse camera for 360° images

## Software Installation
### 1. Setting up your RaspberryPi 5
```
$ uname -a
Linux raspberrypi 6.6.51+rpt-rpi-2712 #1 SMP PREEMPT Debian 1:6.6.51-1+rpt3 (2024-10-08) aarch64 GNU/Linux
```

The Raspberry Pi 5 can be equipped with an RTC (Real-Time Clock) battery that maintains the time even when the main power is turned off.
In this guide, we will implement intermittent operation using the RTC to power the device only during shooting times,
enabling it to run solely on a small solar panel or battery.
1. **Modify the Configuration File:**

   - Append the following line to `/boot/firmware/config.txt` and then reboot the Raspberry Pi:
     ```
     dtparam=rtc_bbat_vchg=3000000
     ```

   - After rebooting, verify that `/sys/devices/platform/soc/soc\:rpi_rtc/rtc/rtc0/charging_voltage_min` is set to `3000000`.

2. **Edit the EEPROM Configuration:**

   - Run the following command to edit the EEPROM configuration:
     ```bash
     sudo -E rpi-eeprom-config --edit
     ```

   - Ensure that the following settings are present:
     ```
     POWER_OFF_ON_HALT=1
     WAKE_ON_GPIO=0
     ```

### 2. Install PiSphere software
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git
git clone https://github.com/0kam/PiSphere.git
cd PiSphere
chmod +x setup.sh
sudo ./setup.sh
```
