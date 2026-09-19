  // --- SAFE DATA NORMALIZATION ---
  function finiteNumber(value, fallback) {
    var n = Number(value);
    return Number.isFinite(n) ? n : (fallback || 0);
  }

  function baseSarFromProduct(p, fallbackPrice) {
    var currency = String(p && p.inputCurrency || '').toUpperCase();
    var baseSar = finiteNumber(p && p.basePriceSar, NaN);
    if (Number.isFinite(baseSar) && baseSar > 0) return baseSar;

    var raw = finiteNumber(fallbackPrice, 0);
    if (currency === 'YER' && finiteNumber(p && p.baseNorthPriceYer, 0) > 0) {
      return finiteNumber(p.baseNorthPriceYer, 0) / 140;
    }
    if (currency === 'USD') {
      return raw * 3.75;
    }
    return raw;
  }

  function normalizeProduct(p) {
    if (!p) return null;
    var res = Object.assign({}, p);

    var originalRaw = finiteNumber(p.originalPrice, finiteNumber(p.price, 0));
    var discountRaw = finiteNumber(p.discountPrice, finiteNumber(p.price, originalRaw));
    var origSar = baseSarFromProduct(p, originalRaw);
    var discSar = baseSarFromProduct(p, discountRaw);

    if (!Number.isFinite(origSar) || origSar < 0) origSar = 0;
    if (!Number.isFinite(discSar) || discSar < 0) discSar = 0;
    if (origSar > 0 && discSar > origSar) origSar = discSar;

    var discPerc = Number.isFinite(Number(p.discountPercentage))
      ? finiteNumber(p.discountPercentage, 0)
      : (origSar > discSar && origSar > 0 ? Math.round(((origSar - discSar) / origSar) * 100) : 0);

    var cat = p.category || (Array.isArray(p.categories) && p.categories[1] ? p.categories[1] : 'women');
    var cats = Array.isArray(p.categories) && p.categories.length > 0 ? p.categories : ['all', cat];

    var img = p.image || (Array.isArray(p.images) && p.images[0]) || (Array.isArray(p.galleryImages) && p.galleryImages[0]) || '';
    var gallery = Array.isArray(p.galleryImages) && p.galleryImages.length > 0
      ? p.galleryImages
      : (Array.isArray(p.images) && p.images.length > 0 ? p.images : (img ? [img] : []));

    var colors = Array.isArray(p.colors) ? p.colors.map(function(color) {
      if (typeof color === 'string') return { name: color, hex: '#1e293b', images: img ? [img] : [] };
      var imgs = Array.isArray(color && color.images) && color.images.length
        ? color.images
        : (color && color.image ? [color.image] : (img ? [img] : []));
      return {
        name: String(color && color.name || 'لون'),
        hex: String(color && color.hex || '#1e293b'),
        image: imgs[0] || '',
        images: imgs
      };
    }) : [];

    var sizes = Array.isArray(p.sizes) ? p.sizes : [];
    var tags = Array.isArray(p.tags) ? p.tags : (p.tags ? [String(p.tags)] : []);
    var trends = Array.isArray(p.trends) ? p.trends : (p.trendTag ? [String(p.trendTag)] : []);
    var hasRating = Number.isFinite(Number(p.rating)) && Number(p.rating) > 0;
    var reviewCount = Number.isFinite(Number(p.reviewsCount)) ? Math.max(0, Number(p.reviewsCount)) : 0;
    var soldCount = Number.isFinite(Number(p.soldCount)) ? Math.max(0, Number(p.soldCount)) : 0;

    res.id = String(p.id || ('p-' + Date.now()));
    res.name = String(p.name || p.title || 'صنف جديد');
    res.nameEn = p.nameEn !== undefined ? String(p.nameEn) : '';
    res.brand = p.brand !== undefined ? String(p.brand) : '';
    res.category = String(cat);
    res.categoryId = String(p.categoryId || cat);
    res.categories = cats;
    res.subCategory = String(p.subCategory || '');
    res.subCategories = Array.isArray(p.subCategories) ? p.subCategories : [];
    res.sideCategories = Array.isArray(p.sideCategories) ? p.sideCategories : [];
    res.sideSubCategories = Array.isArray(p.sideSubCategories) ? p.sideSubCategories : [];
    res.styleTabs = Array.isArray(p.styleTabs) ? p.styleTabs : [];
    res.originalPrice = Number(origSar.toFixed(2));
    res.discountPrice = Number(discSar.toFixed(2));
    res.basePriceSar = Number(discSar.toFixed(2));
    res.baseOriginalPriceSar = Number(origSar.toFixed(2));
    res.baseNorthPriceYer = finiteNumber(p.baseNorthPriceYer, discSar ? Math.round(discSar * 140) : 0);
    res.baseSouthPriceYer = finiteNumber(p.baseSouthPriceYer, discSar ? Math.round(discSar * 535) : 0);
    res.discountPercentage = Math.max(0, Math.min(100, Number(discPerc) || 0));
    res.price = res.discountPrice;
    res.rating = hasRating ? finiteNumber(p.rating, 0) : 0;
    res.reviewsCount = reviewCount;
    res.enableReviews = p.enableReviews !== false && hasRating;
    res.image = String(img);
    res.images = Array.isArray(p.images) ? p.images : gallery;
    res.gallery = gallery;
    res.galleryImages = gallery;
    res.colors = colors;
    res.sizes = sizes;
    res.tags = tags;
    res.trends = trends;
    res.inStock = p.inStock !== false && (p.stock === undefined || p.stock === null || Number(p.stock) > 0);
    res.stock = p.stock !== undefined && p.stock !== null && Number.isFinite(Number(p.stock)) ? Math.max(0, Number(p.stock)) : null;

    // Preserve every modern product customization without inventing fake values.
    res.description = p.description !== undefined ? String(p.description) : '';
    res.material = p.material !== undefined ? String(p.material) : '';
    res.materials = Array.isArray(p.materials) ? p.materials : [];
    res.badgeText = p.badgeText !== undefined ? String(p.badgeText) : '';
    res.trendBadge = p.trendBadge !== undefined ? String(p.trendBadge) : '';
    res.salesText = p.salesText !== undefined ? String(p.salesText) : '';
    res.couponText = p.couponText !== undefined ? String(p.couponText) : '';
    res.campaignRibbonText = p.campaignRibbonText !== undefined ? String(p.campaignRibbonText) : '';
    res.bestSellerText = p.bestSellerText !== undefined ? String(p.bestSellerText) : '';
    res.ratingReviewsText = p.ratingReviewsText !== undefined ? String(p.ratingReviewsText) : '';
    res.cartBadgeCount = Number.isFinite(Number(p.cartBadgeCount)) ? Number(p.cartBadgeCount) : 0;
    res.storeBadgeTag = p.storeBadgeTag !== undefined ? String(p.storeBadgeTag) : '';
    res.productType = p.productType !== undefined ? String(p.productType) : '';
    res.fabric = p.fabric !== undefined ? String(p.fabric) : '';
    res.ageGroup = p.ageGroup !== undefined ? String(p.ageGroup) : '';
    res.details = Array.isArray(p.details) ? p.details : [];
    res.isRecommended = Boolean(p.isRecommended);
    res.isMostPopular = Boolean(p.isMostPopular);
    res.isBestSeller = Boolean(p.isBestSeller);
    res.isTrend = Boolean(p.isTrend || trends.length > 0);
    res.isLocalFastShipping = Boolean(p.isLocalFastShipping);
    res.hasCurveLogo = Boolean(p.hasCurveLogo);
    res.stretchInfo = p.stretchInfo !== undefined ? String(p.stretchInfo) : '';
    res.hasZoomInBubble = Boolean(p.hasZoomInBubble);
    res.zoomBubbleImage = p.zoomBubbleImage !== undefined ? String(p.zoomBubbleImage) : '';
    res.cardAspect = p.cardAspect || 'tall';
    res.sku = p.sku ? String(p.sku) : '';
    res.soldCount = soldCount;

    res.isNewBadgeEnabled = p.isNewBadgeEnabled === true;
    res.newBadgeText = p.newBadgeText !== undefined ? String(p.newBadgeText) : '';
    res.newBadgeTextColor = p.newBadgeTextColor || '#ffffff';
    res.newBadgeBgColor = p.newBadgeBgColor || '#10b981';
    res.newBadgeDurationDays = finiteNumber(p.newBadgeDurationDays, 7);

    res.hasCoupon = p.hasCoupon === true;
    res.couponDiscountType = p.couponDiscountType || 'percentage';
    res.couponDiscountValue = finiteNumber(p.couponDiscountValue, 0);
    res.couponMaxCap = Number.isFinite(Number(p.couponMaxCap)) ? Number(p.couponMaxCap) : null;
    res.couponCustomLabel = p.couponCustomLabel !== undefined ? String(p.couponCustomLabel) : '';
    res.hasPromotionalTiers = Boolean(p.hasPromotionalTiers);
    res.promotionalTiersText = p.promotionalTiersText !== undefined ? String(p.promotionalTiersText) : '';
    res.hasCouponPriceCustomStyle = p.hasCouponPriceCustomStyle === true;
    res.couponPriceBgColor = p.couponPriceBgColor || '#fff1f2';
    res.couponPriceTextColor = p.couponPriceTextColor || '#e11d48';
    res.couponPriceDividerColor = p.couponPriceDividerColor || '#f43f5e';

    res.isSavingBannerEnabled = p.isSavingBannerEnabled === true;
    res.savingBannerPrefix = p.savingBannerPrefix !== undefined ? String(p.savingBannerPrefix) : '';
    res.savingBannerLeftText = p.savingBannerLeftText !== undefined ? String(p.savingBannerLeftText) : '';
    res.savingBannerBgColor = p.savingBannerBgColor || 'rgba(0, 0, 0, 0.78)';
    res.savingBannerTextColor = p.savingBannerTextColor || '#ffffff';
    res.savingBannerPriceColor = p.savingBannerPriceColor || '#facc15';

    res.showCardShipping = p.showCardShipping === true;
    res.cardShippingText = p.cardShippingText !== undefined ? String(p.cardShippingText) : '';
    
    res.floatingLogos = p.floatingLogos && typeof p.floatingLogos === 'object' ? p.floatingLogos : undefined;
    res.modelWearInfo = p.modelWearInfo && typeof p.modelWearInfo === 'object' ? p.modelWearInfo : undefined;
    res.customInfoItems = Array.isArray(p.customInfoItems) ? p.customInfoItems : [];
    res.campaignIds = Array.isArray(p.campaignIds) ? p.campaignIds : [];
    res.department = p.department !== undefined ? String(p.department) : '';
    res.inputCurrency = p.inputCurrency || 'SAR';
    res.videoUrl = p.videoUrl || '';
    res.washingInstructions = p.washingInstructions !== undefined ? String(p.washingInstructions) : '';
    res.tags = tags;
    res.hashtags = tags;

    return res;
  }

  function normalizeOrder(order) {
    if (!order) return null;
    var rawItems = Array.isArray(order.items) ? order.items : [];
    var items = rawItems.map(function(item, index) {
      var p = item && item.product ? item.product : {
        id: item && (item.productId || item.id) || ('order-product-' + index),
        name: item && (item.name || item.title) || 'منتج غير متوفر',
        sku: item && item.sku || '',
        price: finiteNumber(item && item.price, 0),
        discountPrice: finiteNumber(item && item.price, 0),
        image: item && (item.imageUrl || item.image) || ''
      };
      return Object.assign({}, item || {}, {
        id: String(item && (item.id || item.productId) || p.id || ('item-' + index)),
        productId: String(item && (item.productId || item.id) || p.id || ('item-' + index)),
        quantity: Math.max(1, Math.round(finiteNumber(item && item.quantity, 1))),
        selectedSize: item && item.selectedSize || item && item.size || '',
        selectedColor: item && item.selectedColor || item && item.color || null,
        product: normalizeProduct(p)
      });
    });
    return Object.assign({}, order, {
      id: String(order.id || order.orderId || ('order-' + Date.now())),
      orderId: String(order.orderId || order.id || ''),
      customerName: String(order.customerName || 'عميل المتجر'),
      customerPhone: String(order.customerPhone || ''),
      governorate: String(order.governorate || 'صنعاء'),
      shippingAddress: String(order.shippingAddress || order.deliveryAddress || ''),
      deliveryNotes: String(order.deliveryNotes || order.notes || ''),
      totalAmount: finiteNumber(order.totalAmount, 0),
      items: items,
      status: String(order.status || 'pending_payment')
    });
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
        var res = await serverFetch(url, {
          method: method,
          headers: getAuthHeaders(true),
          body: act === 'delete' ? undefined : JSON.stringify(safeProd)
        });
        var data = await res.json().catch(function() { return {}; });
        if (!res.ok || data.success === false) {
          return { success: false, error: data.error || ('HTTP ' + res.status) };
        }
        return { success: true, product: Object.assign({}, safeProd, data.product || {}) };
      } catch (err) {
        return { success: false, error: err.message || String(err) };
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
        return { success: false, error: 'جلسة الإدارة غير مفعلة. سجّل الدخول أولاً.' };
      }
      try {
        var res = await serverFetch(getBaseUrl() + '/admin/content', {
          method: 'PUT',
          headers: getAuthHeaders(true),
          body: JSON.stringify(payload)
        });
        var data = await res.json().catch(function() { return {}; });
        if (res.ok && data.success !== false) return { success: true, data: data };

        var r2 = await serverFetch(DIRECT_REMOTE_BASE + '/admin/content', {
          method: 'PUT',
          headers: getAuthHeaders(true),
          body: JSON.stringify(payload)
        });
        var d2 = await r2.json().catch(function() { return {}; });
        if (!r2.ok || d2.success === false) {
          return { success: false, error: d2.error || ('HTTP ' + r2.status) };
        }
        return { success: true, data: d2 };
      } catch (err) {
        try {
          var r3 = await serverFetch(DIRECT_REMOTE_BASE + '/admin/content', {
            method: 'PUT',
            headers: getAuthHeaders(true),
            body: JSON.stringify(payload)
          });
          var d3 = await r3.json().catch(function() { return {}; });
          if (!r3.ok || d3.success === false) {
            return { success: false, error: d3.error || ('HTTP ' + r3.status) };
          }
          return { success: true, data: d3 };
        } catch (e2) {
          return { success: false, error: e2.message || String(e2) };
        }
      }
    },

    saveCategories: async function(categories) {
      if (!Array.isArray(categories)) return { success: false };
      var safe = categories.map(function(c) { return normalizeCategory(c); }).filter(Boolean);
      var res = await this.updateContentSection({ categories: safe });
      if (res.success) {
        try { localStorage.setItem('altakhfid_categories', JSON.stringify(safe)); } catch(e) {}
        console.log('[Bridge] Categories saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveBanners: async function(banners) {
      if (!Array.isArray(banners)) return { success: false };
      var safe = banners.map(normalizeBanner).filter(Boolean);
      var res = await this.updateContentSection({ banners: safe });
      if (res.success) {
        try { localStorage.setItem('store_banners_v1', JSON.stringify(safe)); } catch(e) {}
        console.log('[Bridge] Banners saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveCampaigns: async function(campaigns) {
      if (!Array.isArray(campaigns)) return { success: false };
      var safe = campaigns.map(normalizeCampaign).filter(Boolean);
      var res = await this.updateContentSection({ campaigns: safe });
      if (res.success) {
        try {
          localStorage.setItem('trend_campaigns_v2', JSON.stringify(safe));
          localStorage.setItem('altakhfid_campaigns', JSON.stringify(safe));
        } catch(e) {}
        console.log('[Bridge] Campaigns saved to server successfully (' + safe.length + ')');
      }
      return res;
    },

    saveHashtags: async function(hashtags) {
      if (!Array.isArray(hashtags)) return { success: false };
      var res = await this.updateContentSection({ trendHashtags: hashtags, hashtags: hashtags });
      if (res.success) {
        try { localStorage.setItem('trend_hashtags_v2', JSON.stringify(hashtags)); } catch(e) {}
        console.log('[Bridge] Hashtags saved to server successfully (' + hashtags.length + ')');
      }
      return res;
    },

    saveAnnouncements: async function(announcements) {
      var safe = normalizeAnnouncementSettings(announcements);
      var res = await this.updateContentSection({ announcements: safe });
      if (res.success) {
        try { localStorage.setItem('shein_announcement_bar_settings_v1', JSON.stringify(safe)); } catch(e) {}
        console.log('[Bridge] Announcements saved to server successfully');
      }
      return res;
    },

    saveCategoryTabsConfig: async function(config) {
      var res = await this.updateContentSection({ categoryTabsConfig: config });
      if (res.success) {
        try { localStorage.setItem('store_category_tabs_config_v2', JSON.stringify(config)); } catch(e) {}
        console.log('[Bridge] Category tabs config saved to server successfully');
      }
      return res;
    },

    saveRecommendations: async function(tabs) {
      var res = await this.updateContentSection({ recommendationTabs: tabs });
      if (res.success) {
        try { localStorage.setItem('store_recommendation_tabs_v2', JSON.stringify(tabs)); } catch(e) {}
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
        var res = await serverFetch(getBaseUrl() + '/orders', {
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
        var res = await serverFetch(getBaseUrl() + '/orders', {
          headers: getAuthHeaders(false)
        });
        if (!res.ok) {
          throw new Error('HTTP ' + res.status);
        }
        var data = await res.json();
        var raw = Array.isArray(data) ? data : (data.orders || []);
        return raw.map(normalizeOrder).filter(Boolean);
      } catch (err) {
        lastConnectionError = err;
        console.warn('[Bridge] fetchOrders error:', err);
        return [];
      }
    },

    updateOrderStatus: async function(orderId, status) {
      if (!orderId || !status) return { success: false };
      try {
        var res = await serverFetch(getBaseUrl() + '/orders/' + encodeURIComponent(orderId) + '/status', {
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

    updateOrderAddress: async function(orderId, shippingAddress, deliveryNotes) {
      if (!orderId) return { success: false, error: 'معرف الطلب غير موجود' };
      try {
        var res = await serverFetch(getBaseUrl() + '/orders/' + encodeURIComponent(orderId), {
          method: 'PUT',
          headers: getAuthHeaders(true),
          body: JSON.stringify({
            shippingAddress: shippingAddress || '',
            deliveryNotes: deliveryNotes || ''
          })
        });
        var data = await res.json().catch(function() { return {}; });
        if (!res.ok || data.success === false) {
          return { success: false, error: data.error || ('HTTP ' + res.status) };
        }
        return { success: true, order: data.order || null };
      } catch (err) {
        console.error('[Bridge] updateOrderAddress error:', err);
        return { success: false, error: err.message || String(err) };
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

    // LIVE SERVER REFRESH — server is authoritative
    syncFromServer: async function(isManual) {
      try {
        var content = await takhfidBridge.fetchContent();
        if (content) {
          if (Array.isArray(content.categories)) {
            var cats = content.categories.map(function(c) { return normalizeCategory(c); }).filter(Boolean);
            if (lastHooks && lastHooks.setCategories) lastHooks.setCategories(cats);
            try { localStorage.setItem('altakhfid_categories', JSON.stringify(cats)); } catch(e) {}
          }
          if (Array.isArray(content.banners)) {
            var banners = content.banners.map(normalizeBanner).filter(Boolean);
            if (lastHooks && lastHooks.setBanners) lastHooks.setBanners(banners);
            try { localStorage.setItem('store_banners_v1', JSON.stringify(banners)); } catch(e) {}
          }
          if (Array.isArray(content.campaigns)) {
            var campaigns = content.campaigns.map(normalizeCampaign).filter(Boolean);
            if (lastHooks && lastHooks.setCampaigns) lastHooks.setCampaigns(campaigns);
            try {
              localStorage.setItem('trend_campaigns_v2', JSON.stringify(campaigns));
              localStorage.setItem('altakhfid_campaigns', JSON.stringify(campaigns));
            } catch(e) {}
          }
          var hashtags = Array.isArray(content.trendHashtags)
            ? content.trendHashtags
            : (Array.isArray(content.hashtags) ? content.hashtags : null);
          if (hashtags && lastHooks && lastHooks.setHashtags) lastHooks.setHashtags(hashtags);
          if (hashtags) { try { localStorage.setItem('trend_hashtags_v2', JSON.stringify(hashtags)); } catch(e) {} }
          if (content.announcements && typeof content.announcements === 'object') {
            var ann = normalizeAnnouncementSettings(content.announcements);
            if (lastHooks && lastHooks.setAnnouncementSettings) lastHooks.setAnnouncementSettings(ann);
            try { localStorage.setItem('shein_announcement_bar_settings_v1', JSON.stringify(ann)); } catch(e) {}
          }
          if (content.categoryTabsConfig && typeof content.categoryTabsConfig === 'object') {
            if (lastHooks && lastHooks.setCategoryTabsConfig) lastHooks.setCategoryTabsConfig(content.categoryTabsConfig);
            try { localStorage.setItem('store_category_tabs_config_v2', JSON.stringify(content.categoryTabsConfig)); } catch(e) {}
          }
          if (Array.isArray(content.recommendationTabs)) {
            if (lastHooks && lastHooks.setRecommendationTabs) lastHooks.setRecommendationTabs(content.recommendationTabs);
            try { localStorage.setItem('store_recommendation_tabs_v2', JSON.stringify(content.recommendationTabs)); } catch(e) {}
          }
        }

        var serverProducts = await takhfidBridge.fetchProducts();
        if (lastConnectionError) {
          throw lastConnectionError;
        }
        var products = Array.isArray(serverProducts) ? serverProducts.map(normalizeProduct).filter(Boolean) : [];
        if (lastHooks && lastHooks.setProducts) lastHooks.setProducts(products);
        try { localStorage.setItem('altakhfid_products', JSON.stringify(products)); } catch(e) {}

        var orders = await takhfidBridge.fetchOrders();
        var orderList = Array.isArray(orders) ? orders : [];
        if (lastHooks && lastHooks.setOrders) lastHooks.setOrders(orderList);
        try { localStorage.setItem('admin_orders_v2', JSON.stringify(orderList)); } catch(e) {}

        if (isManual) toast('تم تحديث المنتجات والمحتوى والطلبات مباشرة من الخادم ✅', 'success');
        return { success: true, productsCount: products.length, ordersCount: orderList.length };
      } catch (err) {
        console.error('[Bridge] syncFromServer error:', err);
        if (isManual) toast('تعذر تحديث البيانات من الخادم: ' + (err.message || String(err)), 'error');
        return { success: false, error: err.message || String(err) };
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
          toast('تم الاتصال بالخادم بنجاح وجلب ' + finalProdCount + ' منتجاً حياً ✨', 'success');
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
  window.__takhfidSavePricing = takhfidBridge.savePricingSettings.bind(takhfidBridge);
  window.__takhfidCreateOrder = takhfidBridge.createOrder.bind(takhfidBridge);
  window.__takhfidUpdateOrderStatus = takhfidBridge.updateOrderStatus.bind(takhfidBridge);
  window.__takhfidUpdateOrderAddress = takhfidBridge.updateOrderAddress.bind(takhfidBridge);
  window.__takhfidSyncAll = takhfidBridge.syncAllToBackend.bind(takhfidBridge);
  window.__takhfidSyncFromServer = function(isManual) { return takhfidBridge.syncFromServer(isManual); };
  window.__takhfidRefresh = function() { return takhfidBridge.syncFromServer(false); };
  window.__takhfidBulkSync = takhfidBridge.syncAllToBackend.bind(takhfidBridge);
  window.__takhfidFetchOrders = takhfidBridge.fetchOrders.bind(takhfidBridge);
  window.__takhfidNormalizeOrder = normalizeOrder;
  window.__takhfidFiniteNumber = finiteNumber;
  window.syncProductsToServer = function() { return takhfidBridge.syncAllToBackend(true); };

  // UI rules for the new admin: no manual bulk-sync, and live order sorting.
  function installAdminUxRules() {
    try {
      var syncBtn = document.getElementById('admin-sync-cloud-btn');
      if (syncBtn) {
        syncBtn.style.display = 'none';
        syncBtn.setAttribute('aria-hidden', 'true');
      }

      var orderSearch = Array.from(document.querySelectorAll('input')).find(function(input) {
        return input && input.placeholder === 'ابحث بالاسم، الهاتف، المحافظة، أو الطلب...';
      });

      if (orderSearch) {
        var filterBar = orderSearch.closest('.p-2\\.5') || orderSearch.parentElement && orderSearch.parentElement.parentElement;
        if (filterBar && !filterBar.querySelector('#takhfid-order-sort')) {
          var selectWrap = document.createElement('div');
          selectWrap.style.cssText = 'display:flex;align-items:center;gap:6px;margin-top:6px;';
          selectWrap.innerHTML =
            '<span style="font-size:10px;font-weight:800;color:#92400e;">الفرز:</span>' +
            '<select id="takhfid-order-sort" style="flex:1;background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:4px 6px;font-size:11px;font-weight:700;color:#111827;">' +
            '<option value="newest">الأحدث</option>' +
            '<option value="name_asc">الاسم: أ ← ي</option>' +
            '<option value="name_desc">الاسم: ي ← أ</option>' +
            '<option value="amount_desc">القيمة: الأعلى</option>' +
            '<option value="amount_asc">القيمة: الأقل</option>' +
            '</select>';
          filterBar.appendChild(selectWrap);
        }

        var sorter = document.getElementById('takhfid-order-sort');
        var list = orderSearch.closest('.flex.flex-col') && orderSearch.closest('.flex.flex-col').querySelector('.flex-1.overflow-y-auto');
        if (sorter && list && sorter.__takhfidBound !== true) {
          sorter.__takhfidBound = true;
          sorter.addEventListener('change', function() {
            var mode = sorter.value;
            var items = Array.from(list.children);
            items.sort(function(a, b) {
              var at = (a.innerText || '').replace(/\\s+/g, ' ').trim();
              var bt = (b.innerText || '').replace(/\\s+/g, ' ').trim();
              if (mode === 'name_asc' || mode === 'name_desc') {
                var an = at.split('•')[0] || at;
                var bn = bt.split('•')[0] || bt;
                var cmp = an.localeCompare(bn, 'ar');
                return mode === 'name_asc' ? cmp : -cmp;
              }
              var nums = function(s) {
                var ms = s.match(/([0-9][0-9,\\.]*)\\s*(?:ر\.س|ر\.ي)?/g) || [];
                if (!ms.length) return 0;
                return Number((ms[ms.length-1] || '').replace(/[^0-9.]/g, '')) || 0;
              };
              var av = nums(at), bv = nums(bt);
              if (mode === 'amount_desc') return bv - av;
              if (mode === 'amount_asc') return av - bv;
              return 0;
            });
            items.forEach(function(node) { list.appendChild(node); });
          });
        }
      }
    } catch (e) {
      console.warn('[Bridge] admin UX rule warning:', e);
    }
  }

  if (typeof MutationObserver !== 'undefined') {
    var __takhfidUxObserver = new MutationObserver(function() { installAdminUxRules(); });
    try {
      __takhfidUxObserver.observe(document.documentElement || document.body, { childList: true, subtree: true });
    } catch (e) {}
  }
  if (typeof setTimeout !== 'undefined') setTimeout(installAdminUxRules, 250);
  if (typeof setInterval !== 'undefined') setInterval(installAdminUxRules, 1500);

  window.__takhfidInstallAdminUx = installAdminUxRules;

  console.log('[Bridge] Takhfid Store Bridge v4.3.0 loaded and ready.');
})();
