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

module Tuner {

  use Time; // For getCurrentTime().
  use Math; // For isnan() and NAN.

  // Module-level config variables.
  config var tuningEnabled: bool = true;

  // Module-level global variables.
  var globalTask: unmanaged TuningTask;

  // Module-level initialization.
  if (CHPL_TUNER == "none")
    then compilerWarning("Chapel was built without tuning support " +
                         "(CHPL_TUNER=none). No tuning will occur " +
                         "for this binary.");

  if (tuningEnabled) {
    if (chpl_tuner_init())
      then globalTask = new unmanaged TuningTask();
      else tuningEnabled = false;
  }

  

  // Chapel user tuner interface.
  proc enableTuner() {
    if (!tuningEnabled && chpl_tuner_init()) {
      globalTask = new unmanaged TuningTask();
      tuningEnabled = true;
    }
  }

  proc disableTuner() {
    if (tuningEnabled)
      then chpl_tuner_fini;

    tuningEnabled = false;
  }

  proc tune(minVal: real, maxVal: real, stepVal: real, initVal: real,
            task = globalTask)
  {
    var callerFile = __primitive("_get_user_file");
    var callerLine = __primitive("_get_user_line"): string;
    var callerID = callerFile + ":" + callerLine;

    return if (tuningEnabled)
      then task.getValue(callerID, minVal, maxVal, stepVal, initVal)
      else initVal;
  }

  proc tune(r: range(?), initVal: real, task = globalTask): int
  {
    assert(r.boundedType == BoundedRangeType.bounded);

    var callerFile = __primitive("_get_user_file");
    var callerLine = __primitive("_get_user_line"): string;
    var callerID = callerFile + ":" + callerLine;

    var minVal: real = min(r.first, r.last);
    var maxVal: real = max(r.first, r.last);
    var stepVal: real = abs(r.stride);

    return if (tuningEnabled)
      then task.getValue(callerID, minVal, maxVal, stepVal, initVal): int
      else initVal: int;
  }

  proc tuningGranularity(iterations: uint, task = globalTask) {
    if (tuningEnabled)
      then task.setGranularity(iterations);
  }

  proc tuningPerformance(value: real, task = globalTask) {
    if (tuningEnabled)
      then task.setPerformance(value);
  }

  proc tuningConverged(task = globalTask) {
    return !tuningEnabled || task.converged;
  }

  // Representation of independent tuning tasks.
  class TuningTask {

    var taskID: c_void_ptr;
    var functional: bool;
    var firstName: string;
    var varsByName: domain(string);
    var bestVal: [varsByName] real;
    var currVal: [varsByName] bool;
    var iterLimit: uint = 1;

    var iterCount: uint = 0;
    var timestamp: real = NAN;
    var converged: bool = false;
    var performance: real = NAN;

    proc init()
    {
      var empty: c_void_ptr;
      taskID = empty;
      functional = chpl_tuner_task_new(taskID);
    }

    proc ~TuningTask()
    {
      if (!functional)
        then return;

      if (!chpl_tuner_task_delete(taskID))
        then __primitive("chpl_warning", c"Error deleting tuner task");
    }

    proc getValue(name: string, minVal: real, maxVal: real,
                  stepVal: real, initVal: real)
    {
      if (!functional) {
        // Tuner or tuning task is non-functional.  Return quickly.
        return initVal;
      }
      else if (!varsByName.contains(name)) {
        // We've never seen this tuning variable before. Add it to our list.
        addNewVar(name, minVal, maxVal, stepVal, initVal);
      }
      else if (!tuningEnabled || converged) {
        // Do not invoke the tuner for these cases.
        return bestVal[name];
      }
      else if (firstName == name) {
        // Requesting the first variable again indicates a loop head.
        handleLoopHead;
      }

      currVal[name] = true;

      return if (timerStarted)
        then chpl_tuner_task_get(taskID, name.c_str())
        else bestVal[name];
    }

    proc setGranularity(iterations: uint) {
      iterLimit = iterations;
    }

    proc setPerformance(value: real) {
      performance = value;
    }

    proc isConverged() {
      return (!functional || converged);
    }

    proc handleLoopHead {
      if (!timerStarted) {
        // Task setup is complete. Begin a new tuning session.
        if (!chpl_tuner_task_start(taskID)) {
          __primitive("chpl_warning", c"Error starting tuner task");
          functional = false;
          return;
        }
        startTimer;
      }
      else if (iterCount >= iterLimit) {
        // Tuning granularity reached.  This was actually the loop tail.
        handleLoopTail;
      }
      iterCount += 1;
    }

    // Enough iterations have passed.  Report elapsed time to the tuner.
    proc handleLoopTail {
      var value: real;

      if (isnan(performance)) {
        value = getCurrentTime(TimeUnits.microseconds) - timestamp;
      }
      else {
        value = performance;
        performance = NAN;
      }

      // Make sure all tuning variables were requested in this tuning loop.
      var valid = true;
      for i in currVal do
        valid &= i;

      if (!valid || chpl_tuner_task_loop(taskID, value)) {
        // Either not all variables were used, or the search task
        // has new parameters for testing.  Reset the loop state.
        currVal = false;
        startTimer;
      }
      else {
        // Tuning session converged.  Store the best values and stop tuning.
        converged = true;
        for name in varsByName {
          bestVal[name] = chpl_tuner_task_get(taskID, name.c_str());
        }

        if (!chpl_tuner_task_stop(taskID)) {
          __primitive("chpl_warning", c"Error stopping tuner task");
          functional = false;
          return;
        }

        stopTimer;
      }
    }

    proc addNewVar(name, minVal, maxVal, stepVal, initVal) {
      if (timerStarted) {
        // We are adding a tuning variable in the middle of timing
        // the loop. Stop the session before we add a new variable.
        if (!chpl_tuner_task_stop(taskID)) {
          __primitive("chpl_warning", c"Error stopping tuner task");
          functional = false;
          return;
        }
        stopTimer;
      }
      converged = false;

      varsByName.add(name);
      bestVal[name] = initVal;
      if (varsByName.size == 1)
        then firstName = name;

      if (!chpl_tuner_task_var(taskID, name.c_str(),
                               minVal, maxVal, stepVal)) {
        __primitive("chpl_warning", c"Error defining tuner variable");
        functional = false;
      }
    }

    proc startTimer {
      iterCount = 0;
      timestamp = getCurrentTime(TimeUnits.microseconds);
    }

    proc stopTimer {
      iterCount = 0;
      timestamp = NAN;
    }

    proc timerStarted {
      return !isnan(timestamp);
    }
  }

  // Chapel runtime third-party tuner interface.
  extern proc chpl_tuner_init(): bool;
  extern proc chpl_tuner_fini(): bool;
  extern proc chpl_tuner_task_new(ref taskID: c_void_ptr): bool;
  extern proc chpl_tuner_task_delete(taskID: c_void_ptr): bool;
  extern proc chpl_tuner_task_var(taskID: c_void_ptr, name: c_string,
                                  minVal: real, maxVal: real,
                                  stepVal: real): bool;
  extern proc chpl_tuner_task_get(taskID: c_void_ptr, name: c_string): real;
  extern proc chpl_tuner_task_start(taskID: c_void_ptr): bool;
  extern proc chpl_tuner_task_stop(taskID: c_void_ptr): bool;
  extern proc chpl_tuner_task_loop(taskID: c_void_ptr,
                                   performance: real): bool;
}
