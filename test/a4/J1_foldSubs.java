public class J1_foldSubs {
  public J1_foldSubs() {
  }

  public boolean a = true && false;
  public boolean b = true || false;
  public boolean c = false && true;
  public boolean d = c && false;
  public boolean e = true && d;
  public boolean f = false && false;
  public boolean g = true | false;
  public boolean h = true | e;
  public boolean i = a & true;


}

