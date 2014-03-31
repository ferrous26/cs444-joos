public class J1e_badArraySize {
  public J1e_badArraySize() {
  }

  public static int test() {
    String[] strs = new String[10 - 11];
    strs[0] = "hi";
    return 123;
  }
}
