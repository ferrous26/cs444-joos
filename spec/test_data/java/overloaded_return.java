
/* iErro - Overloaded method which differs only by return type */
public class Foo {
    public int bar(int x) {
        return x;
    }

    public boolean bar(int x) {
        return x == 1;
    }
}
