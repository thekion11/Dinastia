using System;
using System.IO;
using System.Threading;
using Windows.Foundation;
using Windows.Storage;
using Windows.Storage.Streams;
using Windows.Media.Editing;

public static class VidFrames {
  static T Wait<T>(IAsyncOperation<T> op) {
    var ev = new ManualResetEventSlim(false);
    op.Completed = (o, s) => ev.Set();
    ev.Wait();
    return op.GetResults();
  }

  [MTAThread]
  public static int Main(string[] args) {
    try {
      string path = args[0], outDir = args[1];
      var file = Wait(StorageFile.GetFileFromPathAsync(path));
      var clip = Wait(MediaClip.CreateFromFileAsync(file));
      var comp = new MediaComposition();
      comp.Clips.Add(clip);
      double dur = clip.OriginalDuration.TotalMilliseconds;
      Console.WriteLine("dur_ms=" + (int)dur);
      for (int i = 2; i < args.Length; i++) {
        int ms = int.Parse(args[i]);
        if (ms >= dur) continue;
        var stream = Wait(comp.GetThumbnailAsync(TimeSpan.FromMilliseconds(ms), 848, 480,
                            VideoFramePrecision.NearestFrame));
        uint size = (uint)stream.Size;
        var reader = new DataReader(stream.GetInputStreamAt(0));
        Wait(reader.LoadAsync(size));
        byte[] b = new byte[size];
        reader.ReadBytes(b);
        File.WriteAllBytes(Path.Combine(outDir, "w" + ms.ToString("D5") + ".bin"), b);
        Console.WriteLine(ms + " -> " + b.Length + " bytes magic=" +
          b[0].ToString("X2") + b[1].ToString("X2") + b[2].ToString("X2") + b[3].ToString("X2"));
      }
      return 0;
    } catch (Exception e) { Console.WriteLine("FALLO: " + e.Message); return 1; }
  }
}
