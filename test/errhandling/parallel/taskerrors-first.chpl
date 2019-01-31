module ReThrown {
class UserError: Error {
  var x: int;
  proc init(x: int) { this.x = x; }
  proc deinit() { writeln("UserError.deinit(", this.x, ")"); }
}
proc main() {
  try {
    try {
      forall i in 0..3 {
        var ex = new owned UserError(i);
        throw ex;
      }
    }
    catch errors: TaskErrors {
      writeln("Caught some TaskErrors");
      throw errors.first();
    }
  }
  catch e {
    writeln("Outer catch");
  }
  writeln("End of main");
}
} // module ReThrown
