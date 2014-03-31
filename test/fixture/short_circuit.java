
public class short_circuit {
    public short_circuit() {}
    public boolean main() {
        int x = 9;
        return (x == 2) || (x != 4) && (x >= 9);
    }
}
