use Tuner;

config var granularity :uint = 1;
config var verbose = 1;

proc main()
{
  var c = -1;
  var x, y, value: real;
  tuningGranularity(granularity);

  do {
    x = tune(-0.25, 1.25, 0.01, .5);
    y = tune(-0.25, 1.25, 0.01, .5);
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

proc calcPerformance(x: real, y: real)
{
  const offset = 0.2;

  return (x-offset)**2 + (y-offset)**2;
}
