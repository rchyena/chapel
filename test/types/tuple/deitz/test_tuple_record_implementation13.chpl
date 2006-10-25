record mytuple {
  var field1 : int;
  var field2 : real;
  def foo(param i : int) var where i == 1 {
    return field1;
  }
  def foo(param i : int) var where i == 2 {
    return field2;
  }
}

var t = mytuple(12, 14.0);

writeln(t);

writeln(t.foo(1));
writeln(t.foo(2));

t.foo(1) = 11;
t.foo(2) = 13.0;

writeln(t);
