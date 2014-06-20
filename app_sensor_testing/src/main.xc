#include "../../platform.h"

#define DEBUG_PRINT_ENABLE 1

#include <debug_print.h>
#include <startkit_adc.h>

void logic(lsm303d_client lsm, distance_sensor_client front, distance_sensor_client rear, startkit_adc_if client adc);

int main() {
  interface distance_sensor_i front_distance, rear_distance;
  interface lsm303d_i motion;
  chan adc_chan;
  startkit_adc_if adc_i;

  par {
    on tile[0].core[3] : adc_task(adc_i, adc_chan, 0);
    on tile[0] : logic(motion, front_distance, rear_distance, adc_i);

    startkit_adc(adc_chan);


    //[[combine]]
    par {
      on tile[0].core[2] : lsm303d(motion, motion_sensor);
      on tile[0].core[2] : distance_sensor(front_distance, distance_sensors[0]);
      on tile[0].core[2] : distance_sensor(rear_distance, distance_sensors[1]);
    }
  }

  return 0;
}

void logic(lsm303d_client lsm, distance_sensor_client front, distance_sensor_client rear, startkit_adc_if client adc) {
  timer t; unsigned time;
  vector3d acc, mag;
  unsigned short adc_val[4] = {0, 0, 0, 0};
  unsigned int battery_voltage = 0;

  front.frequency(13);
  rear.frequency(17);


  t :> time;
  time += 500 * XS1_TIMER_KHZ;
  while (1) {
    select {

     case t when timerafter(time) :> void:
//        adc.trigger();
        debug_printf("BATTERY: %dmV\n", battery_voltage);

        lsm.accelerometer_raw(acc);
        debug_printf("ACC_RAW: %d %d %d\n", acc.x, acc.y, acc.z);
        lsm.accelerometer(acc);
        debug_printf("ACC:     %d %d %d\n", acc.x, acc.y, acc.z);

        lsm.magnetometer_raw(mag);
        debug_printf("MAG_RAW: %d %d %d\n", mag.x, mag.y, mag.z);
        lsm.magnetometer(mag);
        debug_printf("MAG:     %d %d %d\n", mag.x, mag.y, mag.z);

        debug_printf("FRONT:   %d\n", front.read());
        debug_printf("REAR:    %d\n\n", rear.read());

        time += 500 * XS1_TIMER_KHZ;
        break;
      case adc.complete():
        adc.read(adc_val);
        battery_voltage = adc_val[3] * 15350 / 65535;
        break;
    }
  }
}
