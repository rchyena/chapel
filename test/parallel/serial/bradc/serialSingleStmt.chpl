use Time;

serial (1==1) do begin foo();
writeln("Second");

def foo() {
  sleep(2);
  writeln("First");
}
