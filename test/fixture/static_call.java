
public class static_call {
    public static_call() {}

    public static int test() {
        return static_call.foo();
    }

    public static int foo() {
        return 123;
    }
}
