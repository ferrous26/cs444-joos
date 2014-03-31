public class J1_overflow {
  public J1_overflow() {
  }

  public static int test() {
    byte test = (byte)100;
    for (int i = 0; i < 28; i = i + 1)
      test = (byte)(test + 1);

    if (test == 0)
      return 123;
    return 22;
  }
}

