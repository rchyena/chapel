type mytup = (int, real);

def returntwo(): mytup {
  return (1, 2.3);
}

var x: int;
var y: real;

var t: mytup;

t = returntwo();

writeln("t is: ", t);
