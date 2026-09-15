import type { Product, Category, Banner, TrendCampaign, PricingSettings, Order, User, StoreSettings } from './types';
import { initialStoreSettings } from './types';
import { initialPricingSettings } from './utils/pricing';

const API_BASE_URL = (((import.meta as any).env?.VITE_API_BASE_URL as string) || '').replace(/\/$/, '');
const TOKEN_KEY = 'takhfid_access_token';

export function getAccessToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setAccessToken(token: string): void {
  try {
    localStorage.setItem(TOKEN_KEY, token);
  } catch {
    // ignore
  }
}

export function clearAccessToken(): void {
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {
    // ignore
  }
}

export function normalizePhone(value: string): string {
  let digits = value.replace(/\D/g, '');
  if (digits.startsWith('00')) digits = digits.slice(2);
  if (digits.startsWith('0')) digits = `967${digits.slice(1)}`;
  if (digits.length === 9 && digits.startsWith('7')) digits = `967${digits}`;
  return digits;
}

export async function apiFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers || {});
  headers.set('Accept', 'application/json');
  if (init.body && !(init.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  const token = getAccessToken();
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  // If running with Vite dev server proxy or direct
  const url = `${API_BASE_URL}${path}`;
  
  let response: Response;
  try {
    response = await fetch(url, { ...init, headers });
  } catch (err) {
    // Fallback to direct URL if relative fails
    if (!API_BASE_URL && path.startsWith('/takhfid')) {
      const directUrl = `https://whats.alattab.site${path}`;
      response = await fetch(directUrl, { ...init, headers });
    } else {
      throw err;
    }
  }

  const data = (await response.json().catch(() => ({}))) as T & { error?: string; message?: string };
  if (!response.ok) {
    throw new Error(data.error || data.message || `خطأ في الخادم (${response.status})`);
  }
  return data;
}

export interface ApiUser {
  uid: string;
  phone: string;
  firstName?: string;
  secondName?: string;
  thirdName?: string;
  lastName?: string;
  governorate?: string;
  role?: 'admin' | 'customer';
  isAdmin?: boolean;
  createdAt?: string;
  lastLoginAt?: string;
  updatedAt?: string;
}

export interface VerifySessionResponse {
  success: boolean;
  accessToken: string;
  tokenType: 'Bearer';
  expiresAt: string;
  user: ApiUser;
}

// ================= AUTHENTICATION =================

export async function sendOtpApi(phoneNumber: string) {
  const cleanPhone = normalizePhone(phoneNumber);
  return apiFetch<{
    success: boolean;
    expiresInSeconds: number;
    retryAfterSeconds: number;
    phoneNumber: string;
  }>('/takhfid/api/v4/auth/send-otp', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber: cleanPhone }),
  });
}

export async function verifyOtpApi(payload: {
  phoneNumber: string;
  otp: string;
  firstName: string;
  secondName?: string;
  thirdName?: string;
  lastName?: string;
  governorate: string;
}): Promise<VerifySessionResponse> {
  const cleanPayload = {
    ...payload,
    phoneNumber: normalizePhone(payload.phoneNumber),
  };
  const result = await apiFetch<VerifySessionResponse>('/takhfid/api/v4/auth/verify-otp', {
    method: 'POST',
    body: JSON.stringify(cleanPayload),
  });
  if (result.accessToken) {
    setAccessToken(result.accessToken);
  }
  return result;
}

export async function fetchCurrentUser(): Promise<ApiUser | null> {
  if (!getAccessToken()) return null;
  try {
    const result = await apiFetch<{ success: boolean; user: ApiUser }>('/takhfid/api/v4/auth/me');
    return result.user;
  } catch {
    clearAccessToken();
    return null;
  }
}

export async function logoutApi(): Promise<void> {
  try {
    await apiFetch('/takhfid/api/v4/auth/logout', { method: 'POST' });
  } catch {
    // ignore
  } finally {
    clearAccessToken();
  }
}

// ================= PRODUCTS API =================

export function sanitizeProduct(p: any): Product {
  const price = typeof p.price === 'number' && !isNaN(p.price)
    ? p.price
    : (typeof p.discountPrice === 'number' && !isNaN(p.discountPrice)
      ? p.discountPrice
      : (typeof p.originalPrice === 'number' && !isNaN(p.originalPrice) ? p.originalPrice : 0));
      
  return {
    ...p,
    id: String(p.id || `prod-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`),
    name: p.name || 'منتج غير مسمى',
    price,
    originalPrice: typeof p.originalPrice === 'number' && !isNaN(p.originalPrice) ? p.originalPrice : price,
    discountPrice: typeof p.discountPrice === 'number' && !isNaN(p.discountPrice) ? p.discountPrice : price,
    discount: typeof p.discount === 'number' ? p.discount : (typeof p.discountPercentage === 'number' ? p.discountPercentage : 0),
    discountPercentage: typeof p.discountPercentage === 'number' ? p.discountPercentage : (typeof p.discount === 'number' ? p.discount : 0),
    categoryId: p.categoryId || p.category || (Array.isArray(p.categories) && p.categories[1]) || 'all',
    category: p.category || p.categoryId || 'all',
    categories: Array.isArray(p.categories) && p.categories.length ? p.categories : ['all', p.category || p.categoryId || 'all'],
    subCategory: p.subCategory || 'عام',
    subCategories: Array.isArray(p.subCategories) ? p.subCategories : [],
    image: p.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop&q=80',
    galleryImages: Array.isArray(p.galleryImages) ? p.galleryImages : (Array.isArray(p.gallery) ? p.gallery : []),
    gallery: Array.isArray(p.gallery) ? p.gallery : (Array.isArray(p.galleryImages) ? p.galleryImages : []),
    colors: Array.isArray(p.colors) ? p.colors : [],
    sizes: Array.isArray(p.sizes) ? p.sizes : [],
    inStock: p.inStock !== false,
    rating: typeof p.rating === 'number' ? p.rating : 4.8,
    reviewsCount: typeof p.reviewsCount === 'number' ? p.reviewsCount : 50,
  };
}

export async function fetchProductsApi(): Promise<Product[]> {
  try {
    const data = await apiFetch<{ products?: any[] }>('/takhfid/api/v2/products');
    if (Array.isArray(data.products) && data.products.length > 0) {
      const sanitized = data.products.map(sanitizeProduct);
      // Update local storage cache
      try {
        localStorage.setItem('altakhfid_products', JSON.stringify(sanitized));
      } catch {}
      return sanitized;
    }
    return [];
  } catch (error) {
    console.warn('Could not fetch products from server API:', error);
    throw error;
  }
}

export async function createProductApi(product: Product): Promise<Product> {
  const payload = sanitizeProduct(product);
  try {
    const data = await apiFetch<{ success?: boolean; product?: Product }>('/takhfid/api/v2/products', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    return data.product ? sanitizeProduct(data.product) : payload;
  } catch (e) {
    console.warn('POST /products failed, falling back to bulk/local:', e);
    return payload;
  }
}

export async function bulkSyncProductsApi(products: Product[]): Promise<{ count: number; success: boolean }> {
  const sanitized = products.map(sanitizeProduct);
  try {
    const data = await apiFetch<{ success?: boolean; count?: number; message?: string }>('/takhfid/api/v2/products/bulk', {
      method: 'POST',
      body: JSON.stringify({ products: sanitized }),
    });
    return {
      count: data.count || sanitized.length,
      success: data.success !== false,
    };
  } catch (e) {
    console.warn('POST /products/bulk failed:', e);
    return { count: sanitized.length, success: false };
  }
}

export async function updateProductApi(product: Product): Promise<Product> {
  const payload = sanitizeProduct(product);
  try {
    const data = await apiFetch<{ success?: boolean; product?: Product }>(`/takhfid/api/v2/products/${payload.id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    return data.product ? sanitizeProduct(data.product) : payload;
  } catch {
    return createProductApi(payload);
  }
}

export async function deleteProductApi(productId: string): Promise<boolean> {
  try {
    await apiFetch(`/takhfid/api/v2/products/${productId}`, {
      method: 'DELETE',
    });
    return true;
  } catch (err) {
    console.warn('DELETE /products failed:', err);
    return false;
  }
}

// ================= CONTENT, PRICING & STORE SETTINGS API =================

export interface ServerContent {
  banners: Banner[];
  campaigns: TrendCampaign[];
  categories: Category[];
  pricingSettings?: PricingSettings;
  storeSettings?: StoreSettings;
  orders?: Order[];
  users?: User[];
  [key: string]: any;
}

export async function fetchContentApi(): Promise<ServerContent> {
  try {
    const data = await apiFetch<{ content?: ServerContent; success?: boolean }>('/takhfid/admin/api/content');
    return {
      banners: Array.isArray(data.content?.banners) ? data.content!.banners : [],
      campaigns: Array.isArray(data.content?.campaigns) ? data.content!.campaigns : [],
      categories: Array.isArray(data.content?.categories) ? data.content!.categories : [],
      pricingSettings: data.content?.pricingSettings,
      storeSettings: data.content?.storeSettings,
      orders: Array.isArray(data.content?.orders) ? data.content!.orders : [],
      users: Array.isArray(data.content?.users) ? data.content!.users : [],
    };
  } catch (error) {
    console.warn('Could not fetch content from server:', error);
    return { banners: [], campaigns: [], categories: [] };
  }
}

export async function saveContentApi(content: Partial<ServerContent>): Promise<boolean> {
  try {
    await apiFetch('/takhfid/admin/api/content', {
      method: 'PUT',
      body: JSON.stringify(content),
    });
    return true;
  } catch (error) {
    console.warn('Could not save content to server:', error);
    return false;
  }
}

export async function fetchPricingSettingsApi(): Promise<PricingSettings> {
  let cached: PricingSettings = initialPricingSettings;
  try {
    const saved = localStorage.getItem('altakhfid_pricing_settings');
    if (saved) {
      cached = { ...initialPricingSettings, ...JSON.parse(saved) };
    }
  } catch {}

  try {
    const content = await fetchContentApi();
    if (content.pricingSettings && typeof content.pricingSettings.sarToYerRateNorth === 'number') {
      const merged = { ...cached, ...content.pricingSettings };
      try {
        localStorage.setItem('altakhfid_pricing_settings', JSON.stringify(merged));
      } catch {}
      return merged;
    }
  } catch {}

  return cached;
}

export async function savePricingSettingsApi(settings: PricingSettings): Promise<boolean> {
  try {
    localStorage.setItem('altakhfid_pricing_settings', JSON.stringify(settings));
  } catch {}

  try {
    await saveContentApi({ pricingSettings: settings });
    return true;
  } catch (err) {
    console.warn('Failed to save pricing to server:', err);
    return false;
  }
}

// ================= STORE & ADMIN CONTACT SETTINGS API =================

export async function fetchStoreSettingsApi(): Promise<StoreSettings> {
  let cached: StoreSettings = initialStoreSettings;
  try {
    const saved = localStorage.getItem('altakhfid_store_settings');
    if (saved) {
      cached = { ...initialStoreSettings, ...JSON.parse(saved) };
    }
  } catch {}

  try {
    const content = await fetchContentApi();
    if (content.storeSettings && content.storeSettings.primaryPhone) {
      const merged = { ...cached, ...content.storeSettings };
      try {
        localStorage.setItem('altakhfid_store_settings', JSON.stringify(merged));
      } catch {}
      return merged;
    }
  } catch {}

  return cached;
}

export async function saveStoreSettingsApi(settings: StoreSettings): Promise<boolean> {
  try {
    localStorage.setItem('altakhfid_store_settings', JSON.stringify(settings));
  } catch {}

  try {
    await saveContentApi({ storeSettings: settings });
    return true;
  } catch (err) {
    console.warn('Failed to save store settings to server:', err);
    return false;
  }
}

// ================= ORDERS API =================

export async function createOrderApi(order: Order): Promise<boolean> {
  try {
    await apiFetch('/takhfid/api/v2/orders', {
      method: 'POST',
      body: JSON.stringify(order),
    });
    return true;
  } catch (e) {
    // Fallback: save order inside server content endpoint
    try {
      const content = await fetchContentApi();
      const existingOrders = content.orders || [];
      const updatedOrders = [order, ...existingOrders.filter(o => o.id !== order.id)];
      await saveContentApi({ orders: updatedOrders });
      return true;
    } catch {
      return false;
    }
  }
}

export async function fetchOrdersApi(): Promise<Order[]> {
  try {
    const res = await apiFetch<{ orders?: Order[]; data?: Order[] }>('/takhfid/api/v2/orders');
    const list = res.orders || res.data;
    if (Array.isArray(list) && list.length > 0) {
      return list;
    }
  } catch {}

  try {
    const content = await fetchContentApi();
    if (Array.isArray(content.orders) && content.orders.length > 0) {
      return content.orders;
    }
  } catch {}

  try {
    const local = localStorage.getItem('altakhfid_orders');
    return local ? JSON.parse(local) : [];
  } catch {
    return [];
  }
}

export async function updateOrderStatusApi(
  orderId: string,
  status: Order['status'],
  isPaid?: boolean
): Promise<boolean> {
  try {
    await apiFetch(`/takhfid/api/v2/orders/${orderId}`, {
      method: 'PUT',
      body: JSON.stringify({ status, isPaid, updatedAt: new Date().toISOString() }),
    });
    return true;
  } catch {
    // Fallback update in server content
    try {
      const content = await fetchContentApi();
      const existingOrders = content.orders || [];
      const updated = existingOrders.map(ord =>
        ord.id === orderId
          ? { ...ord, status, isPaid: isPaid ?? ord.isPaid, updatedAt: new Date().toISOString() }
          : ord
      );
      await saveContentApi({ orders: updated });
      return true;
    } catch {
      return false;
    }
  }
}

export async function deleteOrderApi(orderId: string): Promise<boolean> {
  try {
    await apiFetch(`/takhfid/api/v2/orders/${orderId}`, {
      method: 'DELETE',
    });
    return true;
  } catch {
    try {
      const content = await fetchContentApi();
      const existingOrders = content.orders || [];
      const updated = existingOrders.filter(o => o.id !== orderId);
      await saveContentApi({ orders: updated });
      return true;
    } catch {
      return false;
    }
  }
}

export async function bulkSyncOrdersApi(orders: Order[]): Promise<number> {
  try {
    await saveContentApi({ orders });
    return orders.length;
  } catch {
    return 0;
  }
}

// ================= CUSTOMERS / USERS API =================

export async function fetchUsersApi(): Promise<User[]> {
  try {
    const res = await apiFetch<{ users?: User[]; data?: User[] }>('/takhfid/api/v2/users');
    const list = res.users || res.data;
    if (Array.isArray(list) && list.length > 0) {
      return list;
    }
  } catch {}

  try {
    const content = await fetchContentApi();
    if (Array.isArray(content.users) && content.users.length > 0) {
      return content.users;
    }
  } catch {}

  try {
    const local = localStorage.getItem('altakhfid_all_users');
    return local ? JSON.parse(local) : [];
  } catch {
    return [];
  }
}

export async function saveUserApi(user: User): Promise<boolean> {
  try {
    await apiFetch('/takhfid/api/v2/users', {
      method: 'POST',
      body: JSON.stringify(user),
    });
    return true;
  } catch {
    try {
      const currentUsers = await fetchUsersApi();
      const exists = currentUsers.some(u => u.uid === user.uid || u.phone === user.phone);
      const updated = exists
        ? currentUsers.map(u => (u.uid === user.uid ? { ...u, ...user } : u))
        : [user, ...currentUsers];
      localStorage.setItem('altakhfid_all_users', JSON.stringify(updated));
      await saveContentApi({ users: updated });
      return true;
    } catch {
      return false;
    }
  }
}

export async function deleteUserApi(uid: string): Promise<boolean> {
  try {
    await apiFetch(`/takhfid/api/v2/users/${uid}`, {
      method: 'DELETE',
    });
    return true;
  } catch {
    try {
      const currentUsers = await fetchUsersApi();
      const updated = currentUsers.filter(u => u.uid !== uid);
      localStorage.setItem('altakhfid_all_users', JSON.stringify(updated));
      await saveContentApi({ users: updated });
      return true;
    } catch {
      return false;
    }
  }
}

export async function bulkSyncUsersApi(users: User[]): Promise<number> {
  try {
    await saveContentApi({ users });
    localStorage.setItem('altakhfid_all_users', JSON.stringify(users));
    return users.length;
  } catch {
    return 0;
  }
}

// ================= AUTOMATIC FIRST-RUN & COMPREHENSIVE MIGRATION =================

export interface MigrationSummary {
  products: number;
  categories: number;
  banners: number;
  campaigns: number;
  orders: number;
  users: number;
  pricingSettings: boolean;
  storeSettings: boolean;
  serverSynced: boolean;
  errors: string[];
}

export async function fullMigrationToServer(data: {
  products: Product[];
  categories: Category[];
  banners: Banner[];
  campaigns: TrendCampaign[];
  pricingSettings: PricingSettings;
  storeSettings: StoreSettings;
  orders?: Order[];
  users?: User[];
}): Promise<MigrationSummary> {
  const summary: MigrationSummary = {
    products: 0,
    categories: data.categories.length,
    banners: data.banners.length,
    campaigns: data.campaigns.length,
    orders: data.orders?.length || 0,
    users: data.users?.length || 0,
    pricingSettings: false,
    storeSettings: false,
    serverSynced: false,
    errors: [],
  };

  // 1. Bulk push products to server
  try {
    const res = await bulkSyncProductsApi(data.products);
    summary.products = res.count;
  } catch (err: any) {
    summary.errors.push('فشل ترحيل بعض المنتجات: ' + (err?.message || 'خطأ غير معروف'));
  }

  // 2. Save all content, pricing, store settings, orders and users
  try {
    const payload: Partial<ServerContent> = {
      categories: data.categories,
      banners: data.banners,
      campaigns: data.campaigns,
      pricingSettings: data.pricingSettings,
      storeSettings: data.storeSettings,
      orders: data.orders || [],
      users: data.users || [],
    };
    const saved = await saveContentApi(payload);
    if (saved) {
      summary.pricingSettings = true;
      summary.storeSettings = true;
      summary.serverSynced = true;
    }
  } catch (err: any) {
    summary.errors.push('فشل ترحيل المحتوى والإعدادات: ' + (err?.message || ''));
  }

  return summary;
}

export async function autoMigrateDataToServer(
  fallbackProducts: Product[],
  fallbackCategories: Category[],
  fallbackBanners: Banner[],
  fallbackCampaigns: TrendCampaign[],
  fallbackStoreSettings: StoreSettings = initialStoreSettings
): Promise<{ migratedProducts: number; serverSynced: boolean }> {
  let migratedProducts = 0;
  let serverSynced = false;

  // 1. Verify or sync products
  try {
    const serverProducts = await fetchProductsApi();
    if (!serverProducts || serverProducts.length === 0) {
      console.log('Server has no products yet. Migrating products to server...');
      const res = await bulkSyncProductsApi(fallbackProducts);
      migratedProducts = res.count;
      serverSynced = true;
    } else {
      migratedProducts = serverProducts.length;
      serverSynced = true;
    }
  } catch {
    console.log('Server fetch failed, attempting bulk upload...');
    try {
      const res = await bulkSyncProductsApi(fallbackProducts);
      migratedProducts = res.count;
      serverSynced = true;
    } catch {}
  }

  // 2. Check and seed content if empty
  try {
    const content = await fetchContentApi();
    const needsCategories = !content.categories || content.categories.length === 0;
    const needsBanners = !content.banners || content.banners.length === 0;
    const needsCampaigns = !content.campaigns || content.campaigns.length === 0;
    const needsStoreSettings = !content.storeSettings || !content.storeSettings.primaryPhone;

    if (needsCategories || needsBanners || needsCampaigns || needsStoreSettings) {
      console.log('Seeding server content with categories, banners, campaigns, settings...');
      await saveContentApi({
        categories: needsCategories ? fallbackCategories : content.categories,
        banners: needsBanners ? fallbackBanners : content.banners,
        campaigns: needsCampaigns ? fallbackCampaigns : content.campaigns,
        pricingSettings: content.pricingSettings || initialPricingSettings,
        storeSettings: needsStoreSettings ? fallbackStoreSettings : content.storeSettings,
      });
    }
  } catch (e) {
    console.warn('Content check/migration error:', e);
  }

  return { migratedProducts, serverSynced };
}
