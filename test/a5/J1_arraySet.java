public class J1_arraySet {
  public J1_arraySet() {}

  public static int test() {
    int[] nums = new int[1];
    nums[0] = 4;
    nums[0] = (int)(byte)512;

    String[] strs = new String[5];
    strs[0] = "hi";

    Object[] objs = new Object[42];
    objs[0]       = new int[3];

    ((int[])(objs[0]))[0] = 123;
    return ((int[])(objs[0]))[0];
  }

  public static void main(String[] args) {
    System.out.println(test());
  }

}
