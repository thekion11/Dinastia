using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

/* Reescala una imagen a un tamano exacto con remuestreo de calidad y la guarda como
   JPEG con la calidad que se pida. Se usa para dejar la textura de la Tierra en
   4096x2048: es el mayor tamano que TODAS las GPU de movil garantizan (muchas topan
   en 4096), asi que subir de ahi se veria en el PC y fallaria en el Android. */
class Escalar {
  static ImageCodecInfo Codec(string mime){
    foreach(var c in ImageCodecInfo.GetImageEncoders()) if(c.MimeType==mime) return c;
    return null;
  }
  static void Main(string[] a){
    if(a.Length<4){ Console.WriteLine("uso: Escalar.exe origen destino ancho alto [calidad]"); return; }
    int W=int.Parse(a[2]), H=int.Parse(a[3]);
    long q=a.Length>=5?long.Parse(a[4]):92;
    using(var src=new Bitmap(a[0]))
    using(var dst=new Bitmap(W,H,PixelFormat.Format24bppRgb))
    using(var g=Graphics.FromImage(dst)){
      g.InterpolationMode=InterpolationMode.HighQualityBicubic;
      g.PixelOffsetMode=PixelOffsetMode.HighQuality;
      g.SmoothingMode=SmoothingMode.HighQuality;
      g.CompositingQuality=CompositingQuality.HighQuality;
      g.DrawImage(src,new Rectangle(0,0,W,H),new Rectangle(0,0,src.Width,src.Height),GraphicsUnit.Pixel);
      var ep=new EncoderParameters(1);
      ep.Param[0]=new EncoderParameter(System.Drawing.Imaging.Encoder.Quality,q);
      dst.Save(a[1],Codec("image/jpeg"),ep);
      Console.WriteLine(src.Width+"x"+src.Height+" -> "+W+"x"+H+"  calidad "+q);
    }
  }
}
