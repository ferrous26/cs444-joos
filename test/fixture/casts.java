
public class casts {
    public casts() {}

    public int test() {
        Object a = (Object)this;
        casts b = (casts)a;
        int x = 123;
        short y = (short)x;
        return (int)y;
    }
}
