/*
 * Copyright 2004-2016 Cray Inc.
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "chplrt.h"
#include "chpltypes.h"
#include "chpl-mem.h"
#include "hclient.h"

#include <stdlib.h>
#include <sys/param.h>

static hdesc_t* hdesc;

typedef struct TaskState {
  hdef_t*  hdef;
  htask_t* htask;
} TaskState_t;

chpl_bool chpl_tuner_init(void) {
  if (getenv("HARMONY_HOME") == NULL) {
    char pathbuf[ MAXPATHLEN ];
    strncpy(pathbuf, getenv("CHPL_HOME"), sizeof(pathbuf) - 35);
    strcat(pathbuf, "/./third-party/activeharmony/install");
    setenv("HARMONY_HOME", pathbuf, 1);
  }

  hdesc = ah_alloc();
  if (!hdesc)
    return false;

  if (ah_connect(hdesc, NULL, 0) != 0) {
    ah_free(hdesc);
    return false;
  }

  return true;
}

chpl_bool chpl_tuner_fini(void) {
  ah_free(hdesc);
  return true;
}

chpl_bool chpl_tuner_task_new(void** taskID) {
  TaskState_t* state = chpl_malloc( sizeof(TaskState_t) );
  if (!state)
    return false;
  
  state->hdef = ah_def_alloc();
  if (!state->hdef) {
    chpl_free(state);
    return false;
  }

  state->htask = NULL;
  *taskID = state;
  return true;
}

chpl_bool chpl_tuner_task_delete(void* taskID) {
  hdef_t*  hdef  = ((TaskState_t*)taskID)->hdef;
  htask_t* htask = ((TaskState_t*)taskID)->htask;

  ah_kill(htask);
  ah_def_free(hdef);
  return true;
}

chpl_bool chpl_tuner_task_var(void* taskID, c_string name,
                              _real64 min, _real64 max, _real64 step) {
  hdef_t* hdef = ((TaskState_t*)taskID)->hdef;
  return (ah_def_real(hdef, name, min, max, step, NULL) == 0);
}

_real64 chpl_tuner_task_get(void* taskID, c_string name) {
  htask_t* htask = ((TaskState_t*)taskID)->htask;
  return ah_get_real(htask, name);
}

chpl_bool chpl_tuner_task_start(void* taskID) {
  hdef_t*  hdef  = ((TaskState_t*)taskID)->hdef;
  htask_t* htask = ah_start(hdesc, hdef);

  if (!htask)
    return false;

  while (ah_fetch(htask) != 1);

  ((TaskState_t*)taskID)->htask = htask;
  return true;
}

chpl_bool chpl_tuner_task_stop(void* taskID) {
  htask_t* htask = ((TaskState_t*)taskID)->htask;
  ah_kill(htask);
  return true;
}

chpl_bool chpl_tuner_task_loop(void* taskID, _real64 performance) {
  htask_t* htask = ((TaskState_t*)taskID)->htask;
  ah_report(htask, &performance);
  ah_fetch(htask);

  if (ah_converged(htask) == 1) {
    ah_best(htask);
    return false;
  }
  return true;
}
