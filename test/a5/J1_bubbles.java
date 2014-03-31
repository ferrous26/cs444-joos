public class J1_bubbles {
  public J1_bubbles() {
  }

  public int sort() {
    int[] nums = new int[123];
    for (int i = 0; i < 123; i = i + 1)
      nums[i] = 123 - i;

    for (int i = 0; i < 123; i = i + 1) {
      for (int j = 1; j < 123; j = j + 1) {
        if (nums[j - 1] > nums[j]) {
          int t = nums[j-1];
          nums[j-1] = nums[i];
          nums[i]   = t;
        }
      }
    }

    return nums[122];
  }

  public static int test() {
    J1_bubbles bubble = new J1_bubbles();
    return bubble.sort();
  }

  public static void main(String[] args) {
    J1_bubbles bubble = new J1_bubbles();
    System.out.println(bubble.sort());
  }
}
