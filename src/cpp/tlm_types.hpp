#ifndef _TLMTYPES_H_
#define _TLMTYPES_H_

#include "algo.h"

enum depstate { INIT, REQUESTED, COMPLETE, DONT_CARE };
enum returntype { LOCAL, REMOTE }; //


typedef struct workunit {
  state_t target;
  state_t inital;
  int depth;

  depstate deps[MAX_PRED_STATES];
  state_t predecessors[MAX_PRED_STATES];
  amp_t amplitudes[MAX_PRED_STATES];

  returntype returnloc; // REMOTE means ret to upstream.
  int wu_dest;
  int wu_dst_pred_idx; // position in the predecessors list
} workunit_t;

typedef struct workreturn {
  state_t target;
  amp_t amplitude;

  int wu_dest;
  int wu_dst_pred_idx; // position in the predecessors list
} workreturn_t;

bool can_eval(workunit_t wu);
bool non_default(workunit_t wu);

#endif