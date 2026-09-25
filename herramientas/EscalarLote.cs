using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

/* Reescala en lote conservando la transparencia. Las equipaciones vienen a 420x420
   con canal alfa; en el juego se ven a ~110 px, asi que 420 es diez veces mas
   pixeles de los que hacen falta y 167 MB no caben en un APK. A 200x200 se ven
   igual de bien y el pack entero baja a una fraccion.
   PNG y no JPEG a proposito: el JPEG NO tiene canal alfa y las camisetas
   quedarian con un cuadrado blanco de fondo. */
class EscalarLote {
  static void Main(string[] a){
    if(a.Length<3){ Console.WriteLine("uso: EscalarLote.exe origen destino lado"); return; }
    int L=int.Parse(a[2]);
    Directory.CreateDirectory(a[1]);
    int n=0; long antes=0, despues=0;
    foreach(var f in Directory.GetFiles(a[0],"*.png")){
      try{
        var fi=new FileInfo(f); antes+=fi.Length;
        using(var src=new Bitmap(f)){
          int w=src.Width, h=src.Height;
          double k=(double)L/Math.Max(w,h);
          if(k>1)k=1;                                  // nunca AGRANDAR: solo empeoraria
          int nw=Math.Max(1,(int)Math.Round(w*k)), nh=Math.Max(1,(int)Math.Round(h*k));
          using(var dst=new Bitmap(nw,nh,PixelFormat.Format32bppArgb))
          using(var g=Graphics.FromImage(dst)){
            g.Clear(Color.Transparent);
            g.InterpolationMode=InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode=PixelOffsetMode.HighQuality;
            g.SmoothingMode=SmoothingMode.HighQuality;
            g.CompositingQuality=CompositingQuality.HighQuality;
            g.DrawImage(src,new Rectangle(0,0,nw,nh),new Rectangle(0,0,w,h),GraphicsUnit.Pixel);
            string sal=Path.Combine(a[1],Path.GetFileName(f));
            dst.Save(sal,ImageFormat.Png);
            despues+=new FileInfo(sal).Length;
          }
        }
        n++;
      }catch(Exception e){ Console.WriteLine("fallo " + Path.GetFileName(f) + ": " + e.Message); }
    }
    Console.WriteLine(n + " imagenes  " + (antes/1048576) + " MB -> " + (despues/1048576) + " MB");
  }
}
