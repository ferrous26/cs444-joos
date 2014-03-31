public class Main extends A {
  public Main() {
  }

  public int a = 2;

  public static int test() {
    Main m = new Main();
    if (((A)m).a == 1)
      return 123;
    return 22;
  }
}
