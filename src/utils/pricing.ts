import type { PricingSettings } from '../types';

export const initialPricingSettings: PricingSettings = {
  usdRate: 535,
  sarRate: 140,
  yerRate: 1,
  shippingSanaa: 1500,
  shippingOther: 2500,
  freeShippingThreshold: 20000
};

export function formatPrice(amount: number, currency: string = 'YER'): string {
  if (currency === 'SAR') {
    return `${(amount / 140).toFixed(2)} ر.س`;
  }
  if (currency === 'USD') {
    return `$${(amount / 535).toFixed(2)}`;
  }
  return `${Math.round(amount).toLocaleString('ar-YE')} ر.ي`;
}
