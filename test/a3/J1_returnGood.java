abstract public class J1_returnGood {

  public J1_returnGood() {
    return;
  }

  public int test() {
    return 9;
  }

  public Object otherTest() {
    return new Object();
  }

  public char[] lol() {
    return new char[4];
  }

  public boolean lookup() {
    return false;
  }

  public boolean ifs() {
    if (true)
      return false;
    else
      return true;
  }

  public boolean ifs2() {
    if (true)
      return false;
    return true;
  }

  public boolean whiles() {
    while (true)
      return false;
  }

  public int whiles2() {
    while (true) {
      int a = 4;
      return 5;
    }
  }

  public int fors() {
    for (int i = 0; true; i = i + 1)
      return 8;
  }

  public int fors2() {
    for (int i = 0; true; i = i + 1) {
      return 0;
    }
  }

  public void voidTest() {
    return;
  }

  public int manyReturn(int arg) {
    if (false)
      return 4;

    while (true)
      return 32;
  }

  public J1_returnGood self() {
    return this;
  }

  public void implicitVoid() {
  }

  public abstract int abstractMethod();

  public int returnParam(int a) {
    return a;
  }

  public boolean returnLocal()  {
    boolean a = true;
    return a;
  }

  public int field = 4;

  public int returnField() {
    return field;
  }

}
