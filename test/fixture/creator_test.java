
public class creator_test {
    public creator_test(int x) {
        foo = x;
    }

    public creator_test() {}

    public static int test() {
        creator_test a = new creator_test(456);
        int[] b = new int[10];
        creator_test[] c = new creator_test[10];

        return a.foo;
    }

    public int foo = 123;
}
