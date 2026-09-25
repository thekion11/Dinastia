const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const base = __dirname;

function xmlToText(xml) {
  const paras = xml.split(/<w:p[ >]/).slice(1);
  const lines = [];
  for (const p of paras) {
    const texts = [...p.matchAll(/<w:t[^>]*>([^<]*)<\/w:t>/g)].map((m) => m[1]);
    const line = texts
      .join("")
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, '"')
      .trim();
    if (line) lines.push(line);
  }
  return lines.join("\n");
}

for (const name of ["maestro", "arquitectura"]) {
  const zip = path.join(base, name + ".zip");
  const dest = path.join(base, name + "_xml");
  fs.copyFileSync(path.join(base, name + ".docx"), zip);
  if (fs.existsSync(dest)) fs.rmSync(dest, { recursive: true, force: true });
  execSync(
    `powershell -NoProfile -Command "Expand-Archive -LiteralPath '${zip}' -DestinationPath '${dest}' -Force"`
  );
  const xml = fs.readFileSync(path.join(dest, "word", "document.xml"), "utf8");
  const txt = xmlToText(xml);
  fs.writeFileSync(path.join(base, name + ".txt"), txt, "utf8");
  console.log(name, "chars", txt.length, "lines", txt.split("\n").length);
}
