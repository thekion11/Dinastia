// Prueba de humo del export Web (5-11-2026): sirve la carpeta exportada, la abre en Chromium y espera la señal
// «DINASTIA_MENU_LISTO» (ui/principal.gd, solo en Web y Android). Falla si hay errores de consola o de página.
//   node humo_web.mjs <carpeta_del_export> <captura.jpg>
// Entorno: CHROME_PATH (ejecutable; si falta, usa el Chrome del sistema con channel «chrome»), ESPERA_S (por defecto 240),
//          RUIDO_OK (regex de mensajes de error tolerados, además de favicon).
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright-core";

const [carpeta, captura] = process.argv.slice(2);
if (!carpeta || !captura) { console.error("uso: humo_web.mjs <carpeta> <captura.jpg>"); process.exit(2); }
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream",
  ".png": "image/png", ".json": "application/json", ".css": "text/css", ".svg": "image/svg+xml", ".ico": "image/x-icon" };
const raiz = path.resolve(carpeta);
const servidor = http.createServer((req, res) => {
  let ruta = decodeURIComponent(new URL(req.url, "http://x").pathname);
  if (ruta.endsWith("/")) ruta += "index.html";
  const archivo = path.join(raiz, ruta);
  if (!archivo.startsWith(raiz + path.sep) || !fs.existsSync(archivo) || fs.statSync(archivo).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "Content-Type": MIME[path.extname(archivo)] || "application/octet-stream",
    "Cross-Origin-Opener-Policy": "same-origin", "Cross-Origin-Embedder-Policy": "require-corp" });
  fs.createReadStream(archivo).pipe(res);
});
await new Promise((r) => servidor.listen(0, "127.0.0.1", r));
const puerto = servidor.address().port;

const opciones = { headless: true, args: ["--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] };
if (process.env.CHROME_PATH) opciones.executablePath = process.env.CHROME_PATH; else opciones.channel = "chrome";
const navegador = await chromium.launch(opciones);
const pagina = await navegador.newPage({ viewport: { width: 1280, height: 720 } });
// Ruido CONOCIDO del export Web (5-11): no hay extensión C++ para web.wasm32 (el juego usa el respaldo GDScript) y el motor avisa
// del recorte de oclusión. Cualquier otro error SÍ falla.
const CONOCIDO = "No GDExtension library found|GDExtension dynamic library not found|Error loading extension|Occlusion culling is disabled|at: (parse_gdextension_file|open_library|load_extensions|_print_warning)";
const tolerado = new RegExp("favicon|" + CONOCIDO + (process.env.RUIDO_OK ? "|" + process.env.RUIDO_OK : ""), "i");
const errores = [];
let listo = false;
pagina.on("console", (m) => {
  const t = m.text();
  if (t.includes("DINASTIA_MENU_LISTO")) listo = true;
  if ((m.type() === "error" || /SCRIPT ERROR|SHADER ERROR/.test(t)) && !tolerado.test(t + (m.location().url || ""))) errores.push(`[${m.type()}] ${t}`);
});
pagina.on("pageerror", (e) => errores.push(`[pageerror] ${e.message}`));
pagina.on("requestfailed", (r) => { if (!tolerado.test(r.url())) errores.push(`[requestfailed] ${r.url()}`); });

const limite = Date.now() + (Number(process.env.ESPERA_S) || 240) * 1000;
await pagina.goto(`http://127.0.0.1:${puerto}/index.html`);
while (!listo && Date.now() < limite) await pagina.waitForTimeout(1000);
if (listo) await pagina.waitForTimeout(5000);   // unos segundos más: los errores del menú suelen salir justo después
fs.mkdirSync(path.dirname(path.resolve(captura)), { recursive: true });
await pagina.screenshot({ path: captura, type: "jpeg", quality: 80 });
await navegador.close();
servidor.close();

if (!listo) console.log("FALLO: no apareció «DINASTIA_MENU_LISTO» antes del límite.");
for (const e of errores.slice(0, 20)) console.log("FALLO: " + e);
const fallos = (listo ? 0 : 1) + errores.length;
console.log(`FIN. ${fallos} fallos`);
process.exit(fallos === 0 ? 0 : 1);
