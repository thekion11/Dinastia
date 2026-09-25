using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

/* Arranca DINASTIA: el proyecto de Godot, con su motor portable. Se compila
   con /target:winexe para que NO aparezca la ventana negra de consola.

   REESCRITO el 14-9-2026: hasta esa fecha abria "dinastia-futbol-manager
   base.html" en el navegador -el juego VIEJO-. El motor activo es Godot desde
   el 2-9-2026 (ver dinastia-godot/LEEME.md), pero este lanzador y "JUGAR
   DINASTIA (nube).bat" siguieron apuntando al HTML durante semanas sin que
   nada avisara: se detecto al preparar el archivado del HTML original.

   Se abre el PROYECTO fuente directo (--path), no un .exe ya exportado a
   entregas\: asi el iconito de la raiz siempre juega la version mas
   reciente del codigo, sin depender de acordarse de recompilar cada vez. */
static class Lanzador {
  [STAThread]
  static void Main(){
    try{
      // El .exe vive en "Proyecto x\"; el proyecto y el motor, a su lado.
      string raiz = AppDomain.CurrentDomain.BaseDirectory;
      string proyecto = Buscar(raiz, "dinastia-godot", esCarpeta: true);
      string godot = Buscar(raiz, Path.Combine("herramientas", "godot", "Godot_v4.7.2-stable_win64.exe"), esCarpeta: false);

      if (proyecto == null || godot == null){
        MessageBox.Show("No encuentro el proyecto de Godot o su motor portable.\n\n" +
          "Se esperaba junto a este lanzador:\n" +
          "  dinastia-godot\\\n" +
          "  herramientas\\godot\\Godot_v4.7.2-stable_win64.exe",
          "DINASTIA", MessageBoxButtons.OK, MessageBoxIcon.Error);
        return;
      }

      var psi = new ProcessStartInfo(godot);
      psi.Arguments = "--path \"" + proyecto + "\"";
      psi.UseShellExecute = false;
      Process.Start(psi);
    }catch(Exception e){
      MessageBox.Show("No se pudo abrir el juego:\n\n" + e.Message, "DINASTIA",
        MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
  }

  // Busca `relativo` junto al lanzador y, si no esta, un nivel arriba -por si
  // alguien lo mueve a herramientas\, como ya pasaba con el lanzador viejo.
  static string Buscar(string raiz, string relativo, bool esCarpeta){
    string a = Path.Combine(raiz, relativo);
    if (esCarpeta ? Directory.Exists(a) : File.Exists(a)) return a;
    string arriba = Directory.GetParent(raiz.TrimEnd(Path.DirectorySeparatorChar)).FullName;
    string b = Path.Combine(arriba, relativo);
    if (esCarpeta ? Directory.Exists(b) : File.Exists(b)) return b;
    return null;
  }
}
