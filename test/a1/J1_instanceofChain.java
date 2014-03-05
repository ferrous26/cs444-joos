public class J1_instanceofChain {
  public J1_instanceofChain() {
    String test = "hi";
    boolean value = test instanceof int[] || test instanceof char[];
    boolean other = test instanceof int[] || test instanceof String[];
    boolean third = test instanceof char[] || value == other;
    boolean boom  = test instanceof char[] + "hi";
  }
}

