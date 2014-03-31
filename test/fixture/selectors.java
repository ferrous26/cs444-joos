
public class selectors {
    public selectors() {}

    public int test() {
        return this.a.b[5] + c(true).a.d[5].e;
    }

    public selectors a = null;
    public int[] b = new int[10];
    public selectors c(boolean test) {
        return a;
    }
    public selectors[] d = null;
    public int e = 5;
}
