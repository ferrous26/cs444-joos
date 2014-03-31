
public class multiarg {
    public multiarg() {}

    public int test() {
        return this.foo(1, 2, 3);
    }

    public int foo(int a, int b, int c) {
        return 123;
    }
}
