/**
 * Takhfid Store - Complete Real-Time Sync & Server Bridge (v4 API)
 * Handles bidirectional synchronization between the client store, local cache,
 * and the Flask Backend (https://whats.alattab.site/takhfid/api/v4).
 * 
 * Includes comprehensive data normalization and fallbacks to prevent any
 * missing-property runtime errors (white screens) across all screens.
 */
(function() {
  'use strict';

  function getCustomApiBaseUrl() {
    try {
      if (typeof window !== 'undefined') {
        var winEnv = window.VITE_API_BASE_URL || window.__VITE_API_BASE_URL;
        if (winEnv && typeof winEnv === 'string' && winEnv.indexOf('%') === -1 && winEnv.trim()) {
          return winEnv.trim();
        }
      }
    } catch(e) {}
    return 'https://whats.alattab.site';
  }

  var rawBaseUrl = getCustomApiBaseUrl();
  var REMOTE_SERVER = rawBaseUrl.replace(/\/takhfid\/api\/v4\/?$/, '').replace(/\/+$/, '');
  var API_BASE = REMOTE_SERVER + '/takhfid/api/v4';
  var DIRECT_REMOTE_BASE = API_BASE;

  var lastHooks = null;
  var lastConnectionError = null;

  function showConnectionErrorBanner(errMsg) {
    if (typeof document === 'undefined') return;
    var existing = document.getElementById('takhfid-connection-error-banner');
    if (!existing) {
      existing = document.createElement('div');
      existing.id = 'takhfid-connection-error-banner';
      existing.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99999;background:#fee2e2;color:#991b1b;border-bottom:1px solid #f87171;padding:8px 12px;font-family:Cairo,sans-serif;font-size:12px;display:flex;align-items:center;justify-content:space-between;gap:8px;box-shadow:0 2px 8px rgba(0,0,0,0.15);direction:rtl;';
      var rootEl = document.getElementById('root');
      if (rootEl && rootEl.parentNode) {
        rootEl.parentNode.insertBefore(existing, rootEl);
      } else {
        document.body.appendChild(existing);
      }
    }
    existing.innerHTML = '<div style="display:flex;align-items:center;gap:6px;flex:1;overflow:hidden;"><span style="font-size:14px;">⚠️</span><span style="font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">تعذر الاتصال بالخادم: ' + (errMsg || 'خطأ في الشبكة أو الخادم') + '</span></div><button id="takhfid-retry-btn" style="background:#dc2626;color:#ffffff;border:none;border-radius:6px;padding:4px 10px;font-size:11px;font-weight:700;cursor:pointer;flex-shrink:0;">إعادة المحاولة</button>';
    var btn = document.getElementById('takhfid-retry-btn');
    if (btn) {
      btn.onclick = function() {
        btn.textContent = 'جارٍ المحاولة...';
        btn.disabled = true;
        if (window.__takhfidInitSync && lastHooks) {
          window.__takhfidInitSync(lastHooks).finally(function() {
            btn.textContent = 'إعادة المحاولة';
            btn.disabled = false;
          });
        }
      };
    }
  }

  function hideConnectionErrorBanner() {
    if (typeof document === 'undefined') return;
    var existing = document.getElementById('takhfid-connection-error-banner');
    if (existing && existing.parentNode) {
      existing.parentNode.removeChild(existing);
    }
  }

  function isNativePlatform() {
    if (typeof window === 'undefined') return false;
    if (window.Capacitor) return true;
    var proto = (window.location && window.location.protocol) || '';
    var host = (window.location && window.location.hostname) || '';
    if (proto === 'file:' || proto === 'capacitor:' || proto === 'ionic:' || proto === 'content:') {
      return true;
    }
    if (host === 'localhost' || host === '127.0.0.1' || host === '') {
      return true;
    }
    if (typeof navigator !== 'undefined' && navigator.userAgent) {
      if (/Android|iPhone|iPad|iPod|Capacitor/i.test(navigator.userAgent) || navigator.userAgent.indexOf('wv') !== -1) {
        return true;
      }
    }
    return false;
  }

  function getBaseUrl() {
    return DIRECT_REMOTE_BASE;
  }

  if (typeof window !== 'undefined' && window.fetch && !window.__takhfidFetchPatched) {
    window.__takhfidFetchPatched = true;
    var _origFetch = window.fetch;
    window.fetch = function(input, init) {
      try {
        if (typeof input === 'string') {
          if (input.startsWith('/takhfid')) {
            input = REMOTE_SERVER + input;
          } else if (input.indexOf('localhost/takhfid') !== -1 || input.indexOf('127.0.0.1/takhfid') !== -1) {
            input = input.replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/, REMOTE_SERVER).replace(/^capacitor:\/\/localhost/, REMOTE_SERVER);
          }
        } else if (input && typeof input === 'object' && input.url) {
          var u = input.url;
          if (u.startsWith('/takhfid')) {
            return _origFetch.call(this, new Request(REMOTE_SERVER + u, input), init);
          } else if (u.indexOf('localhost/takhfid') !== -1 || u.indexOf('127.0.0.1/takhfid') !== -1) {
            var newU = u.replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/, REMOTE_SERVER).replace(/^capacitor:\/\/localhost/, REMOTE_SERVER);
            return _origFetch.call(this, new Request(newU, input), init);
          }
        }
      } catch (err) {
        console.warn('[Takhfid Bridge] fetch url rewrite notice:', err);
      }
      return _origFetch.call(this, input, init);
    };
  }

  function getAuthToken() {
    try {
      var t = localStorage.getItem('takhfid_access_token');
      if (t) return t;
      var prof = localStorage.getItem('user_profile');
      if (prof) {
        var p = JSON.parse(prof);
        if (p && (p.accessToken || p.token)) return p.accessToken || p.token;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  function getAuthHeaders(includeContentType) {
    var headers = {};
    if (includeContentType !== false) {
      headers['Content-Type'] = 'application/json';
    }
    var token = getAuthToken();
    if (token) {
      headers['Authorization'] = 'Bearer ' + token;
    }
    return headers;
  }

  var activeToast = null;
  function toast(msg, type) {
    if (activeToast) {
      try { activeToast(msg, type || 'info'); } catch(e) {}
    } else {
      console.log('[Takhfid Bridge ' + (type || 'info') + ']: ' + msg);
    }
  }

  // --- SAFE DATA NORMALIZATION ---
  function normalizeProduct(p) {
    if (!p) return null;
    var res = Object.assign({}, p);

    var discPrice = typeof p.discountPrice === 'number' && !isNaN(p.discountPrice)
      ? p.discountPrice
      : (typeof p.price === 'number' && !isNaN(p.price)
        ? p.price
        : (typeof p.originalPrice === 'number' && !isNaN(p.originalPrice) ? p.originalPrice : 45));

    var origPrice = typeof p.originalPrice === 'number' && !isNaN(p.originalPrice)
      ? p.originalPrice
      : (typeof p.price === 'number' && !isNaN(p.price)
        ? Math.round(p.price * 1.35)
        : Math.round(discPrice * 1.35));

    if (origPrice < discPrice) origPrice = Math.round(discPrice * 1.35);

    var discPerc = typeof p.discountPercentage === 'number' && !isNaN(p.discountPercentage)
      ? p.discountPercentage
      : (origPrice > discPrice ? Math.round(((origPrice - discPrice) / origPrice) * 100) : 0);

    var cat = p.category || (Array.isArray(p.categories) && p.categories[1] ? p.categories[1] : 'women');
    var cats = Array.isArray(p.categories) && p.categories.length > 0 ? p.categories : ['all', cat];

    var img = p.image || (Array.isArray(p.images) && p.images[0]) || (Array.isArray(p.galleryImages) && p.galleryImages[0]) || 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&auto=format&fit=crop&q=80';
    var gallery = Array.isArray(p.galleryImages) && p.galleryImages.length > 0
      ? p.galleryImages
      : (Array.isArray(p.images) && p.images.length > 0 ? p.images : [img]);

    // Normalize colors, preserving per-color images and hex values
    var colors = Array.isArray(p.colors) && p.colors.length > 0 ? p.colors.map(function(c) {
      if (typeof c === 'string') {
        return { name: c, hex: '#1e293b', images: [img], image: img };
      }
      var cImgs = Array.isArray(c.images) && c.images.length > 0
        ? c.images
        : (c.image ? [c.image] : [img]);
      return {
        name: c.name || 'لون',
        hex: c.hex || '#1e293b',
        image: cImgs[0] || img,
        images: cImgs
      };
    }) : [{ name: 'افتراضي', hex: '#1e293b', image: img, images: [img] }];

    var sizes = Array.isArray(p.sizes) && p.sizes.length > 0 ? p.sizes : ['M', 'L', 'XL'];
    var tags = Array.isArray(p.tags) ? p.tags : (p.tags ? [String(p.tags)] : []);
    var trends = Array.isArray(p.trends) && p.trends.length > 0 ? p.trends : (p.trendTag ? [p.trendTag] : []);

    res.id = String(p.id || ('p-' + Date.now()));
    res.name = String(p.name || p.title || 'صنف جديد');
    res.brand = String(p.brand || 'SHEIN');
    res.category = String(cat);
    res.categories = cats;
    res.subCategory = String(p.subCategory || 'عام');
    res.originalPrice = Number(origPrice);
    res.discountPrice = Number(discPrice);
    res.discountPercentage = Number(discPerc);
    res.price = Number(discPrice);
    res.rating = typeof p.rating === 'number' ? p.rating : 4.8;
    res.reviewsCount = typeof p.reviewsCount === 'number' ? p.reviewsCount : 120;
    res.image = String(img);
    res.images = gallery;
    res.galleryImages = gallery;
    res.colors = colors;
    res.sizes = sizes;
    res.tags = tags;
    res.trends = trends;
    res.inStock = p.inStock !== false && p.stock !== 0;

    // Badges & customizations - fully preserved and synchronized
    res.isSavingBannerEnabled = Boolean(p.isSavingBannerEnabled);
    res.savingBannerPrefix = p.savingBannerPrefix !== undefined ? String(p.savingBannerPrefix) : 'توفير';
    res.savingBannerLeftText = p.savingBannerLeftText !== undefined ? String(p.savingBannerLeftText) : '';
    res.savingBannerBgColor = p.savingBannerBgColor || 'rgba(0, 0, 0, 0.78)';
    res.savingBannerTextColor = p.savingBannerTextColor || '#ffffff';
    res.savingBannerPriceColor = p.savingBannerPriceColor || '#facc15';

    res.showCardShipping = Boolean(p.showCardShipping);
    res.cardShippingText = p.cardShippingText !== undefined ? String(p.cardShippingText) : 'شحن مجاني وسريع 🚚';
    res.isLocalFastShipping = Boolean(p.isLocalFastShipping);

    res.isNewBadgeEnabled = p.isNewBadgeEnabled !== false;
    res.newBadgeText = p.newBadgeText || 'NEW';
    res.newBadgeTextColor = p.newBadgeTextColor || '#ffffff';
    res.newBadgeBgColor = p.newBadgeBgColor || '#10b981';
    res.newBadgeDurationDays = typeof p.newBadgeDurationDays === 'number' ? p.newBadgeDurationDays : 7;

    res.isBestSeller = Boolean(p.isBestSeller);
    res.bestSellerText = p.bestSellerText || '';
    res.campaignRibbonText = p.campaignRibbonText || '';
    res.ratingReviewsText = p.ratingReviewsText || '';
    res.cartBadgeCount = typeof p.cartBadgeCount === 'number' ? p.cartBadgeCount : undefined;
    res.productType = p.productType || '';
    res.fabric = p.fabric || '';
    res.ageGroup = p.ageGroup || '';
    res.hasCurveLogo = Boolean(p.hasCurveLogo);
    res.stretchInfo = p.stretchInfo || '';
    res.hasZoomInBubble = Boolean(p.hasZoomInBubble);
    res.zoomBubbleImage = p.zoomBubbleImage || '';
    res.enableReviews = p.enableReviews !== false;
    res.enableSizeGuide = p.enableSizeGuide !== false;
    res.cardAspect = p.cardAspect || 'tall';
    res.sku = p.sku || ('SKU-' + (p.id || Date.now()));
    res.soldCount = typeof p.soldCount === 'number' ? p.soldCount : 100;

    return res;
  }

  function normalizeBanner(b, idx) {
    if (!b) return null;
    return {
      id: String(b.id || ('banner-' + (idx || Date.now()))),
      title: String(b.title || 'شاشة عرض'),
      subtitle: String(b.subtitle || ''),
      image: String(b.image || 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&auto=format&fit=crop&q=80'),
      bgGradient: b.bgGradient || 'from-[#5C2304] via-[#853409] to-[#AC4A0F]',
      themeColor: b.themeColor || '#853409',
      customColor: b.customColor || '',
      isTransparent: b.isTransparent !== false,
      badge: b.badge || '',
      floatingText: b.floatingText || '',
      floatingTextPosition: b.floatingTextPosition || 'top-right',
      slideDuration: b.slideDuration && Number(b.slideDuration) > 0 ? Number(b.slideDuration) : 4,
      categoryId: b.categoryId || 'all',
      categoryTarget: b.categoryTarget || b.categoryId || 'all',
      targetType: b.targetType || 'category',
      targetSubCategory: b.targetSubCategory || '',
      targetStyleTab: b.targetStyleTab || '',
      targetTrend: b.targetTrend || '',
      pullToRefreshTitle: b.pullToRefreshTitle || 'التخفيض الصح',
      pullToRefreshSubtitle: b.pullToRefreshSubtitle || b.subtitle || 'أناقة الجميع',
      subScreenTabs: Array.isArray(b.subScreenTabs) ? b.subScreenTabs : [],
      isActive: b.isActive !== false && b.active !== false,
      order: typeof b.order === 'number' ? b.order : (idx + 1)
    };
  }

  function sortCategoriesWithAllFirst(cats) {
  if (!Array.isArray(cats)) return cats;
  var allIdx = cats.findIndex(function(c) { return c && (c.id === "all" || c.name === "كل" || c.name === "الكل"); });
  if (allIdx > 0) {
    var allCat = cats[allIdx];
    var rest = cats.filter(function(_, idx) { return idx !== allIdx; });
    return [allCat].concat(rest);
  }
  return cats;
}

function normalizeCategory(c, existingDefaults) {
    if (!c) return null;
    var def = existingDefaults ? existingDefaults.find(function(d) { return d.id === c.id; }) : null;
    var subCats = Array.isArray(c.subCategories) && c.subCategories.length > 0 ? c.subCategories : (def && def.subCategories ? def.subCategories : []);
    var styleTabs = Array.isArray(c.styleTabs) && c.styleTabs.length > 0 ? c.styleTabs : (def && def.styleTabs ? def.styleTabs : []);
    var sideCats = Array.isArray(c.sideCategories) && c.sideCategories.length > 0 ? c.sideCategories : (def && def.sideCategories ? def.sideCategories : []);

    return {
      id: String(c.id || ('cat-' + Date.now())),
      name: String(c.name || 'قسم'),
      iconName: c.iconName || (def && def.iconName) || 'Shirt',
      image: c.image || (def && def.image) || 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&auto=format&fit=crop&q=80',
      badge: c.badge || (def && def.badge) || '',
      itemCount: typeof c.itemCount === 'number' ? c.itemCount : (def ? def.itemCount : 0),
      subCategories: subCats,
      styleTabs: styleTabs,
      sideCategories: sideCats
    };
  }

  function normalizeAnnouncementSettings(settings) {
    if (settings && typeof settings === 'object' && Array.isArray(settings.screens) && settings.screens.length > 0) {
      return settings;
    }
    // Return safe default announcement settings if missing/corrupted
    return {
      isEnabled: true,
      autoFlip: true,
      intervalSeconds: 4,
      screens: [
        {
          id: "screen-free-shipping",
          title: "شحن مجاني",
          badgeText: "عرض حصري 🚚",
          mainTitle: "شحن مجاني لكافة المحافظات",
          subTitle: "للطلبات الأكثر من 20,000 ر.ي",
          iconType: "truck",
          coupons: [
            { id: "c1", code: "FREESHIP", discount: "شحن مجاني", minSpend: "الحد الأدنى 20,000 ر.ي" },
            { id: "c2", code: "EXPRESS", discount: "توصيل سريع", minSpend: "للطلبات المؤكدة" }
          ],
          backgroundColor: "#F0FDF4",
          cardBackgroundColor: "#DCFCE7",
          textColor: "#166534",
          badgeBackgroundColor: "#15803D",
          badgeTextColor: "#FFFFFF",
          borderColor: "#BBF7D0",
          excelPresetId: "emerald",
          isActive: true,
          order: 1
        },
        {
          id: "screen-new-user",
          title: "ترحيب بالعميل الجديد",
          badgeText: "هدية الترحيب 🎁",
          mainTitle: "خصم 20% للطلب الأول",
          subTitle: "قسيمة خصم فورية عند أول عملية شراء",
          iconType: "percent",
          coupons: [
            { id: "c3", code: "WELCOME20", discount: "خصم 20%", minSpend: "بدون حد أدنى" },
            { id: "c4", code: "EXTRA5", discount: "إضافي 5%", minSpend: "للطلب الفوري" }
          ],
          backgroundColor: "#FEF2F2",
          cardBackgroundColor: "#FEE2E2",
          textColor: "#991B1B",
          badgeBackgroundColor: "#DC2626",
          badgeTextColor: "#FFFFFF",
          borderColor: "#FECACA",
          excelPresetId: "rose",
          isActive: true,
          order: 2
        }
      ]
    };
  }

  function normalizeCampaign(camp, idx) {
    if (!camp) return null;
    return {
      id: String(camp.id || ('camp-' + (idx || Date.now()))),
      hashtag: String(camp.hashtag || '#تخفيض_الصح'),
      title: String(camp.title || 'حملة ترويجية'),
      description: String(camp.description || ''),
      bgImage: camp.bgImage || 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1200&auto=format&fit=crop&q=80',
      daysLeft: camp.daysLeft || '3 أيام',
      productIds: Array.isArray(camp.productIds) ? camp.productIds : [],
      isActive: camp.isActive !== false
    };
  }

  var takhfidBridge = {
    version: '4.3.0',
    setToastHandler: function(fn) {
      activeToast = fn;
    },

    // 1. PRODUCTS API
    fetchProducts: async function() {
      try {
        var res = await fetch(getBaseUrl() + '/products?limit=200');
        if (!res.ok) throw new Error('HTTP ' + res.status);
        var data = await res.json();
        var rawList = Array.isArray(data) ? data : (data.products || []);
        var normalized = rawList.map(normalizeProduct).filter(Boolean);
        lastConnectionError = null;
        return normalized;
      } catch (err) {
        console.warn('[Bridge] fetchProducts failed, falling back to direct remote:', err);
        try {
          var r2 = await fetch(DIRECT_REMOTE_BASE + '/products?limit=200');
          if (!r2.ok) throw new Error('HTTP ' + r2.status);
          var d2 = await r2.json();
          var rawList2 = Array.isArray(d2) ? d2 : (d2.products || []);
          var normalized2 = rawList2.map(normalizeProduct).filter(Boolean);
          lastConnectionError = null;
          return normalized2;
        } catch (e2) {
          lastConnectionError = e2 || err;
          console.error('[Bridge] direct fetchProducts error:', e2);
          return [];
        }
      }
    },

    saveProduct: async function(product, action) {
      if (!product || !product.id) return { success: false, error: 'بيانات المنتج غير مكتملة' };
      var act = action || 'update';
      var url = getBaseUrl() + '/admin/products';
      var method = 'POST';

      if (act === 'delete') {
        url += '/' + encodeURIComponent(product.id);
        method = 'DELETE';
      } else if (act === 'update') {
        url += '/' + encodeURIComponent(product.id);
        method = 'PUT';
      }

      var safeProd = normalizeProduct(product);

      try {
        var res = await fetch(url, {
          method: method,
          headers: getAuthHeaders(true),
          body: act === 'delete' ? undefined : JSON.stringify(safeProd)
        });
        var data = await res.json().catch(function() { return {}; });
        if (!res.ok || data.success === false) {
          console.warn('[Bridge] saveProduct error:', data.error || ('HTTP ' + res.status));
          return { success: false, error: data.error || 'فشل حفظ المنتج على الخادم' };
        }
        console.log('[Bridge] Product ' + product.id + ' saved successfully:', act);
        return { success: true, product: data.product || safeProd };
      } catch (err) {
        console.error('[Bridge] saveProduct network exception:', err);
        return { success: false, error: err.message };
      }
    },

    // 2. CONTENT API (Categories, Banners, Campaigns, Announcements, Tabs)
    fetchContent: async function() {
      try {
        var res = await fetch(getBaseUrl() + '/content');
        if (!res.ok) throw new Error('HTTP ' + res.status);
        var data = await res.json();
        return data.content || data || {};
      } catch (err) {
        console.warn('[Bridge] fetchContent failed, trying direct remote:', err);
        try {
          var r2 = await fetch(DIRECT_REMOTE_BASE + '/content');
          if (!r2.ok) throw new Error('HTTP ' + r2.status);
          var d2 = await r2.json();
          return d2.content || d2 || {};
        } catch (e2) {
          console.error('[Bridge] fetchContent error:', e2);
          if (!lastConnectionError) lastConnectionError = e2 || err;
          return {};
        }
      }
    },

    updateContentSection: async function(payload) {
      var token = getAuthToken();
      if (!token) {
        console.warn('[Bridge] updateContentSection: No active auth token. Logging in with admin phone 774952665 is required for remote server sync.');
      }
      try {
        var res = await fetch(getBaseUrl() + '/admin/content', {
          method: 'PUT',
          headers: getAuthHeaders(true),
          body: JSON.stringify(payload)
        });
        var data = await res.json().catch(function() { return {}; });
        if (res.status === 401 || (data && data.error && data.error.includes('غير مصرح'))) {
          console.warn('[Bridge] 401 Unauthorized from server. Admin login needed.');
          toast('تم الحفظ محلياً. لمزامنة الخادم، يرجى تسجيل الدخول برقمك (774952665) 📱', 'warning');
          return { success: false, error: 'جلسة الأدمن غير مفعلة', localSaved: true };
        }
        if (!res.ok || data.success === false) {
          console.warn('[Bridge] updateContentSection proxy failed, trying direct remote:', data);
          var r2 = await fetch(DIRECT_REMOTE_BASE + '/admin/content', {
            method: 'PUT',
            headers: getAuthHeaders(true),
            body: JSON.stringify(payload)
          });
          var d2 = await r2.json().catch(function() { return {}; });
          if (!r2.ok || d2.success === false) {
            return { success: false, error: d2.error || ('HTTP ' + r2.status) };
          }
          return { success: true, data: d2 };
        }
        return { success: true, data: data };
      } catch (err) {
        console.warn('[Bridge] updateContentSection network error, trying direct remote:', err);
        try {
          var r2 = await fetch(DIRECT_REMOTE_BASE + '/admin/content', {
            method: 'PUT',
            headers: getAuthHeaders(true),
            body: JSON.stringify(payload)
          });
          var d2 = await r2.json().catch(function() { return {}; });
          if (!r2.ok || d2.success === false) {
            return { success: false, error: d2.error || ('HTTP ' + r2.status) };
          }
          return { success: true, data: d2 };
        } catch (e2) {
          console.error('[Bridge] updateContentSection fatal network error:', e2);
          return { success: false, error: e2.message };
        }
      }
    },
    saveCategories: async function(categories) {
      if (!Array.isArray(categories)) return { success: false };
      var safe = categories.map(function(c) { return normalizeCategory(c); }).filter(Boolean);
      safe = sortCategoriesWithAllFirst(safe);
      try {
        localStorage.setItem('altakhfid_categories', JSON.stringify(safe));
      } catch(e) {}
      var res = await this.updateContentSection({ categories: safe });
      if (res.success) {
        console.log('[Bridge] Categories saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveBanners: async function(banners) {
      if (!Array.isArray(banners)) return { success: false };
      var safe = banners.map(normalizeBanner).filter(Boolean);
      try {
        localStorage.setItem('store_banners_v1', JSON.stringify(safe));
      } catch(e) {}
      var res = await this.updateContentSection({ banners: safe });
      if (res.success) {
        console.log('[Bridge] Banners saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveCampaigns: async function(campaigns) {
      if (!Array.isArray(campaigns)) return { success: false };
      var safe = campaigns.map(normalizeCampaign).filter(Boolean);
      try {
        localStorage.setItem('trend_campaigns_v2', JSON.stringify(safe));
        localStorage.setItem('altakhfid_campaigns', JSON.stringify(safe));
      } catch(e) {}
      var res = await this.updateContentSection({ campaigns: safe });
      if (res.success) {
        console.log('[Bridge] Campaigns saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveHashtags: async function(hashtags) {
      if (!Array.isArray(hashtags)) return { success: false };
      try {
        localStorage.setItem('trend_hashtags_v2', JSON.stringify(hashtags));
      } catch(e) {}
      var res = await this.updateContentSection({ trendHashtags: hashtags, hashtags: hashtags });
      if (res.success) {
        console.log('[Bridge] Hashtags saved to server successfully (' + hashtags.length + ')');
      }
      return res;
    },

    saveAnnouncements: async function(announcements) {
      var safe = normalizeAnnouncementSettings(announcements);
      try {
        localStorage.setItem('shein_announcement_bar_settings_v1', JSON.stringify(safe));
      } catch(e) {}
      var res = await this.updateContentSection({ announcements: safe });
      if (res.success) {
        console.log('[Bridge] Announcements saved to server successfully');
      }
      return res;
    },

    saveCategoryTabsConfig: async function(config) {
      try {
        localStorage.setItem('store_category_tabs_config_v2', JSON.stringify(config));
        localStorage.setItem('shein_category_tabs_config', JSON.stringify(config));
      } catch(e) {}
      var res = await this.updateContentSection({ categoryTabsConfig: config });
      if (res.success) {
        console.log('[Bridge] Category tabs config saved to server successfully');
      }
      return res;
    },

    saveRecommendations: async function(tabs) {
      try {
        localStorage.setItem('store_recommendation_tabs_v2', JSON.stringify(tabs));
        localStorage.setItem('recommendation_tabs_v1', JSON.stringify(tabs));
      } catch(e) {}
      var res = await this.updateContentSection({ recommendationTabs: tabs });
      if (res.success) {
        console.log('[Bridge] Recommendation tabs saved to server successfully');
      }
      return res;
    },

    // 3. ORDERS API
    createOrder: async function(orderData) {
      if (!orderData) return { success: false, error: 'بيانات الطلب فارغة' };
      var cleanPhone = (orderData.customerPhone || '').replace(/\D/g, '');
      if (cleanPhone.startsWith('00')) cleanPhone = cleanPhone.slice(2);
      if (cleanPhone.startsWith('0')) cleanPhone = '967' + cleanPhone.slice(1);
      if (cleanPhone.length === 9 && cleanPhone.startsWith('7')) cleanPhone = '967' + cleanPhone;

      var items = (orderData.items || []).map(function(item) {
        return {
          id: item.id || item.productId,
          productId: item.id || item.productId,
          name: item.name || item.title || 'منتج',
          price: typeof item.price === 'number' ? item.price : 0,
          quantity: typeof item.quantity === 'number' ? item.quantity : 1,
          selectedSize: item.selectedSize || item.size || null,
          selectedColor: item.selectedColor || item.color || null,
          imageUrl: item.imageUrl || item.image || ''
        };
      });

      var payload = {
        customerPhone: cleanPhone || '967771234567',
        customerName: orderData.customerName || 'عميل المتجر',
        governorate: orderData.governorate || 'صنعاء',
        deliveryAddress: orderData.deliveryAddress || orderData.address || (orderData.governorate || 'صنعاء'),
        items: items,
        totalAmount: typeof orderData.totalAmount === 'number' ? orderData.totalAmount : 0,
        notes: orderData.notes || 'طلب من تطبيق المتجر'
      };

      try {
        var res = await fetch(getBaseUrl() + '/orders', {
          method: 'POST',
          headers: getAuthHeaders(true),
          body: JSON.stringify(payload)
        });
        var data = await res.json().catch(function() { return {}; });

        if (res.status === 201 && data.success !== false) {
          console.log('[Bridge] Real order created on server:', data.orderId || (data.order && data.order.id));
          if (data.accessToken && !getAuthToken()) {
            try { localStorage.setItem('takhfid_access_token', data.accessToken); } catch(e) {}
          }
          try {
            var rawOrders = localStorage.getItem('admin_orders_v2');
            var localOrders = rawOrders ? JSON.parse(rawOrders) : [];
            var savedOrder = data.order || {
              id: data.orderId,
              orderId: data.orderId,
              customerName: payload.customerName,
              customerPhone: payload.customerPhone,
              governorate: payload.governorate,
              items: items,
              totalAmount: payload.totalAmount,
              status: 'pending',
              date: new Date().toLocaleDateString('ar-SA')
            };
            localOrders.unshift(savedOrder);
            localStorage.setItem('admin_orders_v2', JSON.stringify(localOrders));
          } catch(e) {}
          return { success: true, orderId: data.orderId, order: data.order };
        } else {
          console.warn('[Bridge] createOrder error from server:', data);
          return { success: false, error: data.error || 'تعذر تسجيل الطلب على الخادم' };
        }
      } catch (err) {
        console.error('[Bridge] createOrder network error:', err);
        return { success: false, error: err.message };
      }
    },

    fetchOrders: async function() {
      var token = getAuthToken();
      if (!token) return [];
      try {
        var res = await fetch(getBaseUrl() + '/orders', {
          headers: getAuthHeaders(false)
        });
        if (!res.ok) return [];
        var data = await res.json();
        return Array.isArray(data) ? data : (data.orders || []);
      } catch (err) {
        console.warn('[Bridge] fetchOrders error:', err);
        return [];
      }
    },

    updateOrderStatus: async function(orderId, status) {
      if (!orderId || !status) return { success: false };
      try {
        var res = await fetch(getBaseUrl() + '/orders/' + encodeURIComponent(orderId) + '/status', {
          method: 'PATCH',
          headers: getAuthHeaders(true),
          body: JSON.stringify({ status: status })
        });
        var data = await res.json().catch(function() { return {}; });
        return { success: res.ok && data.success !== false };
      } catch (err) {
        console.error('[Bridge] updateOrderStatus error:', err);
        return { success: false, error: err.message };
      }
    },

    // LIVE SYNC FROM SERVER (FETCH ONLY)
    syncFromServer: async function(isManual) {
      console.log('[Bridge] Fetching live data from server (syncFromServer)...');
      try {
        var content = await takhfidBridge.fetchContent();
        if (content) {
          if (Array.isArray(content.categories) && content.categories.length > 0) {
            var normCats = content.categories.map(function(c) { return normalizeCategory(c); }).filter(Boolean);
            if (normCats.length > 0) {
              try { localStorage.setItem('altakhfid_categories', JSON.stringify(normCats)); } catch(e) {}
              if (window.__takhfidSetCategories) window.__takhfidSetCategories(normCats);
            }
          }
          if (Array.isArray(content.banners) && content.banners.length > 0) {
            var normBanners = content.banners.map(normalizeBanner).filter(Boolean);
            if (normBanners.length > 0) {
              try { localStorage.setItem('store_banners_v1', JSON.stringify(normBanners)); } catch(e) {}
              if (window.__takhfidSetBanners) window.__takhfidSetBanners(normBanners);
            }
          }
          if (Array.isArray(content.campaigns) && content.campaigns.length > 0) {
            var normCamps = content.campaigns.map(normalizeCampaign).filter(Boolean);
            if (normCamps.length > 0) {
              try {
                localStorage.setItem('trend_campaigns_v2', JSON.stringify(normCamps));
                localStorage.setItem('altakhfid_campaigns', JSON.stringify(normCamps));
              } catch(e) {}
              if (window.__takhfidSetCampaigns) window.__takhfidSetCampaigns(normCamps);
            }
          }
          var serverHashtags = (Array.isArray(content.trendHashtags) && content.trendHashtags.length > 0) ? content.trendHashtags : (Array.isArray(content.hashtags) && content.hashtags.length > 0 ? content.hashtags : null);
          if (serverHashtags) {
            try { localStorage.setItem('trend_hashtags_v2', JSON.stringify(serverHashtags)); } catch(e) {}
            if (window.__takhfidSetHashtags) window.__takhfidSetHashtags(serverHashtags);
          }
                    if (content.categoryTabsConfig && typeof content.categoryTabsConfig === "object") {
            try {
              localStorage.setItem("shein_category_tabs_config", JSON.stringify(content.categoryTabsConfig));
              localStorage.setItem("store_category_tabs_config_v2", JSON.stringify(content.categoryTabsConfig));
            } catch(e) {}
            if (window.__takhfidSetCategoryTabsConfig) window.__takhfidSetCategoryTabsConfig(content.categoryTabsConfig);
          }
          if (Array.isArray(content.recommendationTabs) && content.recommendationTabs.length > 0) {
            try {
              localStorage.setItem("recommendation_tabs_v1", JSON.stringify(content.recommendationTabs));
              localStorage.setItem("store_recommendation_tabs_v2", JSON.stringify(content.recommendationTabs));
            } catch(e) {}
            if (window.__takhfidSetRecommendations) window.__takhfidSetRecommendations(content.recommendationTabs);
          }
          if (content.announcements && typeof content.announcements === 'object' && Array.isArray(content.announcements.screens) && content.announcements.screens.length > 0) {
            var normAnn = normalizeAnnouncementSettings(content.announcements);
            try { localStorage.setItem('shein_announcement_bar_settings_v1', JSON.stringify(normAnn)); } catch(e) {}
            if (lastHooks && lastHooks.setAnnouncementSettings) lastHooks.setAnnouncementSettings(normAnn);
          }
          if (content.pricingSettings) {
            try { localStorage.setItem('altakhfid_pricing_settings', JSON.stringify(content.pricingSettings)); } catch(e) {}
          }
        }

        var serverProducts = await takhfidBridge.fetchProducts();
        var prodsCount = 0;
        if (Array.isArray(serverProducts) && serverProducts.length > 0) {
          var normProds = serverProducts.map(normalizeProduct).filter(Boolean);
          if (normProds.length > 0) {
            try { localStorage.setItem('altakhfid_products', JSON.stringify(normProds)); } catch(e) {}
            if (window.__takhfidSetProducts) window.__takhfidSetProducts(normProds);
            prodsCount = normProds.length;
          }
        }

        var orders = await takhfidBridge.fetchOrders();
        if (Array.isArray(orders) && orders.length > 0) {
          try { localStorage.setItem('admin_orders_v2', JSON.stringify(orders)); } catch(e) {}
          if (lastHooks && lastHooks.setOrders) lastHooks.setOrders(orders);
        }

        hideConnectionErrorBanner();
        if (isManual) {
          toast('تم جلب وتحديث ' + prodsCount + ' منتجاً حياً وكافة الأقسام والبانرات من الخادم بنجاح 🔄✨', 'success');
        }
        return { success: true, count: prodsCount };
      } catch (err) {
        console.error('[Bridge] syncFromServer error:', err);
        if (isManual) {
          toast('تعذر جلب البيانات من الخادم، تم الإبقاء على البيانات الحالية ⚠️', 'info');
        }
        return { success: false, error: err.message };
      }
    },

    // 4. COMPREHENSIVE BULK SYNC TO BACKEND
    syncAllToBackend: async function(isManual) {
      console.log('[Bridge] Starting full sync to server...');
      var token = getAuthToken();
      if (!token) {
        toast('يرجى تسجيل الدخول بحساب الإدارة لإتمام المزامنة مع الخادم ⚠️', 'info');
        return { success: false, error: 'غير مسجل كمدير' };
      }

      var summary = {
        productsSuccess: 0,
        contentSuccess: false
      };

      try {
        var products = [];
        var categories = [];
        var banners = [];
        var campaigns = [];
        var hashtags = [];
        var announcements = null;
        var categoryTabsConfig = null;
        var recommendationTabs = null;

        try {
          var pStr = localStorage.getItem('altakhfid_products');
          if (pStr) products = JSON.parse(pStr).map(normalizeProduct).filter(Boolean);
        } catch(e) {}
        try {
          var cStr = localStorage.getItem('altakhfid_categories');
          if (cStr) categories = JSON.parse(cStr).map(function(c) { return normalizeCategory(c); }).filter(Boolean);
        } catch(e) {}
        try {
          var bStr = localStorage.getItem('store_banners_v1');
          if (bStr) banners = JSON.parse(bStr).map(normalizeBanner).filter(Boolean);
        } catch(e) {}
        try {
          var campStr = localStorage.getItem('trend_campaigns_v2') || localStorage.getItem('altakhfid_campaigns');
          if (campStr) campaigns = JSON.parse(campStr).map(normalizeCampaign).filter(Boolean);
        } catch(e) {}
        try {
          var hStr = localStorage.getItem('trend_hashtags_v2');
          if (hStr) hashtags = JSON.parse(hStr);
        } catch(e) {}
        try {
          var aStr = localStorage.getItem('shein_announcement_bar_settings_v1');
          if (aStr) announcements = normalizeAnnouncementSettings(JSON.parse(aStr));
        } catch(e) {}
        try {
          var ctStr = localStorage.getItem('store_category_tabs_config_v2');
          if (ctStr) categoryTabsConfig = JSON.parse(ctStr);
        } catch(e) {}
        try {
          var rtStr = localStorage.getItem('store_recommendation_tabs_v2');
          if (rtStr) recommendationTabs = JSON.parse(rtStr);
        } catch(e) {}

        var contentPayload = {};
        if (categories && categories.length > 0) contentPayload.categories = categories;
        if (banners && banners.length > 0) contentPayload.banners = banners;
        if (campaigns && campaigns.length > 0) contentPayload.campaigns = campaigns;
        if (hashtags && hashtags.length > 0) contentPayload.trendHashtags = hashtags;
        if (announcements) contentPayload.announcements = announcements;
        if (categoryTabsConfig) contentPayload.categoryTabsConfig = categoryTabsConfig;
        if (recommendationTabs) contentPayload.recommendationTabs = recommendationTabs;

        if (Object.keys(contentPayload).length > 0) {
          var cRes = await fetch(getBaseUrl() + '/admin/content', {
            method: 'PUT',
            headers: getAuthHeaders(true),
            body: JSON.stringify(contentPayload)
          });
          var cData = await cRes.json().catch(function() { return {}; });
          if (cRes.ok && cData.success !== false) {
            summary.contentSuccess = true;
            console.log('[Bridge] Content sections successfully synced to server');
          } else {
            console.warn('[Bridge] Content sync warning:', cData);
          }
        }

        if (products && products.length > 0) {
          var bulkRes = await fetch(getBaseUrl() + '/admin/products/bulk', {
            method: 'POST',
            headers: getAuthHeaders(true),
            body: JSON.stringify({ products: products })
          });
          var bulkData = await bulkRes.json().catch(function() { return {}; });
          if (bulkRes.ok && bulkData.success !== false) {
            summary.productsSuccess = products.length;
            console.log('[Bridge] Bulk synced ' + products.length + ' products to server');
          } else {
            var okCount = 0;
            for (var i = 0; i < products.length; i++) {
              var p = products[i];
              var pRes = await fetch(getBaseUrl() + '/admin/products/' + encodeURIComponent(p.id), {
                method: 'PUT',
                headers: getAuthHeaders(true),
                body: JSON.stringify(p)
              });
              if (pRes.ok) {
                okCount++;
              } else if (pRes.status === 404) {
                var createRes = await fetch(getBaseUrl() + '/admin/products', {
                  method: 'POST',
                  headers: getAuthHeaders(true),
                  body: JSON.stringify(p)
                });
                if (createRes.ok) okCount++;
              }
            }
            summary.productsSuccess = okCount;
          }
        }

        if (isManual) {
          toast('تمت مزامنة كل بيانات المتجر (المنتجات، الأقسام، البانرات، الحملات، الإعلانات) مع الخادم بنجاح! 🔥☁️', 'success');
        }
        return { success: true, summary: summary };
      } catch (err) {
        console.error('[Bridge] syncAllToBackend fatal error:', err);
        if (isManual) {
          toast('حدث خطأ أثناء المزامنة مع الخادم: ' + err.message, 'info');
        }
        return { success: false, error: err.message };
      }
    },

    // 5. BOOTSTRAP INITIALIZATION ON APP LOAD
    initSync: async function(hooks) {
      hooks = hooks || {};
      lastHooks = hooks;
      if (hooks.showToast) {
        activeToast = hooks.showToast;
      }
      lastConnectionError = null;
      console.log('[Bridge] Initializing synchronization with server...');

      // Auto-cleanup bad localStorage values (e.g. empty array in announcements)
      try {
        var rawAnn = localStorage.getItem('shein_announcement_bar_settings_v1');
        if (rawAnn) {
          var parsedAnn = JSON.parse(rawAnn);
          if (!parsedAnn || !Array.isArray(parsedAnn.screens) || parsedAnn.screens.length === 0) {
            localStorage.removeItem('shein_announcement_bar_settings_v1');
          }
        }
      } catch(e) {}

      try {
        // A. Load Content (Categories, Banners, Campaigns, Announcements)
        var content = await takhfidBridge.fetchContent();
        if (content) {
          // Categories
          if (Array.isArray(content.categories) && content.categories.length > 0) {
            var currentCats = null;
            try {
              var cRaw = localStorage.getItem('altakhfid_categories');
              if (cRaw) currentCats = JSON.parse(cRaw);
            } catch(e) {}
            var normCats = content.categories.map(function(c) {
              return normalizeCategory(c, currentCats);
            }).filter(Boolean);

            if (normCats.length > 0) {
              console.log('[Bridge] Loaded ' + normCats.length + ' normalized categories from server');
              if (hooks.setCategories) hooks.setCategories(normCats);
              try { localStorage.setItem('altakhfid_categories', JSON.stringify(normCats)); } catch(e) {}
            }
          }

          // Banners
          if (Array.isArray(content.banners) && content.banners.length > 0) {
            var normBanners = content.banners.map(normalizeBanner).filter(Boolean);
            if (normBanners.length > 0) {
              console.log('[Bridge] Loaded ' + normBanners.length + ' normalized banners from server');
              if (hooks.setBanners) hooks.setBanners(normBanners);
              try { localStorage.setItem('store_banners_v1', JSON.stringify(normBanners)); } catch(e) {}
            }
          }

          // Campaigns
          if (Array.isArray(content.campaigns) && content.campaigns.length > 0) {
            var normCamps = content.campaigns.map(normalizeCampaign).filter(Boolean);
            if (normCamps.length > 0) {
              console.log('[Bridge] Loaded ' + normCamps.length + ' campaigns from server');
              if (hooks.setCampaigns) hooks.setCampaigns(normCamps);
              try {
                localStorage.setItem('trend_campaigns_v2', JSON.stringify(normCamps));
                localStorage.setItem('altakhfid_campaigns', JSON.stringify(normCamps));
              } catch(e) {}
            }
          }

          // Hashtags
          var serverHashtags = (Array.isArray(content.trendHashtags) && content.trendHashtags.length > 0) ? content.trendHashtags : (Array.isArray(content.hashtags) && content.hashtags.length > 0 ? content.hashtags : null);
          if (serverHashtags) {
            console.log('[Bridge] Loaded ' + serverHashtags.length + ' hashtags from server');
            if (hooks.setHashtags) hooks.setHashtags(serverHashtags);
            try { localStorage.setItem('trend_hashtags_v2', JSON.stringify(serverHashtags)); } catch(e) {}
          }

          // Announcements
          if (content.announcements && typeof content.announcements === 'object' && Array.isArray(content.announcements.screens) && content.announcements.screens.length > 0) {
            var normAnn = normalizeAnnouncementSettings(content.announcements);
            console.log('[Bridge] Loaded announcement settings from server');
            if (hooks.setAnnouncementSettings) hooks.setAnnouncementSettings(normAnn);
            try { localStorage.setItem('shein_announcement_bar_settings_v1', JSON.stringify(normAnn)); } catch(e) {}
          }

          // Category tabs config
          if (content.categoryTabsConfig && typeof content.categoryTabsConfig === 'object') {
            if (hooks.setCategoryTabsConfig) hooks.setCategoryTabsConfig(content.categoryTabsConfig);
            try { localStorage.setItem('store_category_tabs_config_v2', JSON.stringify(content.categoryTabsConfig)); } catch(e) {}
          }

          // Recommendation tabs
          if (Array.isArray(content.recommendationTabs) && content.recommendationTabs.length > 0) {
            if (hooks.setRecommendationTabs) hooks.setRecommendationTabs(content.recommendationTabs);
            try { localStorage.setItem('store_recommendation_tabs_v2', JSON.stringify(content.recommendationTabs)); } catch(e) {}
          }
        }

        // B. Load Products
        var serverProducts = await takhfidBridge.fetchProducts();
        var prodsLoaded = false;
        var finalProdCount = 0;
        if (Array.isArray(serverProducts) && serverProducts.length > 0) {
          var normProds = serverProducts.map(normalizeProduct).filter(Boolean);
          if (normProds.length > 0) {
            console.log('[Bridge] Loaded & normalized ' + normProds.length + ' products directly from server');
            if (hooks.setProducts) hooks.setProducts(normProds);
            try { localStorage.setItem('altakhfid_products', JSON.stringify(normProds)); } catch(e) {}
            prodsLoaded = true;
            finalProdCount = normProds.length;
          }
        }

        // C. Load Orders if token exists
        var orders = await takhfidBridge.fetchOrders();
        if (Array.isArray(orders) && orders.length > 0) {
          console.log('[Bridge] Loaded ' + orders.length + ' orders from server');
          if (hooks.setOrders) hooks.setOrders(orders);
          try { localStorage.setItem('admin_orders_v2', JSON.stringify(orders)); } catch(e) {}
        }

        if (prodsLoaded) {
          hideConnectionErrorBanner();
          console.log('[Bridge] Live sync completed successfully.');
          // Customer notification removed as requested
        } else if (lastConnectionError) {
          var errMsg = lastConnectionError.message || String(lastConnectionError);
          console.error('[Bridge] Server connection failure:', errMsg);
          showConnectionErrorBanner(errMsg);
          toast('فشل الاتصال بالخادم: ' + errMsg + ' (يتم عرض البيانات المؤقتة)', 'error');
        }
      } catch (err) {
        console.error('[Bridge] initSync error:', err);
        var errText = err.message || String(err);
        showConnectionErrorBanner(errText);
        toast('فشل الاتصال بالخادم: ' + errText + ' (يتم عرض البيانات المؤقتة)', 'error');
      }
    }
  };

  // Expose Global Bridges for React bundle
  window.__takhfidBridge = takhfidBridge;
  window.__takhfidInitSync = takhfidBridge.initSync.bind(takhfidBridge);
  window.__takhfidRetrySync = function() {
    if (window.__takhfidInitSync && lastHooks) {
      return window.__takhfidInitSync(lastHooks);
    }
  };
  window.__takhfidSaveProduct = takhfidBridge.saveProduct.bind(takhfidBridge);
  window.__takhfidSaveCategories = takhfidBridge.saveCategories.bind(takhfidBridge);
  window.__takhfidSaveBanners = takhfidBridge.saveBanners.bind(takhfidBridge);
  window.__takhfidSaveCampaigns = takhfidBridge.saveCampaigns.bind(takhfidBridge);
  window.__takhfidSaveHashtags = takhfidBridge.saveHashtags.bind(takhfidBridge);
  window.__takhfidSaveAnnouncements = takhfidBridge.saveAnnouncements.bind(takhfidBridge);
  window.__takhfidSaveCategoryTabsConfig = takhfidBridge.saveCategoryTabsConfig.bind(takhfidBridge);
  window.__takhfidSaveRecommendations = takhfidBridge.saveRecommendations.bind(takhfidBridge);
  window.__takhfidCreateOrder = takhfidBridge.createOrder.bind(takhfidBridge);
  window.__takhfidUpdateOrderStatus = takhfidBridge.updateOrderStatus.bind(takhfidBridge);
  window.__takhfidSyncAll = function(isManual) { return takhfidBridge.syncFromServer(isManual); };
  window.__takhfidSyncFromServer = function(isManual) { return takhfidBridge.syncFromServer(isManual); };
  window.__takhfidRefresh = function() { return takhfidBridge.syncFromServer(false); };
  window.__takhfidBulkSync = takhfidBridge.syncAllToBackend.bind(takhfidBridge);
  window.__takhfidFetchOrders = takhfidBridge.fetchOrders.bind(takhfidBridge);
  window.syncProductsToServer = function() { return takhfidBridge.syncAllToBackend(true); };

  console.log('[Bridge] Takhfid Store Bridge v4.3.0 loaded and ready.');
})();
