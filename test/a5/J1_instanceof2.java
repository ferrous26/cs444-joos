public class J1_instanceof2 {
  public J1_instanceof2(){
  }

  public static int test() {
    String t = "test";

    if (t instanceof Object)
      return 123;
    return 22;
  }
}

