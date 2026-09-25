using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Threading;
using Windows.Foundation;
using Windows.Storage;
using Windows.Storage.Streams;
using Windows.Media.Editing;

/* Saca un fotograma a la resolucion que se pida y, opcionalmente, amplia un recorte.
   Extraer.cs sacaba siempre 848x480 y a ese tamano los futbolistas del video de
   referencia miden diez pixeles: no se puede ver como estan dibujados. */
public static class Zoom {
  static T Wait<T>(IAsyncOperation<T> op){
    var ev=new ManualResetEventSlim(false);
    op.Completed=(o,s)=>ev.Set();
    ev.Wait();
    return op.GetResults();
  }
  [MTAThread]
  public static int Main(string[] a){
    try{
      // video salida.png ms ancho alto [cx cy lado escala]
      string vid=a[0], outPng=a[1];
      int ms=int.Parse(a[2]), W=int.Parse(a[3]), H=int.Parse(a[4]);
      var file=Wait(StorageFile.GetFileFromPathAsync(vid));
      var clip=Wait(MediaClip.CreateFromFileAsync(file));
      var comp=new MediaComposition(); comp.Clips.Add(clip);
      var st=Wait(comp.GetThumbnailAsync(TimeSpan.FromMilliseconds(ms),W,H,VideoFramePrecision.NearestFrame));
      uint size=(uint)st.Size;
      var rd=new DataReader(st.GetInputStreamAt(0));
      Wait(rd.LoadAsync(size));
      byte[] b=new byte[size]; rd.ReadBytes(b);
      using(var msx=new MemoryStream(b))
      using(var img=new Bitmap(msx)){
        Console.WriteLine("fotograma " + img.Width + "x" + img.Height);
        if(a.Length>=8){
          int cx=int.Parse(a[5]), cy=int.Parse(a[6]), lado=int.Parse(a[7]);
          int esc=a.Length>=9?int.Parse(a[8]):4;
          var caja=new Rectangle(cx-lado/2, cy-lado/2, lado, lado);
          using(var dst=new Bitmap(lado*esc,lado*esc,PixelFormat.Format32bppArgb))
          using(var g=Graphics.FromImage(dst)){
            g.InterpolationMode=InterpolationMode.NearestNeighbor;   // sin suavizar: queremos ver el pixel real
            g.PixelOffsetMode=PixelOffsetMode.Half;
            g.DrawImage(img,new Rectangle(0,0,lado*esc,lado*esc),caja,GraphicsUnit.Pixel);
            dst.Save(outPng,ImageFormat.Png);
          }
          Console.WriteLine("recorte " + caja + " x" + esc + " -> " + outPng);
        } else {
          img.Save(outPng,ImageFormat.Png);
          Console.WriteLine("guardado -> " + outPng);
        }
      }
      return 0;
    }catch(Exception e){ Console.WriteLine("FALLO: "+e.Message); return 1; }
  }
}
