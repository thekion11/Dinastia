using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

/* Recorta una caja de un fotograma de la cinematica de marca y la escala a los tamanos de
   icono que pide Android. Por defecto coge el cuadrado central; con cx cy lado se puede
   apuntar a una zona concreta (el monograma ND, que a 48 px es lo unico que se lee). */
class Icono {
  static void Main(string[] a) {
    if (a.Length < 2) { Console.WriteLine("uso: Icono.exe <origen.jpg> <destino> [cx cy lado]"); return; }
    using (var src = new Bitmap(a[0])) {
      Rectangle caja;
      if (a.Length >= 5) {
        int cx = int.Parse(a[2]), cy = int.Parse(a[3]), l = int.Parse(a[4]);
        caja = new Rectangle(cx - l / 2, cy - l / 2, l, l);
      } else {
        int l = Math.Min(src.Width, src.Height);
        caja = new Rectangle((src.Width - l) / 2, (src.Height - l) / 2, l, l);
      }
      int[] tam = { 48, 72, 96, 144, 192 };
      string[] dpi = { "mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi" };
      for (int i = 0; i < tam.Length; i++) {
        using (var dst = new Bitmap(tam[i], tam[i], PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(dst)) {
          g.InterpolationMode = InterpolationMode.HighQualityBicubic;
          g.PixelOffsetMode = PixelOffsetMode.HighQuality;
          g.SmoothingMode = SmoothingMode.HighQuality;
          g.DrawImage(src, new Rectangle(0, 0, tam[i], tam[i]), caja, GraphicsUnit.Pixel);
          string carpeta = System.IO.Path.Combine(a[1], "mipmap-" + dpi[i]);
          System.IO.Directory.CreateDirectory(carpeta);
          dst.Save(System.IO.Path.Combine(carpeta, "ic_launcher.png"), ImageFormat.Png);
        }
      }
      Console.WriteLine("iconos generados desde " + caja.ToString());
    }
  }
}
