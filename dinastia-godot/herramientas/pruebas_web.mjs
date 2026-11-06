// PRUEBAS POR SISTEMA EN WEB (5-11-2026): abre en Chromium cada escena de `pruebas/so/LISTA.txt` que aplica a Web (sistema «web» o «todos»;
// requiere headless o compat) sobre un export Web CON las pruebas dentro (preset Web sin el filtro `pruebas/*`) y espera su marcador
// «OK|FALLO <nombre> [web]». Para elegir la escena se cambia `"args":[]` del index.html servido por la ruta de la escena (positional de Godot).
//   node pruebas_web.mjs <carpeta_del_export> <LISTA.txt> <registro.txt> [nombre ...]
// Entorno: CHROME_PATH, TOPE_S (por prueba, 150), PARALELAS (páginas a la vez, 2). Salida: «OK|FALLO <nombre> <n> s …» (lo lee tabla_so.py).
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright-core";

const [carpeta, listaRuta, registro, ...soloNombres] = process.argv.slice(2);
if (!carpeta || !listaRuta || !registro) { console.error("uso: pruebas_web.mjs <carpeta> <LISTA.txt> <registro.txt> [nombre ...]"); process.exit(2); }
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".pck": "application/octet-stream",
  ".png": "image/png", ".json": "application/json", ".css": "text/css", ".svg": "image/svg+xml", ".ico": "image/x-icon" };

// Pruebas que aplican a Web.
const pruebas = fs.readFileSync(listaRuta, "utf-8").split("\n").filter((l) => l.trim() && !l.startsWith("#")).map((l) => {
  const [nombre, familia, sistemas, escena, requiere] = l.split("|").map((x) => x.trim());
  return { nombre, familia, sistemas: sistemas.split(","), escena, requiere };
}).filter((p) => (p.sistemas.includes("todos") || p.sistemas.includes("web")) && ["headless", "compat"].includes(p.requiere)
  && (soloNombres.length === 0 || soloNombres.includes(p.nombre)));
const escenas = new Map(pruebas.map((p) => [p.nombre, p.escena]));   // lista cerrada: la URL solo elige entre estas

// Servidor con lista cerrada de archivos (la ruta pedida nunca llega al sistema de archivos).
const raiz = path.resolve(carpeta);
const archivos = new Map();
(function listar(dir, prefijo) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) listar(path.join(dir, e.name), prefijo + e.name + "/");
    else if (e.isFile()) archivos.set(prefijo + e.name, path.join(dir, e.name));
  }
})(raiz, "/");
const indice = fs.readFileSync(archivos.get("/index.html"), "utf-8");
if (!indice.includes('"args":[]')) { console.error('FALLO: el index.html no trae "args":[] (¿cambió la plantilla de Godot?)'); process.exit(2); }
const servidor = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");   // NOSONAR(javascript:S5332): base ficticia solo para analizar la URL; el servidor es local
  let ruta = url.pathname;
  const cab = { "Cross-Origin-Opener-Policy": "same-origin", "Cross-Origin-Embedder-Policy": "require-corp" };
  if (ruta === "/" || ruta === "/index.html") {
    const escena = escenas.get(url.searchParams.get("t") ?? "");
    const html = escena === undefined ? indice : indice.replace('"args":[]', `"args":[${JSON.stringify(escena)}]`);
    res.writeHead(200, { ...cab, "Content-Type": "text/html" });
    res.end(html);
    return;
  }
  const archivo = archivos.get(ruta);
  if (archivo === undefined) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { ...cab, "Content-Type": MIME[path.extname(archivo)] || "application/octet-stream" });
  fs.createReadStream(archivo).pipe(res);
});
await new Promise((r) => servidor.listen(0, "127.0.0.1", r));
const puerto = servidor.address().port;

const opciones = { headless: true, args: ["--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] };
if (process.env.CHROME_PATH) opciones.executablePath = process.env.CHROME_PATH; else opciones.channel = "chrome";
const navegador = await chromium.launch(opciones);
const tope = (Number(process.env.TOPE_S) || 150) * 1000;

async function correr(p) {
  const t0 = Date.now();
  const pagina = await navegador.newPage({ viewport: { width: 960, height: 540 } });
  const marcador = new RegExp(`^(OK|FALLO) ${p.nombre} \\[(\\w+)\\]`);
  let veredicto = "";
  const detalle = [];
  const ultimas = [];   // últimas líneas de consola: para saber qué pasó cuando no hay marcador
  pagina.on("console", (m) => {
    const t = m.text();
    ultimas.push(t.slice(0, 120));
    if (ultimas.length > 4) ultimas.shift();
    const k = marcador.exec(t);
    if (k) veredicto = k[1];
    else if (/^FALLO |SCRIPT ERROR|SHADER ERROR/.test(t)) detalle.push(t.slice(0, 160));
  });
  pagina.on("pageerror", (e) => detalle.push("pageerror: " + e.message.slice(0, 160)));
  await pagina.goto(`http://127.0.0.1:${puerto}/index.html?t=${encodeURIComponent(p.nombre)}`);
  while (veredicto === "" && Date.now() - t0 < tope) await pagina.waitForTimeout(500);
  await pagina.close();
  const seg = Math.round((Date.now() - t0) / 1000);
  const malo = veredicto !== "OK" || detalle.some((d) => d.includes("SCRIPT ERROR"));
  const motivo = veredicto === "" ? "sin marcador (tope de tiempo o no arrancó); consola: " + ultimas.join(" ¦ ") : detalle.slice(0, 3).join(" | ");
  return `${malo ? "FALLO" : "OK   "} ${p.nombre.padEnd(42)} ${String(seg).padStart(3)} s  ${malo ? motivo : ""}`;
}

const salida = [];
const cola = [...pruebas];
async function obrero() {
  for (let p = cola.shift(); p !== undefined; p = cola.shift()) {
    const linea = await correr(p);
    console.log(linea);
    salida.push(linea);
  }
}
await Promise.all(Array.from({ length: Number(process.env.PARALELAS) || 2 }, obrero));
await navegador.close();
servidor.close();
const fallos = salida.filter((l) => l.startsWith("FALLO")).length;
const resumen = `PRUEBAS POR SISTEMA [web]: ${pruebas.length} pruebas, ${fallos} fallos`;
console.log(resumen);
fs.writeFileSync(registro, salida.join("\n") + "\n" + resumen + "\n");
process.exit(fallos === 0 ? 0 : 1);
