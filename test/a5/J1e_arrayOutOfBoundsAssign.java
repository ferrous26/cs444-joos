public class J1e_arrayOutOfBoundsAssign {
  public J1e_arrayOutOfBoundsAssign() {
  }

  public static int test() {
    short[] shorts = new short[5];
    shorts[5] = (short)4;
    return 123;
  }
  
}
