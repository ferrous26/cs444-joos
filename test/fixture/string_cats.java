
public class string_cats {
    public string_cats() {}
    public void test() {
        String cats = "Chen, Orin, " +
            this.actually_a_tiger() +
            unrelated +
            //4 +
            this +
            //'s' +
            ""
            ;
    }

    public String unrelated = "Sakamoto, ";
    public String dont_fold = "";

    public String actually_a_tiger() {
        return "Shou, ";
    }

    public String toString() {
        return " other";
    }
}
