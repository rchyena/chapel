class R {
  var x: int;
  var y: real;
}

def foo() {
  var x: int = 1;
  var y: real = 2.3;

  var r = R(x = x, y = y);

  writeln("r is: ", r);
}

def bar() {
  var x: real = 4.5;
  var y: int = 6;

  var r = R(x = y, y = x);

  writeln("r is: ", r);
}

def main() {
  foo();
  bar();
}
