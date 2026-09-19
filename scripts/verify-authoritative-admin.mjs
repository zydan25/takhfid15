import { readFileSync, existsSync } from "node:fs";

const fail = (message) => {
  console.error("❌", message);
  process.exitCode = 1;
};

const requiredGone = [
  "src/main.tsx",
  "src/App.tsx",
  "src/admin-app/AdminApp.tsx",
  "src/components/AdminModal.tsx",
  "src/components/BottomNavigation.tsx",
];

for (const path of requiredGone) {
  if (existsSync(path)) fail(`Legacy UI file still exists: ${path}`);
}

const indexHtml = readFileSync("index.html", "utf8");
const bridge = readFileSync("public/assets/takhfid-bridge.js", "utf8");
const bundle = readFileSync("public/assets/index-Co2L1R-b.js", "utf8");

const required = [
  ["index.html API config", indexHtml.includes("VITE_API_BASE_URL")],
  ["server-authoritative product add", bundle.includes('await window.__takhfidSaveProduct') && bundle.includes('"create"')],
  ["server-authoritative product update", bundle.includes('await window.__takhfidSaveProduct') && bundle.includes('"update"')],
  ["server-authoritative product delete", bundle.includes('await window.__takhfidSaveProduct') && bundle.includes('"delete"')],
  ["server refresh bridge", bridge.includes("syncFromServer") && bridge.includes("window.__takhfidRefresh")],
  ["server-first content writes", bridge.includes("جلسة الإدارة غير مفعلة") && bridge.includes("saveCategories") && bridge.includes("saveBanners")],
  ["order address API", bridge.includes("updateOrderAddress") && bridge.includes("/orders/")],
  ["new product editor text", bundle.includes("إنشاء صنف جديد بالمتجر") && bundle.includes("صور 3:4")],
];

for (const [name, ok] of required) {
  if (ok) console.log("✅", name);
  else fail(`Missing: ${name}`);
}

if (bundle.includes('id:"admin-sync-cloud-btn"')) {
  fail("Manual bulk-sync button is still rendered in the shipped bundle.");
} else {
  console.log("✅ manual bulk-sync button removed from shipped bundle");
}

if (bundle.includes("const Us=()=>{ot(!0),Ee(0),setTimeout")) {
  fail("Pull-to-refresh still uses local-only rotation.");
} else {
  console.log("✅ pull-to-refresh is server-driven");
}

if (bridge.includes("return { success: true, cached: true")) {
  fail("Content API still reports local-cache success without server acceptance.");
} else {
  console.log("✅ no fake local-cache success for admin content writes");
}

if (process.exitCode) process.exit(1);
console.log("All server-authoritative admin checks passed.");
