const fs = require("fs");
const bundle = fs.readFileSync("public/assets/index-Co2L1R-b.js", "utf8");
const exact = fs.readFileSync("exact_banners.json", "utf8");

// 1. Categories
let posMT = bundle.indexOf("MT=[{id:\"all\"");
let endMT = bundle.indexOf("SR=[", posMT);
let mtPart = bundle.slice(posMT, endMT).trim().replace(/,$/, "");
let masterCategories = eval(mtPart.replace("MT=", ""));

// 2. Banners
let posSR = bundle.indexOf("SR=[{id:\"banner-");
let endSR = bundle.indexOf("OT=", posSR);
let srPart = bundle.slice(posSR, endSR).trim().replace(/,$/, "");
let masterBanners = eval(srPart.replace("SR=", ""));

// 3. Campaigns & Hashtags
let posHb = exact.indexOf("hb=[");
let endHb = exact.indexOf("PT=[", posHb);
let hbPart = exact.slice(posHb, endHb).trim().replace(/,$/, "");
let masterCampaigns = eval(hbPart.replace("hb=", ""));

let posTv = exact.indexOf("tv=[");
let endTv = exact.indexOf("hb=[", posTv);
let tvPart = exact.slice(posTv, endTv).trim().replace(/,$/, "");
let masterHashtags = eval(tvPart.replace("tv=", ""));

// 4. Products
let posPt = exact.indexOf("PT=[");
let endPt = exact.indexOf("kR=[", posPt);
let ptPart = exact.slice(posPt, endPt).trim().replace(/,$/, "");
let masterProducts = eval(ptPart.replace("PT=", ""));

// 5. Reviews
let posRx = bundle.indexOf("Rx=[{id:\"rev-p1-1\"");
let endRx = bundle.indexOf("];", posRx);
let rxPart = bundle.slice(posRx, endRx + 1).trim();
let masterReviews = eval(rxPart.replace("Rx=", ""));

// 6. Announcements
let posKT = bundle.indexOf("KT=[{id:\"screen-1");
let endKT = bundle.indexOf(",bm={isEnabled:!0", posKT);
let ktCode = bundle.slice(posKT, endKT).trim();
let ktScreens = eval(ktCode.replace("KT=", ""));
let masterAnnouncements = {
  isEnabled: true,
  autoFlip: true,
  intervalSeconds: 4,
  screens: ktScreens
};

// 7. Category Tabs Config
let masterCategoryTabsConfig = {
  shape: "circle",
  size: "medium",
  customBorderRadius: undefined,
  customWidth: undefined,
  customHeight: undefined,
  isSquareRatio: true
};

// 8. Recommendation Tabs
let posUB = bundle.indexOf("const UB=[{id:\"all\"");
let endUB = bundle.indexOf("],zT=\"store_recommendation_tabs_v2\"", posUB);
let ubCode = bundle.slice(posUB, endUB + 1).trim();
let masterRecommendationTabs = eval(ubCode.replace("const UB=", ""));

const masterData = {
  categories: masterCategories,
  banners: masterBanners,
  campaigns: masterCampaigns,
  trendHashtags: masterHashtags,
  products: masterProducts,
  reviews: masterReviews,
  announcements: masterAnnouncements,
  categoryTabsConfig: masterCategoryTabsConfig,
  recommendationTabs: masterRecommendationTabs
};

fs.mkdirSync("data", { recursive: true });
fs.writeFileSync("data/server_seed_data.json", JSON.stringify(masterData, null, 2));
console.log("SUCCESSFULLY generated data/server_seed_data.json!");
console.log("- Categories:", masterCategories.length);
console.log("- Banners:", masterBanners.length);
console.log("- Campaigns:", masterCampaigns.length);
console.log("- Hashtags:", masterHashtags.length);
console.log("- Products:", masterProducts.length);
console.log("- Reviews:", masterReviews.length);
console.log("- Announcement screens:", masterAnnouncements.screens.length);
console.log("- Category tabs shape:", masterCategoryTabsConfig.shape);
console.log("- Recommendation tabs:", masterRecommendationTabs.length);
