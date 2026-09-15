export interface Product {
  id: string;
  name: string;
  description?: string;
  price: number;
  originalPrice?: number;
  compareAtPrice?: number;
  discount?: number;
  category: string;
  categoryId?: string;
  subCategory?: string | null;
  image: string;
  images?: string[];
  stock?: number;
  inStock?: boolean;
  featured?: boolean;
  rating?: number;
  reviewCount?: number;
  colors?: { name: string; hex: string }[];
  sizes?: string[];
  tags?: string[];
  sku?: string;
  active?: boolean;
}

export interface SubCategory {
  id: string;
  name: string;
  image?: string;
}

export interface Category {
  id: string;
  name: string;
  iconName?: string;
  image?: string;
  itemCount?: number;
  subCategories?: SubCategory[];
}

export interface Banner {
  id: string;
  title: string;
  subtitle?: string;
  image: string;
  link?: string;
  active?: boolean;
  isActive?: boolean;
  categoryId?: string;
}

export interface TrendCampaign {
  id: string;
  title: string;
  subtitle?: string;
  image: string;
  tag?: string;
}

export interface PricingSettings {
  usdRate: number;
  sarRate: number;
  yerRate: number;
  shippingSanaa: number;
  shippingOther: number;
  freeShippingThreshold: number;
  sarToYerRateNorth?: number;
  sarToYerRateSouth?: number;
  usdToYerRateNorth?: number;
  usdToYerRateSouth?: number;
}

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  quantity: number;
  image?: string;
  selectedColor?: string;
  selectedSize?: string;
}

export interface Order {
  id: string;
  customerId?: string;
  customerName: string;
  customerPhone: string;
  customerAvatar?: string;
  governorate: string;
  shippingAddress?: string;
  deliveryNotes?: string;
  items: OrderItem[];
  totalAmount: number;
  status: string;
  isPaid?: boolean;
  sessionId?: string | null;
  trackingNumber?: string;
  approvedAt?: string | null;
  completedAt?: string | null;
  createdAt?: string;
}

export interface User {
  uid: string;
  phone: string;
  firstName?: string;
  secondName?: string;
  thirdName?: string;
  lastName?: string;
  governorate?: string;
  role?: string;
  isAdmin?: boolean;
}

export interface StoreSettings {
  storeName: string;
  phone: string;
  whatsapp: string;
  currency: string;
  enableReviews: boolean;
  announcementText?: string;
  primaryPhone?: string;
  secondaryPhone?: string;
  supportWhatsapp?: string;
}

export const initialStoreSettings: StoreSettings = {
  storeName: 'التخفيض الصح',
  phone: '967774952665',
  whatsapp: '967774952665',
  currency: 'YER',
  enableReviews: true,
  announcementText: 'عروض التخفيض الكبرى متوفرة الآن!'
};
