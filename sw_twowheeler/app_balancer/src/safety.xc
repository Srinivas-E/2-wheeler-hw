#include "safety.h"

#define DEBUG_PRINT_ENABLE 0
#include <debug_print.h>

port out leds = XS1_PORT_32A;

[[combinable]]
void balancer_safety(balancer_client balancer,
                     distance_sensor_client front,
                     distance_sensor_client rear,
                     startkit_adc_if client adc,
                     motors_status_client motors_status,
                     interface balancer_sensors_i server sensors) {
  unsigned battery = 0;
  unsigned current[2] = { 0, 0 };

  while (1) {
    select {
      case motors_status.changed():
        int l, r;
        { l, r } = motors_status.get();
        break;

      case balancer.next():
        int angle = balancer.get_angle();

        if (angle > 43000 || angle < -43000)
          balancer.stop(-1);
        else
          balancer.balance(-1);

        break;

      case adc.complete():
        unsigned short adc_val[4] = { 0, 0, 0, 0 };

        adc.read(adc_val);
        battery = adc_val[3] * 15350 / 65535;
        current[0] = adc_val[0] * 6255 / 65535;
        current[1] = adc_val[1] * 6255 / 65535;

        if (battery > 11800)
          leds <: ~(1<<7);
        else
          leds <: ~0;

        //if (current[0] > 5000 || current[1] > 5000)
        //  balancer.stop();

//        debug_printf("%dmV %dmA %dmA\n", battery, current[0], current[1]);
        break;

      case sensors.battery_voltage() -> unsigned voltage:
        voltage = battery;
        break;

      case sensors.motors_current() -> { unsigned left, unsigned right }:
        left = current[0];
        right = current[1];
        break;

    }
  }
}
