#!/bin/bash
# Calibration script is done by ## Substring & psakhis/sergi ## and all credit's goes to them! 
# This has only been slightly modified to work with Batocera using a GunCon2.

calibration_and_setup() {
  calibration_output="$(/usr/bin/switchres 320 240 60 -s -l "python /usr/bin/calibrate.py -r 320x240" 2>&1)"
  calibration_data="$(echo $calibration_output | grep "guncon2-calibration:Calibration" |tail -1)"
  x_min=$(get_calibration_value "$calibration_data" x min)
  x_max=$(get_calibration_value "$calibration_data" x max)
  x_fuzz=$(get_calibration_value "$calibration_data" x fuzz)
  y_min=$(get_calibration_value "$calibration_data" y min)
  y_max=$(get_calibration_value "$calibration_data" y max)
  y_fuzz=$(get_calibration_value "$calibration_data" y fuzz)
  echo "SUBSYSTEM==\"input\", ACTION==\"add\", KERNEL==\"event*\", ATTRS{idVendor}==\"0b9a\", ATTRS{idProduct}==\"016a\", MODE=\"0666\", ENV{ID_INPUT_JOYSTICK}=\"0\", ENV{ID_INPUT_GUN}=\"0\", ENV{ID_INPUT_MOUSE}=\"0\", RUN+=\"/usr/bin/guncon-add\", RUN+=\"/bin/bash -c 'evdev-joystick --e %E{DEVNAME} -a 0 -f 0 -m -32768 -M 32767 ; evdev-joystick --e %E{DEVNAME} -a 1 -f 0 -m -32768 -M 32767 ; evdev-joystick --e %E{DEVNAME} -a 3 -f $x_fuzz -m $x_min -M $x_max ; evdev-joystick --e %E{DEVNAME} -a 4 -f $y_fuzz -m $y_min -M $y_max'\"" | tee /etc/udev/rules.d/99-guncon.rules
  echo >> /etc/udev/rules.d/99-guncon.rules "SUBSYSTEM==\"input\", ACTION==\"add\", KERNEL==\"event*\", ATTRS{name}==\"GunCon2-Gun\", MODE=\"0666\", ENV{ID_INPUT_GUN}=\"1\", ENV{ID_INPUT_JOYSTICK}=\"0\", ENV{ID_INPUT_MOUSE}=\"1\""
  udevadm control --reload-rules && udevadm trigger
}

get_calibration_value() {
  local calibration_text="$1"
  local axis="$2"
  local param="$3"

  # The line should look like "INFO:guncon2-calibration:Calibration: x=(val 280, min 169, max 745, fuzz 5, flat 0, res 0) y=(val 185, min 31, max 263, fuzz 5, flat 0, res 0)"
  if [[ $axis == x ]] ; then
    echo "$calibration_text" | cut -d '=' -f2 | egrep -o "$param [0-9]+" | sed "s/$param //"
  elif [[ $axis == y ]] ; then
    echo "$calibration_text" | cut -d '=' -f3 | egrep -o "$param [0-9]+" | sed "s/$param //"
  else
    return 1
  fi
  return 0
}

calibration_and_setup

batocera-save-overlay
