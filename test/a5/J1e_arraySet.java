public class J1e_arraySet {
  public J1e_arraySet() {
  }

  public static int test() {
    Object[] objs = new J1e_arraySet[4];
    objs[0] = new String("hi");
    return 123;
  }

  public static void main(String[] args) {
    test();
  }
}

