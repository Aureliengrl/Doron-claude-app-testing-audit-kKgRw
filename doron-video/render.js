const { bundle } = require("@remotion/bundler");
const { renderMedia, selectComposition } = require("@remotion/renderer");
const path = require("path");
const fs = require("fs");

async function main() {
  console.log("🎬 Doron Video Renderer");
  console.log("========================\n");

  // Output dir
  const outDir = path.join(__dirname, "out");
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

  console.log("📦 Bundling...");
  const bundled = await bundle({
    entryPoint: path.join(__dirname, "src/index.jsx"),
    webpackOverride: (config) => config,
  });

  console.log("🎯 Selecting composition...");
  const composition = await selectComposition({
    serveUrl: bundled,
    id: "DoronVideo",
  });

  const outPath = path.join(outDir, "doron-promo.mp4");

  console.log("🚀 Rendering... (peut prendre 2-5 min)");
  console.log(`   Output: ${outPath}\n`);

  await renderMedia({
    composition,
    serveUrl: bundled,
    codec: "h264",
    outputLocation: outPath,
    onProgress: ({ progress }) => {
      const pct = Math.round(progress * 100);
      const bar = "█".repeat(Math.round(pct / 5)) + "░".repeat(20 - Math.round(pct / 5));
      process.stdout.write(`\r   [${bar}] ${pct}%`);
    },
  });

  console.log("\n\n✅ Vidéo générée !");
  console.log(`📁 ${outPath}`);
  console.log("\n🎙️  Prochaine étape : Ajouter la voix sur ElevenLabs");
  console.log("   → https://elevenlabs.io");
  console.log("   → Voix recommandée : 'Callum' ou 'Charlotte' (français)");
}

main().catch((e) => {
  console.error("\n❌ Erreur:", e.message);
  process.exit(1);
});
