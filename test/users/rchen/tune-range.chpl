use Tuner;

config var granularity :uint = 1;
config var verbose = 1;

proc main()
{
  var c = -1;
  var x, y, value: int;
  tuningGranularity(granularity);

  do {
    x = tune(-25..125 by 3 align 3, 3);
    y = tune(-25..125 by 5 align 5, 5);
    value = calcPerformance(x, y);

    tuningPerformance(value);

    if (verbose) {
      if (c < 0 || c + 1 == granularity)
        then writeln(x, " & ", y, " == ", value);
    }

    if (c + 1 < granularity)
      then c = c + 1;
      else c = 0;
  }
  while (!tuningConverged());

  writeln("Final value: ", x, " & ", y, " == ", value);
}

proc calcPerformance(x: int, y: int)
{
  const offset = 20;

  return (x-offset)**2 + (y-offset)**2;
}

