use Tuner;

config var granularity :uint = 1;
config var verbose = 1;

proc main()
{
  var c = -1;
  var late = 0;
  var x, y, z, value: int;

  tuningGranularity(granularity);

  do {
    x = tune(-25..125 by 3 align 3, 3);
    y = tune(-25..125 by 5 align 5, 5);

    late = late + 1;
    if (late == 5) {
      // This tuning variable doesn't always get set in the loop.
      z = tune(-25..125 by 7 align 7, 7);
      late = 0;
    }

    value = calcPerformance(x, y, z);
    tuningPerformance(value);

    if (verbose) {
      if (c < 0 || c + 1 == granularity)
        then writeln(x, " & ", y, " & ", z, " == ", value);
    }

    if (c + 1 < granularity)
      then c = c + 1;
      else c = 0;
  }
  while (!tuningConverged());

  writeln("Final value: ", x, " & ", y, " & ", z, " == ", value);
}

proc calcPerformance(x: int, y: int, z: int)
{
  const offset = 20;

  return (x-offset)**2 + (y-offset)**2 + (z-offset)**2;
}
