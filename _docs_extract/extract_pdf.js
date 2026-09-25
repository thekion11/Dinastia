const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const dir = __dirname;
try {
  execSync("npm install pdf-parse@1.1.1 --omit=dev", { cwd: dir, stdio: "inherit" });
} catch (e) {
  console.error("npm install failed", e.message);
  process.exit(1);
}

const pdfParse = require("pdf-parse");
const buf = fs.readFileSync(path.join(dir, "informe.pdf"));
pdfParse(buf).then((data) => {
  fs.writeFileSync(path.join(dir, "informe.txt"), data.text, "utf8");
  console.log("pdf pages", data.numpages, "chars", data.text.length);
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
