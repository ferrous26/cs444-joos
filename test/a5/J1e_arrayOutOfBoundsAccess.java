public class J1e_arrayOutOfBoundsAccess {
  public J1e_arrayOutOfBoundsAccess() {
  }

  public static int test() {
    int[] ints = new int[10];
    return ints[11];
  }

}

