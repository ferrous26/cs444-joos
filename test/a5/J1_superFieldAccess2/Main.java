public class Main extends A {
  public Main() {
  }

  public int test2() {
    return ((A)this).a;
  }

  public int a = 22;

  public static int test() {
    return (new Main()).test2();
  }
}
