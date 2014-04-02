
public class string_cats {
    public string_cats() {}
    public void test() {
        String cats = "Chen, Orin, " + this.actually_a_tiger() + unrelated + this;
    }

    public String unrelated = "Sakamoto, ";

    public String actually_a_tiger() {
        return "Shou, ";
    }

    public String toString() {
        return " others";
    }
}
