
#include "tlm_types.hpp"
#include "algo.h"


bool can_eval(workunit_t wu) {
  bool can = true;
  for (int i = 0; i < MAX_PRED_STATES; i++) {
    if (wu.deps[i] != COMPLETE && wu.deps[i] != DONT_CARE) {
      can = false;
      break;
    }
  }
  return can;
}

bool non_default(workunit_t wu) {
  bool non_default = false;
  for (int i = 0; i < MAX_PRED_STATES; i++) {
    if (wu.deps[i] > INIT) {
      non_default = true;
      break;
    }
  }
  return non_default;
}
