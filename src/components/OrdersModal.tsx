import React from 'react';
import { X, Package, Clock, CheckCircle, Truck, Phone } from 'lucide-react';
import type { Order } from '../types';
import { safeFormatNumber } from '../utils/pricing';

interface OrdersModalProps {
  isOpen: boolean;
  orders: Order[];
  currency: 'YER' | 'SAR';
  onClose: () => void;
  onOpenSupport: () => void;
}

export const OrdersModal: React.FC<OrdersModalProps> = ({
  isOpen,
  orders,
  currency,
  onClose,
  onOpenSupport,
}) => {
  if (!isOpen) return null;

  const getStatusBadge = (status: Order['status']) => {
    switch (status) {
      case 'preparing':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
            <Clock className="w-3 h-3" />
            <span>جاري التجهيز بالمستودع</span>
          </span>
        );
      case 'in_shipping':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-blue-50 text-blue-700 border border-blue-200">
            <Truck className="w-3 h-3" />
            <span>جاري الشحن والتوصيل</span>
          </span>
        );
      case 'delivered':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle className="w-3 h-3" />
            <span>تم التوصيل بنجاح</span>
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700">
            <span>ملغي</span>
          </span>
        );
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/60 backdrop-blur-xs transition-opacity duration-300">
      <div
        className="bg-white w-full max-w-md h-full shadow-2xl flex flex-col animate-in slide-in-from-left duration-300"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 bg-white">
          <div className="flex items-center gap-2">
            <Package className="w-5 h-5 text-purple-700" />
            <h2 className="font-extrabold text-slate-800 text-base">سجل طلباتي</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-all"
            aria-label="إغلاق"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {orders.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-64 text-center">
              <div className="w-16 h-16 rounded-full bg-purple-50 flex items-center justify-center text-purple-600 mb-3">
                <Package className="w-8 h-8" />
              </div>
              <h3 className="text-base font-bold text-slate-800">لا توجد طلبات سابقة</h3>
              <p className="text-xs text-slate-500 mt-1">
                عند إتمام أي طلب، ستتمكن من تتبع حالة التجهيز والشحن هنا مباشرة!
              </p>
            </div>
          ) : (
            orders.map((ord) => (
              <div
                key={ord.id}
                className="bg-slate-50 rounded-2xl p-4 border border-slate-200/80 space-y-3"
              >
                <div className="flex items-center justify-between">
                  <span className="font-mono font-bold text-xs text-purple-700">
                    {ord.orderNumber}
                  </span>
                  {getStatusBadge(ord.status)}
                </div>

                <div className="space-y-2 border-y border-slate-200/60 py-2">
                  {ord.items.map((item, idx) => (
                    <div key={idx} className="flex items-center gap-2 text-xs">
                      <img
                        src={item.image}
                        alt={item.productName}
                        className="w-10 h-10 object-cover rounded-lg shrink-0"
                      />
                      <div className="flex-1 min-w-0">
                        <span className="font-bold text-slate-800 block truncate">
                          {item.productName}
                        </span>
                        <span className="text-[10px] text-slate-500">
                          الكمية: {item.quantity || 1} × {safeFormatNumber(item.price)} ر.ي
                        </span>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">المحافظة: {ord.governorate}</span>
                  <span className="font-black text-purple-700 text-sm">
                    {safeFormatNumber(ord.total)} {ord.currency || currency}
                  </span>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Footer Support Button */}
        <div className="p-4 border-t border-slate-100 bg-slate-50">
          <button
            onClick={onOpenSupport}
            className="w-full py-2.5 px-4 rounded-xl bg-white hover:bg-slate-100 border border-slate-200 text-slate-700 font-bold text-xs transition-all flex items-center justify-center gap-2"
          >
            <Phone className="w-4 h-4 text-purple-600" />
            <span>تواصل مع خدمة العملاء للمساعدة</span>
          </button>
        </div>
      </div>
    </div>
  );
};
