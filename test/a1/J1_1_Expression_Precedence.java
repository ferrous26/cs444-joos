public class J1_1_Expression_Precedence {
  public J1_1_Expression_Precedence() {}

  public static int test() {
    boolean a = (1 + 2) * 3 + 4 - 5 % 6 * 7 + 8 * 9 == -50 || false && true;
  }
}
