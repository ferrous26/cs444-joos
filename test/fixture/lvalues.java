
public class lvalues {
    public lvalues() {}

    public int test() {
        int x = 5;
        a = 23;
        (a) = 42;
        (((a))) = 69;
        b[1] = 96;
        foo().a = (9);
        return 0;
    }

    public lvalues foo() {
        return null;
    }

    public int a = 0;
    public int[] b = null;
}
