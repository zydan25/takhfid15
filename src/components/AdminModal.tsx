import React, { useState, useEffect } from 'react';
import {
  X,
  ShieldCheck,
  Users,
  Package,
  ShoppingBag,
  Flame,
  RefreshCw,
  CheckCircle,
  Trash2,
  Plus,
  Phone,
  DollarSign,
  Server,
  CloudUpload,
  CloudDownload,
  Check,
  AlertCircle,
  Settings,
  Building2,
  MapPin,
  CreditCard,
  Download,
  Upload,
  Printer,
  FileText,
  Calendar,
  Barcode,
  Search,
} from 'lucide-react';
import type { Order, Product, TrendCampaign, User, PricingSettings, StoreSettings } from '../types';
import { initialStoreSettings } from '../types';
import { fetchAllUsersFromFirestore, deleteUserFromFirestore, updateOrderStatusInFirestore } from '../firebase';
import { safeFormatNumber, initialPricingSettings } from '../utils/pricing';
import {
  fetchProductsApi,
  createProductApi,
  deleteProductApi,
  bulkSyncProductsApi,
  savePricingSettingsApi,
  saveContentApi,
  fetchStoreSettingsApi,
  saveStoreSettingsApi,
  fetchUsersApi,
  deleteUserApi,
  bulkSyncUsersApi,
  updateOrderStatusApi,
  deleteOrderApi,
  bulkSyncOrdersApi,
  fullMigrationToServer,
  type MigrationSummary,
} from '../api';
import { INITIAL_CATEGORIES } from '../data/categories';
import { INITIAL_BANNERS } from '../data/banners';
import { INITIAL_TREND_CAMPAIGNS } from '../data/trends';

interface AdminModalProps {
  isOpen: boolean;
  orders: Order[];
  products: Product[];
  campaigns: TrendCampaign[];
  pricingSettings?: PricingSettings;
  storeSettings?: StoreSettings;
  onClose: () => void;
  onUpdateOrderStatus: (orderId: string, status: Order['status'], isPaid?: boolean) => void;
  onSaveProduct: (product: Product) => void;
  onDeleteProduct: (productId: string) => void;
  onUpdateCampaigns: (campaigns: TrendCampaign[]) => void;
  onSavePricingSettings?: (settings: PricingSettings) => void;
  onSaveStoreSettings?: (settings: StoreSettings) => void;
  onRefreshProductsFromServer?: () => Promise<void>;
  onShowToast: (msg: string, type?: 'success' | 'info' | 'error') => void;
}

export const AdminModal: React.FC<AdminModalProps> = ({
  isOpen,
  orders,
  products,
  campaigns,
  pricingSettings: propPricingSettings,
  storeSettings: propStoreSettings,
  onClose,
  onUpdateOrderStatus,
  onSaveProduct,
  onDeleteProduct,
  onUpdateCampaigns,
  onSavePricingSettings,
  onSaveStoreSettings,
  onRefreshProductsFromServer,
  onShowToast,
}) => {
  if (!isOpen) return null;

  const [activeTab, setActiveTab] = useState<'orders' | 'products' | 'pricing' | 'store-settings' | 'migration' | 'customers' | 'trends' | 'sales-report'>('orders');
  const [firestoreUsers, setFirestoreUsers] = useState<User[]>([]);
  const [isLoadingUsers, setIsLoadingUsers] = useState(false);

  // Sales Report Filter States
  const [reportGovernorate, setReportGovernorate] = useState('all');
  const [reportStartDate, setReportStartDate] = useState('');
  const [reportEndDate, setReportEndDate] = useState('');
  const [reportSearchQuery, setReportSearchQuery] = useState('');
  const [isExportingPdf, setIsExportingPdf] = useState(false);

  // Sales Report Computed Rows with complete Try-Catch & Null Guarding
  const salesReportData = React.useMemo(() => {
    try {
      const safeOrders = Array.isArray(orders) ? orders : [];
      const rows: Array<{
        id: string;
        orderNumber: string;
        date: string;
        customerName: string;
        governorate: string;
        productName: string;
        quantity: number;
        unitPrice: number;
        totalPrice: number;
        barcode: string;
      }> = [];

      let indexCounter = 0;

      for (const ord of safeOrders) {
        if (!ord || ord.status === 'cancelled') continue;

        const gov = ord.governorate || 'صنعاء';
        if (reportGovernorate !== 'all' && gov !== reportGovernorate) continue;

        if (ord.createdAt) {
          const ordTime = new Date(ord.createdAt).getTime();
          if (!isNaN(ordTime)) {
            if (reportStartDate) {
              const startT = new Date(reportStartDate).getTime();
              if (ordTime < startT) continue;
            }
            if (reportEndDate) {
              const endT = new Date(reportEndDate);
              endT.setHours(23, 59, 59, 999);
              if (ordTime > endT.getTime()) continue;
            }
          }
        }

        const dateStr = ord.createdAt
          ? new Date(ord.createdAt).toLocaleDateString('ar-YE', {
              year: 'numeric',
              month: '2-digit',
              day: '2-digit',
            })
          : new Date().toLocaleDateString('ar-YE');

        const items = Array.isArray(ord.items) ? ord.items : [];
        for (const item of items) {
          if (!item) continue;
          const prod = (item as any).product || item;
          const name = String(prod?.name || (item as any)?.productName || 'صنف ملابس');
          const qty = Number(item.quantity || 1);
          const price = Number(prod?.discountPrice || prod?.originalPrice || (item as any)?.price || 0);

          if (reportSearchQuery.trim()) {
            const q = reportSearchQuery.trim().toLowerCase();
            if (!name.toLowerCase().includes(q) && !(ord.customerName || '').toLowerCase().includes(q)) {
              continue;
            }
          }

          // Generate numeric Barcode safely
          const rawSku = String(prod?.sku || prod?.id || `00${100000 + indexCounter}`);
          const numOnly = rawSku.replace(/[^0-9]/g, '');
          const barcode = numOnly ? `00${numOnly.slice(0, 10)}` : `00${100000 + indexCounter}`;

          rows.push({
            id: `${ord.id}-${indexCounter}`,
            orderNumber: String(ord.orderNumber || ord.id || `#${indexCounter + 1}`),
            date: dateStr,
            customerName: ord.customerName || 'عميل المتجر',
            governorate: gov,
            productName: name,
            quantity: qty,
            unitPrice: price,
            totalPrice: price * qty,
            barcode,
          });

          indexCounter++;
        }
      }

      const totalQuantity = rows.reduce((acc, r) => acc + (Number(r.quantity) || 0), 0);
      const totalRevenue = rows.reduce((acc, r) => acc + (Number(r.totalPrice) || 0), 0);

      return {
        rows,
        totalQuantity,
        totalItemsCount: rows.length,
        totalRevenue,
      };
    } catch (err) {
      console.error('Error computing sales report:', err);
      return {
        rows: [],
        totalQuantity: 0,
        totalItemsCount: 0,
        totalRevenue: 0,
      };
    }
  }, [orders, reportGovernorate, reportStartDate, reportEndDate, reportSearchQuery]);

  const handlePrintReport = () => {
    try {
      window.print();
      onShowToast('تم فتح نافذة الطباعة بنجاح 🖨️', 'success');
    } catch (err) {
      onShowToast('حدث خطأ أثناء محاولة الطباعة', 'error');
    }
  };

  // Pricing Form State
  const [pricingForm, setPricingForm] = useState<PricingSettings>(() => {
    return propPricingSettings || initialPricingSettings;
  });
  const [isSavingPricing, setIsSavingPricing] = useState(false);

  // Store & Contact Settings Form State
  const [storeSettingsForm, setStoreSettingsForm] = useState<StoreSettings>(() => {
    return propStoreSettings || initialStoreSettings;
  });
  const [isSavingStoreSettings, setIsSavingStoreSettings] = useState(false);

  useEffect(() => {
    if (propPricingSettings) {
      setPricingForm(propPricingSettings);
    }
  }, [propPricingSettings]);

  useEffect(() => {
    if (propStoreSettings) {
      setStoreSettingsForm(propStoreSettings);
    }
  }, [propStoreSettings]);

  // Server Migration State
  const [serverProductCount, setServerProductCount] = useState<number | null>(null);
  const [isCheckingServer, setIsCheckingServer] = useState(false);
  const [isMigratingProducts, setIsMigratingProducts] = useState(false);
  const [isMigratingContent, setIsMigratingContent] = useState(false);
  const [isFullMigrating, setIsFullMigrating] = useState(false);
  const [fullMigrationResult, setFullMigrationResult] = useState<MigrationSummary | null>(null);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);

  // New Product Modal/Form State
  const [isAddingProduct, setIsAddingProduct] = useState(false);
  const [newProdName, setNewProdName] = useState('');
  const [newProdPrice, setNewProdPrice] = useState('');
  const [newProdOriginalPrice, setNewProdOriginalPrice] = useState('');
  const [newProdCategory, setNewProdCategory] = useState('women');
  const [newProdImage, setNewProdImage] = useState('');
  const [isSavingProduct, setIsSavingProduct] = useState(false);

  // Check server status & product count
  const checkServerStatus = async () => {
    setIsCheckingServer(true);
    setSyncMessage(null);
    try {
      const serverProds = await fetchProductsApi();
      setServerProductCount(serverProds.length);
      setSyncMessage(`الخادم متصل بنجاح، وعدد المنتجات المسجلة فيه: ${serverProds.length}`);
    } catch (e: any) {
      setSyncMessage(`تعذر الاستعلام من الخادم: ${e.message || 'خطأ غير معروف'}`);
    } finally {
      setIsCheckingServer(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'migration') {
      checkServerStatus();
    }
  }, [activeTab]);

  // Load registered users from Server API with fallback to Firestore
  const loadUsers = async () => {
    setIsLoadingUsers(true);
    try {
      const serverUsers = await fetchUsersApi();
      if (serverUsers && serverUsers.length > 0) {
        setFirestoreUsers(serverUsers);
      } else {
        const users = await fetchAllUsersFromFirestore();
        setFirestoreUsers(users);
        if (users.length > 0) {
          bulkSyncUsersApi(users).catch(() => {});
        }
      }
    } catch (err) {
      console.error(err);
      try {
        const users = await fetchAllUsersFromFirestore();
        setFirestoreUsers(users);
      } catch {}
    } finally {
      setIsLoadingUsers(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'customers') {
      loadUsers();
    }
  }, [activeTab]);

  const handleDeleteUser = async (uid: string) => {
    if (window.confirm('هل أنت متأكد من حذف حساب هذا العميل؟')) {
      await deleteUserApi(uid);
      try {
        await deleteUserFromFirestore(uid);
      } catch {}
      setFirestoreUsers((prev) => prev.filter((u) => u.uid !== uid));
      onShowToast('تم حذف العميل بنجاح من الخادم وقاعدة البيانات', 'success');
    }
  };

  const handleSyncUsersToServer = async () => {
    try {
      const count = await bulkSyncUsersApi(firestoreUsers);
      onShowToast(`تمت مزامنة ${count} عميل مع الخادم بنجاح! 👥`, 'success');
    } catch (err: any) {
      onShowToast(`فشلت المزامنة: ${err.message}`, 'error');
    }
  };

  // Handle Orders Status Update and Sync
  const handleUpdateOrder = async (orderId: string, status: Order['status'], isPaid?: boolean) => {
    onUpdateOrderStatus(orderId, status, isPaid);
    await updateOrderStatusApi(orderId, status, isPaid);
    try {
      await updateOrderStatusInFirestore(orderId, status, isPaid);
    } catch {}
    onShowToast(`تم تحديث حالة الطلب في الخادم بنجاح ✅`, 'success');
  };

  const handleDeleteOrder = async (orderId: string) => {
    if (!window.confirm('هل أنت متأكد من حذف هذا الطلب نهائياً؟')) return;
    await deleteOrderApi(orderId);
    onShowToast('تم حذف الطلب بنجاح من الخادم 🗑️', 'info');
  };

  const handleSyncOrdersToServer = async () => {
    try {
      const count = await bulkSyncOrdersApi(orders);
      onShowToast(`تمت مزامنة ${count} طلب مع الخادم بنجاح! 📦`, 'success');
    } catch (err: any) {
      onShowToast(`فشلت المزامنة: ${err.message}`, 'error');
    }
  };

  // Handle Save Store & Contact Settings
  const handleSaveStoreSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingStoreSettings(true);
    try {
      await saveStoreSettingsApi(storeSettingsForm);
      if (onSaveStoreSettings) {
        onSaveStoreSettings(storeSettingsForm);
      }
      onShowToast('تم حفظ ونشر بيانات الإدارة والأرقام بنجاح على الخادم 📞', 'success');
    } catch (err: any) {
      onShowToast(`خطأ في حفظ الإعدادات: ${err.message || 'فشل الاتصال'}`, 'error');
    } finally {
      setIsSavingStoreSettings(false);
    }
  };

  // Handle Save Pricing
  const handleSavePricing = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingPricing(true);
    try {
      await savePricingSettingsApi(pricingForm);
      if (onSavePricingSettings) {
        onSavePricingSettings(pricingForm);
      }
      onShowToast('تم حفظ ونشر إعدادات التسعير والعملات بنجاح على الخادم 💵', 'success');
    } catch (err: any) {
      onShowToast(`خطأ في حفظ التسعيرات: ${err.message || 'فشل الاتصال'}`, 'error');
    } finally {
      setIsSavingPricing(false);
    }
  };

  // Handle Bulk Migrate Products to Server
  const handleBulkMigrate = async () => {
    setIsMigratingProducts(true);
    try {
      const result = await bulkSyncProductsApi(products);
      setServerProductCount(result.count);
      onShowToast(`تم نقل ومزامنة ${result.count} منتج إلى الخادم الجديد بنجاح! 🚀`, 'success');
      if (onRefreshProductsFromServer) {
        await onRefreshProductsFromServer();
      }
      checkServerStatus();
    } catch (err: any) {
      onShowToast(`فشلت مزامنة المنتجات: ${err.message}`, 'error');
    } finally {
      setIsMigratingProducts(false);
    }
  };

  // Handle Content Migration (Categories, Banners, Campaigns)
  const handleContentMigrate = async () => {
    setIsMigratingContent(true);
    try {
      await saveContentApi({
        categories: INITIAL_CATEGORIES,
        banners: INITIAL_BANNERS,
        campaigns: campaigns.length > 0 ? campaigns : INITIAL_TREND_CAMPAIGNS,
        pricingSettings: pricingForm,
        storeSettings: storeSettingsForm,
      });
      onShowToast('تم رفع وتحديث التصنيفات والبانرات والحملات والإعدادات إلى الخادم بنجاح! ✨', 'success');
    } catch (err: any) {
      onShowToast(`فشل رفع المحتوى: ${err.message}`, 'error');
    } finally {
      setIsMigratingContent(false);
    }
  };

  // Handle Comprehensive Full Migration
  const handleFullMigration = async () => {
    if (
      !window.confirm(
        'هل تريد بدء الترحيل الشامل لجميع المنتجات، التصنيفات، البانرات، إعدادات الصرف، بيانات الإدارة والأرقام، والطلبات والعملاء إلى الخادم (whats.alattab.site) الآن؟'
      )
    ) {
      return;
    }
    setIsFullMigrating(true);
    try {
      const summary = await fullMigrationToServer({
        products,
        categories: INITIAL_CATEGORIES,
        banners: INITIAL_BANNERS,
        campaigns: campaigns.length > 0 ? campaigns : INITIAL_TREND_CAMPAIGNS,
        pricingSettings: pricingForm,
        storeSettings: storeSettingsForm,
        orders,
        users: firestoreUsers,
      });
      setFullMigrationResult(summary);
      setServerProductCount(summary.products);
      if (summary.serverSynced) {
        onShowToast('تم الترحيل الشامل والكامل إلى الخادم الجديد بنجاح! 🚀🎉', 'success');
        if (onRefreshProductsFromServer) {
          await onRefreshProductsFromServer();
        }
      } else {
        onShowToast('اكتمل الترحيل جزئياً، يرجى مراجعة تفاصيل التقرير', 'info');
      }
    } catch (e: any) {
      onShowToast(`فشل الترحيل الشامل: ${e.message}`, 'error');
    } finally {
      setIsFullMigrating(false);
    }
  };

  // Export JSON Backup
  const handleExportBackup = () => {
    const backupData = {
      exportDate: new Date().toISOString(),
      server: 'whats.alattab.site',
      products,
      categories: INITIAL_CATEGORIES,
      banners: INITIAL_BANNERS,
      campaigns,
      pricingSettings: pricingForm,
      storeSettings: storeSettingsForm,
      orders,
      users: firestoreUsers,
    };
    const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `altakhfid-full-backup-${new Date().toISOString().slice(0, 10)}.json`;
    link.click();
    URL.revokeObjectURL(url);
    onShowToast('تم تنزيل النسخة الاحتياطية بنجاح 💾', 'success');
  };

  // Import JSON Backup
  const handleImportBackup = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const text = await file.text();
      const parsed = JSON.parse(text);
      if (parsed.storeSettings) setStoreSettingsForm(parsed.storeSettings);
      if (parsed.pricingSettings) setPricingForm(parsed.pricingSettings);
      onShowToast('تم استيراد الملف بنجاح! اضغط الآن على "الترحيل الشامل" لحفظه بالخادم', 'info');
    } catch {
      onShowToast('الملف غير صالح أو تالف', 'error');
    }
  };

  // Handle Create Product
  const handleCreateProductSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const priceNum = Number(newProdPrice);
    if (!newProdName || isNaN(priceNum) || priceNum <= 0) {
      onShowToast('يرجى كتابة اسم صحيح وسعر مناسب', 'error');
      return;
    }

    setIsSavingProduct(true);
    const newProd: Product = {
      id: `prod-${Date.now()}`,
      name: newProdName,
      price: priceNum,
      originalPrice: newProdOriginalPrice ? Number(newProdOriginalPrice) : priceNum * 1.3,
      discountPrice: priceNum,
      category: newProdCategory,
      categoryId: newProdCategory,
      categories: ['all', newProdCategory],
      image: newProdImage || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewsCount: 1,
    };

    try {
      // 1. Save to custom server
      await createProductApi(newProd);
      // 2. Add to app state
      onSaveProduct(newProd);
      onShowToast('تم حفظ المنتج ورفعه إلى الخادم الجديد بنجاح ✅', 'success');
      setIsAddingProduct(false);
      setNewProdName('');
      setNewProdPrice('');
      setNewProdOriginalPrice('');
      setNewProdImage('');
    } catch (err: any) {
      onShowToast(`خطأ في رفع المنتج: ${err.message}`, 'error');
    } finally {
      setIsSavingProduct(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-2 sm:p-4 bg-black/60 backdrop-blur-xs transition-opacity duration-300">
      <div
        className="bg-white w-full max-w-4xl h-[90vh] rounded-3xl shadow-2xl overflow-hidden flex flex-col animate-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Admin Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-900 text-white">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-600 flex items-center justify-center text-white shadow-md">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-black text-base sm:text-lg">لوحة تحكم الإدارة</h2>
                <span className="text-[10px] bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded-full border border-emerald-500/30 flex items-center gap-1 font-mono">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                  whats.alattab.site
                </span>
              </div>
              <div className="flex items-center gap-2 text-xs text-slate-300">
                <span>المشرف: بشير نجيب محرز التبالي</span>
                <span className="text-amber-400 font-mono">782996982</span>
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-full text-slate-400 hover:text-white hover:bg-slate-800 transition-all"
            aria-label="إغلاق"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center gap-2 px-6 py-2.5 bg-slate-100 border-b border-slate-200 overflow-x-auto no-scrollbar">
          <button
            onClick={() => setActiveTab('orders')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'orders'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <ShoppingBag className="w-4 h-4" />
            <span>الطلبات الواردة ({orders.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('products')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'products'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <Package className="w-4 h-4" />
            <span>المنتجات ({products.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('pricing')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'pricing'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <DollarSign className="w-4 h-4" />
            <span>التسعيرات والعملات</span>
          </button>

          <button
            onClick={() => setActiveTab('store-settings')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'store-settings'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <Phone className="w-4 h-4" />
            <span>بيانات الإدارة والأرقام</span>
          </button>

          <button
            onClick={() => setActiveTab('migration')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'migration'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <Server className="w-4 h-4" />
            <span>نقل الخادم والمزامنة</span>
          </button>

          <button
            onClick={() => setActiveTab('customers')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'customers'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <Users className="w-4 h-4" />
            <span>العملاء</span>
          </button>

          <button
            onClick={() => setActiveTab('trends')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'trends'
                ? 'bg-purple-600 text-white shadow-xs'
                : 'bg-white text-slate-700 hover:bg-slate-200/80'
            }`}
          >
            <Flame className="w-4 h-4" />
            <span>الحملات</span>
          </button>

          <button
            onClick={() => setActiveTab('sales-report')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
              activeTab === 'sales-report'
                ? 'bg-emerald-600 text-white shadow-xs'
                : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
            }`}
          >
            <Printer className="w-4 h-4" />
            <span>تقرير المبيعات والطباعة</span>
          </button>
        </div>

        {/* Tab Content */}
        <div className="flex-1 overflow-y-auto p-6 bg-slate-50/50">
          {/* ORDERS TAB */}
          {activeTab === 'orders' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm text-slate-800">سجل طلبات الشراء ({orders.length})</h3>
                  <p className="text-xs text-slate-500">إدارة ومتابعة تسليم وتأكيد الطلبات ومزامنتها مع الخادم</p>
                </div>
                {orders.length > 0 && (
                  <button
                    onClick={handleSyncOrdersToServer}
                    className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 bg-purple-50 text-purple-700 hover:bg-purple-100 rounded-xl transition-all"
                  >
                    <CloudUpload className="w-3.5 h-3.5" />
                    <span>مزامنة الطلبات مع الخادم</span>
                  </button>
                )}
              </div>

              {orders.length === 0 ? (
                <div className="bg-white p-8 rounded-2xl text-center border border-slate-100 text-slate-500 text-xs">
                  لا توجد طلبات واردة حتى الآن.
                </div>
              ) : (
                orders.map((ord) => (
                  <div key={ord.id} className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs space-y-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-black text-purple-700 font-mono">#{ord.orderNumber || ord.id}</span>
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            ord.status === 'delivered'
                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                              : ord.status === 'in_shipping'
                              ? 'bg-blue-50 text-blue-700 border border-blue-200'
                              : ord.status === 'cancelled'
                              ? 'bg-rose-50 text-rose-700 border border-rose-200'
                              : 'bg-amber-50 text-amber-700 border border-amber-200'
                          }`}>
                            {ord.status === 'delivered' ? 'تم التسليم' : ord.status === 'in_shipping' ? 'قيد التوصيل' : ord.status === 'cancelled' ? 'ملغي' : 'جديد'}
                          </span>
                        </div>
                        <div className="text-[11px] text-slate-500 mt-0.5">
                          {ord.customerName} - <span className="font-mono text-slate-700">{ord.customerPhone || (ord as any).phone || ''}</span> ({ord.governorate})
                        </div>
                      </div>
                      <span className="text-xs font-black text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-xl">
                        {safeFormatNumber(ord.total)} {ord.currency || 'ر.ي'}
                      </span>
                    </div>

                    {ord.items && ord.items.length > 0 && (
                      <div className="text-[11px] text-slate-600 bg-slate-50 p-2 rounded-xl">
                        {ord.items.map((it, idx) => (
                          <div key={idx} className="flex justify-between py-0.5">
                            <span>{it.quantity}x {it.productName || (it as any).name || 'منتج'}</span>
                            <span className="font-mono text-slate-500">{safeFormatNumber(it.price * it.quantity)}</span>
                          </div>
                        ))}
                      </div>
                    )}

                    <div className="flex items-center justify-between pt-1 border-t border-slate-100 text-xs">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleUpdateOrder(ord.id, 'delivered', true)}
                          className="font-bold px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition-all flex items-center gap-1 text-[11px]"
                        >
                          <CheckCircle className="w-3 h-3" />
                          <span>تم التسليم والدفع</span>
                        </button>
                        <button
                          onClick={() => handleUpdateOrder(ord.id, 'in_shipping', ord.isPaid)}
                          className="font-bold px-2.5 py-1 rounded-lg bg-blue-50 text-blue-700 hover:bg-blue-100 transition-all text-[11px]"
                        >
                          جاري التوصيل
                        </button>
                        <button
                          onClick={() => handleUpdateOrder(ord.id, 'cancelled', false)}
                          className="font-bold px-2 py-1 rounded-lg text-slate-500 hover:bg-slate-100 transition-all text-[11px]"
                        >
                          إلغاء
                        </button>
                      </div>

                      <button
                        onClick={() => handleDeleteOrder(ord.id)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all"
                        title="حذف الطلب"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}

          {/* PRODUCTS TAB */}
          {activeTab === 'products' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm text-slate-800">أصناف المتجر ({products.length})</h3>
                  <p className="text-xs text-slate-500">مربوطة بالخادم الجديد whats.alattab.site</p>
                </div>
                <button
                  onClick={() => setIsAddingProduct(true)}
                  className="flex items-center gap-1.5 bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold px-3.5 py-2 rounded-xl transition-all shadow-xs"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة منتج جديد</span>
                </button>
              </div>

              {/* Add Product Inline Form */}
              {isAddingProduct && (
                <form
                  onSubmit={handleCreateProductSubmit}
                  className="bg-white p-5 rounded-2xl border-2 border-purple-200 shadow-sm space-y-3 animate-in fade-in duration-200"
                >
                  <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                    <h4 className="text-xs font-bold text-slate-800">إضافة منتج وحفظه مباشرة في الخادم</h4>
                    <button
                      type="button"
                      onClick={() => setIsAddingProduct(false)}
                      className="text-slate-400 hover:text-slate-600 p-1"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">اسم المنتج</label>
                      <input
                        type="text"
                        required
                        value={newProdName}
                        onChange={(e) => setNewProdName(e.target.value)}
                        placeholder="مثلاً: فستان سهرة مخملي"
                        className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>

                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">التصنيف</label>
                      <select
                        value={newProdCategory}
                        onChange={(e) => setNewProdCategory(e.target.value)}
                        className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      >
                        <option value="women">نسائي</option>
                        <option value="men">رجالي</option>
                        <option value="kids">أطفال</option>
                        <option value="shoes">أحذية</option>
                        <option value="bags">حقائب</option>
                        <option value="accessories">إكسسوارات</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">السعر المخفض (بالريال السعودي أو اليمني)</label>
                      <input
                        type="number"
                        required
                        value={newProdPrice}
                        onChange={(e) => setNewProdPrice(e.target.value)}
                        placeholder="120"
                        className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>

                    <div>
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">السعر الأصلي (قبل الخصم)</label>
                      <input
                        type="number"
                        value={newProdOriginalPrice}
                        onChange={(e) => setNewProdOriginalPrice(e.target.value)}
                        placeholder="240"
                        className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>

                    <div className="sm:col-span-2">
                      <label className="block text-[11px] font-bold text-slate-700 mb-1">رابط صورة المنتج (URL)</label>
                      <input
                        type="url"
                        value={newProdImage}
                        onChange={(e) => setNewProdImage(e.target.value)}
                        placeholder="https://images.unsplash.com/..."
                        className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setIsAddingProduct(false)}
                      className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 bg-slate-100 hover:bg-slate-200"
                    >
                      إلغاء
                    </button>
                    <button
                      type="submit"
                      disabled={isSavingProduct}
                      className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-purple-600 hover:bg-purple-700 flex items-center gap-1.5"
                    >
                      {isSavingProduct && <RefreshCw className="w-3.5 h-3.5 animate-spin" />}
                      <span>حفظ المنتج في الخادم</span>
                    </button>
                  </div>
                </form>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {products.map((p) => (
                  <div
                    key={p.id}
                    className="bg-white p-3 rounded-2xl border border-slate-200 flex items-center gap-3 justify-between"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <img src={p.image} alt={p.name} className="w-14 h-14 object-cover rounded-xl shrink-0" />
                      <div className="min-w-0">
                        <h4 className="text-xs font-bold text-slate-800 truncate">{p.name}</h4>
                        <span className="text-xs font-black text-purple-700 block mt-0.5">
                          {safeFormatNumber(p.price)} {p.price < 1000 ? 'ر.س' : 'ر.ي'}
                        </span>
                        <span className="text-[10px] text-slate-400 block">{p.category}</span>
                      </div>
                    </div>

                    <button
                      onClick={async () => {
                        if (window.confirm(`هل أنت متأكد من حذف المنتج: ${p.name}؟`)) {
                          await deleteProductApi(p.id);
                          onDeleteProduct(p.id);
                          onShowToast('تم حذف المنتج من الخادم بنجاح', 'info');
                        }
                      }}
                      className="p-2 text-slate-400 hover:text-rose-600 rounded-xl hover:bg-rose-50 transition-all shrink-0"
                      title="حذف المنتج"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* PRICING TAB */}
          {activeTab === 'pricing' && (
            <div className="space-y-5">
              <div>
                <h3 className="font-bold text-sm text-slate-800">إدارة أسعار الصرف والتسعيرات</h3>
                <p className="text-xs text-slate-500">
                  تحديد أسعار الصرف ومعدلات تحويل الريال السعودي والدولار مع الحفظ المباشر في الخادم
                </p>
              </div>

              <form onSubmit={handleSavePricing} className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      سعر صرف الريال السعودي (شمال / صنعاء)
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        required
                        value={pricingForm.sarToYerRateNorth}
                        onChange={(e) =>
                          setPricingForm((prev) => ({ ...prev, sarToYerRateNorth: Number(e.target.value) }))
                        }
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 pl-12"
                      />
                      <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                    </div>
                    <span className="text-[10px] text-slate-400 block mt-1">القيمة الافتراضية المعتمدة: 140 ر.ي</span>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      سعر صرف الريال السعودي (جنوب / عدن)
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        required
                        value={pricingForm.sarToYerRateSouth}
                        onChange={(e) =>
                          setPricingForm((prev) => ({ ...prev, sarToYerRateSouth: Number(e.target.value) }))
                        }
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 pl-12"
                      />
                      <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                    </div>
                    <span className="text-[10px] text-slate-400 block mt-1">القيمة الافتراضية المعتمدة: 520 ر.ي</span>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      سعر صرف الدولار (شمال / صنعاء)
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        required
                        value={pricingForm.usdToYerRateNorth}
                        onChange={(e) =>
                          setPricingForm((prev) => ({ ...prev, usdToYerRateNorth: Number(e.target.value) }))
                        }
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 pl-12"
                      />
                      <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      سعر صرف الدولار (جنوب / عدن)
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        required
                        value={pricingForm.usdToYerRateSouth}
                        onChange={(e) =>
                          setPricingForm((prev) => ({ ...prev, usdToYerRateSouth: Number(e.target.value) }))
                        }
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 pl-12"
                      />
                      <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      حد الشحن المجاني للطلبات
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        required
                        value={pricingForm.freeShippingThreshold}
                        onChange={(e) =>
                          setPricingForm((prev) => ({ ...prev, freeShippingThreshold: Number(e.target.value) }))
                        }
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 pl-12"
                      />
                      <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                    </div>
                    <span className="text-[10px] text-slate-400 block mt-1">شحن مجاني عند تجاوز هذا المبلغ</span>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      المنطقة الافتراضية المطبقة
                    </label>
                    <select
                      value={pricingForm.activeRegion || 'north'}
                      onChange={(e) =>
                        setPricingForm((prev) => ({ ...prev, activeRegion: e.target.value as 'north' | 'south' }))
                      }
                      className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                    >
                      <option value="north">محافظات الشمال (سعر الصرف 140 ر.ي / ر.س)</option>
                      <option value="south">محافظات الجنوب (سعر الصرف 520 ر.ي / ر.س)</option>
                    </select>
                  </div>
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                  <div className="text-[11px] text-slate-500 flex items-center gap-1.5">
                    <CheckCircle className="w-4 h-4 text-emerald-600" />
                    <span>تطبق هذه التسعيرات فوراً على كل عمليات العرض والتحويل وسلة الشراء</span>
                  </div>

                  <button
                    type="submit"
                    disabled={isSavingPricing}
                    className="flex items-center gap-1.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs px-5 py-2.5 rounded-xl shadow-xs transition-all"
                  >
                    {isSavingPricing ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Check className="w-3.5 h-3.5" />}
                    <span>حفظ ونشر التسعيرات على الخادم</span>
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* STORE & CONTACT SETTINGS TAB */}
          {activeTab === 'store-settings' && (
            <div className="space-y-5">
              <div>
                <h3 className="font-bold text-sm text-slate-800">بيانات الإدارة وأرقام التواصل والحسابات</h3>
                <p className="text-xs text-slate-500">
                  إدارة أرقام الواتساب، هواتف خدمة العملاء، أوقات العمل، ورسوم التوصيل وحسابات الدفع وتخزينها في الخادم
                </p>
              </div>

              <form onSubmit={handleSaveStoreSettings} className="space-y-4">
                {/* 1. Store Identity & Contact */}
                <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
                  <div className="flex items-center gap-2 border-b border-slate-100 pb-2.5">
                    <Building2 className="w-4 h-4 text-purple-600" />
                    <h4 className="text-xs font-bold text-slate-800">بيانات المتجر والاتصال المعتمدة</h4>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">اسم المتجر الرسمي</label>
                      <input
                        type="text"
                        required
                        value={storeSettingsForm.storeName}
                        onChange={(e) => setStoreSettingsForm((prev) => ({ ...prev, storeName: e.target.value }))}
                        placeholder="متجر التخفيض الصح"
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">
                        رقم الواتساب المعتمد (الدردشة والطلبات)
                      </label>
                      <div className="relative">
                        <input
                          type="text"
                          required
                          value={storeSettingsForm.whatsappNumber}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({ ...prev, whatsappNumber: e.target.value }))
                          }
                          placeholder="782996982"
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                          dir="ltr"
                        />
                        <Phone className="w-3.5 h-3.5 text-purple-600 absolute right-3 top-3" />
                      </div>
                      <span className="text-[10px] text-slate-400 block mt-1">يظهر للعملاء في نافذة الدعم وزر الواتساب السريع</span>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رقم الاتصال المباشر الأساسي</label>
                      <div className="relative">
                        <input
                          type="text"
                          required
                          value={storeSettingsForm.primaryPhone}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({ ...prev, primaryPhone: e.target.value }))
                          }
                          placeholder="782996982"
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                          dir="ltr"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رقم الاتصال الثانوي / الطوارئ</label>
                      <div className="relative">
                        <input
                          type="text"
                          value={storeSettingsForm.secondaryPhone}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({ ...prev, secondaryPhone: e.target.value }))
                          }
                          placeholder="771053370"
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                          dir="ltr"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">ساعات وأوقات الدعم</label>
                      <input
                        type="text"
                        value={storeSettingsForm.supportHours}
                        onChange={(e) =>
                          setStoreSettingsForm((prev) => ({ ...prev, supportHours: e.target.value }))
                        }
                        placeholder="9:00 ص - 11:00 م"
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">عنوان المتجر أو المركز الرئيسي</label>
                      <input
                        type="text"
                        value={storeSettingsForm.address}
                        onChange={(e) => setStoreSettingsForm((prev) => ({ ...prev, address: e.target.value }))}
                        placeholder="صنعاء - اليمن (توصيل لجميع المحافظات)"
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">رسالة الترحيب وتنويه الدعم</label>
                    <textarea
                      rows={2}
                      value={storeSettingsForm.supportNotice}
                      onChange={(e) =>
                        setStoreSettingsForm((prev) => ({ ...prev, supportNotice: e.target.value }))
                      }
                      placeholder="فريقنا متواجد لخدمتكم والإجابة على كافة استفساراتكم ومتابعة طلباتكم على مدار الساعة"
                      className="w-full text-xs p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 resize-none"
                    />
                  </div>
                </div>

                {/* 2. Delivery & Free Shipping Threshold */}
                <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
                  <div className="flex items-center gap-2 border-b border-slate-100 pb-2.5">
                    <MapPin className="w-4 h-4 text-emerald-600" />
                    <h4 className="text-xs font-bold text-slate-800">رسوم التوصيل والشحن المجاني</h4>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رسوم التوصيل (ريال يمني)</label>
                      <div className="relative">
                        <input
                          type="number"
                          value={storeSettingsForm.deliveryFeeYer}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({
                              ...prev,
                              deliveryFeeYer: Number(e.target.value) || 0,
                            }))
                          }
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                        />
                        <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رسوم التوصيل (ريال سعودي)</label>
                      <div className="relative">
                        <input
                          type="number"
                          value={storeSettingsForm.deliveryFeeSar}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({
                              ...prev,
                              deliveryFeeSar: Number(e.target.value) || 0,
                            }))
                          }
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                        />
                        <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.س</span>
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">الحد الأدنى للتوصيل المجاني</label>
                      <div className="relative">
                        <input
                          type="number"
                          value={storeSettingsForm.freeDeliveryThresholdYer}
                          onChange={(e) =>
                            setStoreSettingsForm((prev) => ({
                              ...prev,
                              freeDeliveryThresholdYer: Number(e.target.value) || 0,
                            }))
                          }
                          className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                        />
                        <span className="absolute left-3 top-2.5 text-xs text-slate-400 font-bold">ر.ي</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 3. Payment Accounts */}
                <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
                  <div className="flex items-center gap-2 border-b border-slate-100 pb-2.5">
                    <CreditCard className="w-4 h-4 text-purple-600" />
                    <h4 className="text-xs font-bold text-slate-800">بيانات وأرقام حسابات السداد والدفع</h4>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رقم حساب بنك الكريمي المميز</label>
                      <input
                        type="text"
                        value={storeSettingsForm.kuraimiAccount || ''}
                        onChange={(e) =>
                          setStoreSettingsForm((prev) => ({ ...prev, kuraimiAccount: e.target.value }))
                        }
                        placeholder="مثلاً: 3001234567"
                        className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                        dir="ltr"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رقم محفظة ون كاش (OneCash)</label>
                      <input
                        type="text"
                        value={storeSettingsForm.oneCashAccount || ''}
                        onChange={(e) =>
                          setStoreSettingsForm((prev) => ({ ...prev, oneCashAccount: e.target.value }))
                        }
                        placeholder="782996982"
                        className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                        dir="ltr"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">رقم محفظة جوالي (Jawaly)</label>
                      <input
                        type="text"
                        value={storeSettingsForm.jawalyAccount || ''}
                        onChange={(e) =>
                          setStoreSettingsForm((prev) => ({ ...prev, jawalyAccount: e.target.value }))
                        }
                        placeholder="771053370"
                        className="w-full text-xs font-mono font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500 text-left"
                        dir="ltr"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 mb-1">اسم المستلم لحوالات النجم والصرافين</label>
                      <input
                        type="text"
                        value={storeSettingsForm.alNajmName || ''}
                        onChange={(e) =>
                          setStoreSettingsForm((prev) => ({ ...prev, alNajmName: e.target.value }))
                        }
                        placeholder="بشير نجيب محرز التبالي"
                        className="w-full text-xs font-bold p-2.5 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-purple-500"
                      />
                    </div>
                  </div>
                </div>

                {/* Submit button */}
                <div className="pt-2 flex items-center justify-between">
                  <div className="text-[11px] text-slate-500 flex items-center gap-1.5">
                    <CheckCircle className="w-4 h-4 text-emerald-600" />
                    <span>تُحفظ البيانات مباشرة في الخادم whats.alattab.site وتُطبق فوراً</span>
                  </div>

                  <button
                    type="submit"
                    disabled={isSavingStoreSettings}
                    className="flex items-center gap-1.5 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs px-5 py-2.5 rounded-xl shadow-xs transition-all"
                  >
                    {isSavingStoreSettings ? (
                      <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    ) : (
                      <Check className="w-3.5 h-3.5" />
                    )}
                    <span>حفظ ونشر بيانات الإدارة في الخادم</span>
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* MIGRATION & SERVER SYNC TAB */}
          {activeTab === 'migration' && (
            <div className="space-y-5">
              <div>
                <h3 className="font-bold text-sm text-slate-800">مركز الترحيل الشامل والمزامنة مع الخادم</h3>
                <p className="text-xs text-slate-500">
                  نقل كافة بيانات المتجر (المنتجات، الأقسام، البانرات، الأسعار، أرقام الإدارة، الطلبات، العملاء) إلى الخادم المخصص whats.alattab.site
                </p>
              </div>

              {/* Server Connection Card */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600">
                      <Server className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-slate-800">الخادم الهدف: whats.alattab.site</h4>
                      <span className="text-[11px] font-mono text-emerald-600 flex items-center gap-1">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        نقطة النهاية النشطة: /takhfid/api/v2 & /takhfid/admin/api/content
                      </span>
                    </div>
                  </div>

                  <button
                    onClick={checkServerStatus}
                    disabled={isCheckingServer}
                    className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 bg-slate-100 hover:bg-slate-200 rounded-xl text-slate-700 transition-all"
                  >
                    <RefreshCw className={`w-3.5 h-3.5 ${isCheckingServer ? 'animate-spin' : ''}`} />
                    <span>فحص الاتصال</span>
                  </button>
                </div>

                {syncMessage && (
                  <div className="p-3 bg-purple-50 border border-purple-100 text-purple-800 text-xs rounded-xl flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 shrink-0 text-purple-600" />
                    <span>{syncMessage}</span>
                  </div>
                )}

                {/* Real-Time Database State Grid */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-1">
                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-center">
                    <span className="text-[10px] text-slate-500 block mb-0.5">المنتجات في الخادم</span>
                    <span className="text-base font-black text-purple-700 font-mono">
                      {serverProductCount !== null ? serverProductCount : '...'}
                    </span>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-center">
                    <span className="text-[10px] text-slate-500 block mb-0.5">التصنيفات والبانرات</span>
                    <span className="text-base font-black text-slate-800 font-mono">
                      {INITIAL_CATEGORIES.length} أقسام / {INITIAL_BANNERS.length} بانر
                    </span>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-center">
                    <span className="text-[10px] text-slate-500 block mb-0.5">أرقام التواصل وحسابات الدفع</span>
                    <span className="text-xs font-black text-emerald-600 font-mono">
                      {storeSettingsForm.whatsappNumber || 'مكتمل'}
                    </span>
                  </div>

                  <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-center">
                    <span className="text-[10px] text-slate-500 block mb-0.5">الطلبات والعملاء</span>
                    <span className="text-base font-black text-indigo-700 font-mono">
                      {orders.length} طلب / {firestoreUsers.length} عميل
                    </span>
                  </div>
                </div>
              </div>

              {/* ONE-CLICK FULL MIGRATION HERO ACTION */}
              <div className="bg-gradient-to-r from-purple-700 via-indigo-700 to-purple-800 text-white p-5 rounded-2xl shadow-lg space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center">
                      <CloudUpload className="w-5 h-5 text-amber-300" />
                    </div>
                    <div>
                      <h4 className="font-extrabold text-sm">الترحيل الشامل لجميع البيانات بنقرة واحدة</h4>
                      <p className="text-white/80 text-xs mt-0.5">
                        يرفع المنتجات، التصنيفات، البانرات، إعدادات الصرف، بيانات الإدارة والأرقام، والطلبات والعملاء دفعة واحدة إلى الخادم
                      </p>
                    </div>
                  </div>
                </div>

                <button
                  onClick={handleFullMigration}
                  disabled={isFullMigrating}
                  className="w-full py-3 px-4 rounded-xl bg-white hover:bg-slate-50 text-purple-800 font-black text-xs transition-all shadow-md flex items-center justify-center gap-2 cursor-pointer"
                >
                  {isFullMigrating ? (
                    <RefreshCw className="w-4 h-4 animate-spin text-purple-700" />
                  ) : (
                    <CheckCircle className="w-4 h-4 text-emerald-600" />
                  )}
                  <span>
                    {isFullMigrating
                      ? 'جاري ترحيل وحفظ جميع البيانات في الخادم الجديد...'
                      : 'بدء الترحيل الكامل والشامل إلى الخادم الآن 🚀'}
                  </span>
                </button>

                {fullMigrationResult && (
                  <div className="p-3 bg-white/10 rounded-xl border border-white/20 text-xs space-y-1 text-white">
                    <div className="font-bold flex items-center gap-1 text-emerald-300">
                      <Check className="w-4 h-4" />
                      <span>تقرير اكتمال الترحيل:</span>
                    </div>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-[11px] pt-1">
                      <span>المنتجات المرحلة: {fullMigrationResult.products}</span>
                      <span>التصنيفات: {fullMigrationResult.categories}</span>
                      <span>البانرات والحملات: {fullMigrationResult.banners + fullMigrationResult.campaigns}</span>
                      <span>إعدادات التسعير: {fullMigrationResult.pricingSettings ? '✅ نُقلت' : '⚠️'}</span>
                      <span>بيانات الإدارة والأرقام: {fullMigrationResult.storeSettings ? '✅ نُقلت' : '⚠️'}</span>
                      <span>الطلبات والعملاء: {fullMigrationResult.orders + fullMigrationResult.users}</span>
                    </div>
                    {fullMigrationResult.errors.length > 0 && (
                      <div className="text-amber-200 text-[10px] mt-1 pt-1 border-t border-white/10">
                        ملاحظات: {fullMigrationResult.errors.join(' | ')}
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Granular Individual Sync Operations */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="bg-white p-5 rounded-2xl border border-slate-200 flex flex-col justify-between space-y-3">
                  <div>
                    <div className="flex items-center gap-2 text-purple-700 font-bold text-xs mb-1">
                      <CloudUpload className="w-4 h-4" />
                      <span>نقل ومزامنة المنتجات للخادم ({products.length})</span>
                    </div>
                    <p className="text-[11px] text-slate-500 leading-relaxed">
                      رفع أصناف المتجر بالكامل وتخزينها في قاعدة بيانات الخادم الجديد.
                    </p>
                  </div>

                  <button
                    onClick={handleBulkMigrate}
                    disabled={isMigratingProducts}
                    className="w-full flex items-center justify-center gap-2 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs py-2.5 rounded-xl transition-all shadow-xs"
                  >
                    {isMigratingProducts ? <RefreshCw className="w-4 h-4 animate-spin" /> : <CloudUpload className="w-4 h-4" />}
                    <span>{isMigratingProducts ? 'جاري النقل والتخزين...' : 'نقل المنتجات إلى الخادم الآن'}</span>
                  </button>
                </div>

                <div className="bg-white p-5 rounded-2xl border border-slate-200 flex flex-col justify-between space-y-3">
                  <div>
                    <div className="flex items-center gap-2 text-indigo-700 font-bold text-xs mb-1">
                      <CloudUpload className="w-4 h-4" />
                      <span>مزامنة التصنيفات والبانرات وبيانات الإدارة</span>
                    </div>
                    <p className="text-[11px] text-slate-500 leading-relaxed">
                      حفظ إعدادات الأقسام، البانرات الترويجية، حملات الترند، وأرقام وهواتف الإدارة في الخادم.
                    </p>
                  </div>

                  <button
                    onClick={handleContentMigrate}
                    disabled={isMigratingContent}
                    className="w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs py-2.5 rounded-xl transition-all shadow-xs"
                  >
                    {isMigratingContent ? <RefreshCw className="w-4 h-4 animate-spin" /> : <CloudUpload className="w-4 h-4" />}
                    <span>{isMigratingContent ? 'جاري الرفع...' : 'رفع المحتوى والإعدادات'}</span>
                  </button>
                </div>
              </div>

              {/* Backup & Restore Tools */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-3">
                <h4 className="text-xs font-bold text-slate-800">أدوات النسخ الاحتياطي والاستعادة (JSON)</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={handleExportBackup}
                    className="flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-bold transition-all"
                  >
                    <Download className="w-4 h-4 text-purple-600" />
                    <span>تنزيل نسخة احتياطية كاملة (JSON)</span>
                  </button>

                  <label className="flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-bold transition-all cursor-pointer">
                    <Upload className="w-4 h-4 text-emerald-600" />
                    <span>استيراد ملف نسخة احتياطية</span>
                    <input type="file" accept=".json" onChange={handleImportBackup} className="hidden" />
                  </label>
                </div>
              </div>

              {/* Refresh from server */}
              {onRefreshProductsFromServer && (
                <div className="bg-white p-4 rounded-2xl border border-slate-200 flex items-center justify-between">
                  <div className="flex items-center gap-2 text-xs text-slate-700 font-bold">
                    <CloudDownload className="w-4 h-4 text-emerald-600" />
                    <span>تحديث منتجات المتجر الآن مباشرة من الخادم</span>
                  </div>
                  <button
                    onClick={async () => {
                      await onRefreshProductsFromServer();
                      onShowToast('تم تحديث المنتجات من الخادم بنجاح! 🔄', 'success');
                    }}
                    className="text-xs font-bold px-3 py-1.5 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 rounded-xl transition-all"
                  >
                    جلب المنتجات المحدثة
                  </button>
                </div>
              )}
            </div>
          )}

          {/* CUSTOMERS TAB */}
          {activeTab === 'customers' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-sm text-slate-800">العملاء المسجلين ({firestoreUsers.length})</h3>
                  <p className="text-xs text-slate-500">إدارة حسابات العملاء ومزامنتها مع الخادم</p>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={handleSyncUsersToServer}
                    className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 bg-purple-50 text-purple-700 hover:bg-purple-100 rounded-xl transition-all"
                  >
                    <CloudUpload className="w-3.5 h-3.5" />
                    <span>مزامنة العملاء مع الخادم</span>
                  </button>
                  <button
                    onClick={loadUsers}
                    disabled={isLoadingUsers}
                    className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-all text-slate-700"
                  >
                    <RefreshCw className={`w-3.5 h-3.5 ${isLoadingUsers ? 'animate-spin' : ''}`} />
                    <span>تحديث</span>
                  </button>
                </div>
              </div>

              {isLoadingUsers ? (
                <div className="p-8 text-center text-xs text-slate-500">جاري تحميل العملاء...</div>
              ) : firestoreUsers.length === 0 ? (
                <div className="bg-white p-8 rounded-2xl text-center border border-slate-100 text-slate-500 text-xs">
                  لا يوجد عملاء مسجلين حالياً في قاعدة البيانات.
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {firestoreUsers.map((u) => (
                    <div
                      key={u.uid}
                      className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between"
                    >
                      <div>
                        <h4 className="text-xs font-bold text-slate-800">
                          {u.firstName || 'عميل'} {u.lastName || ''}
                        </h4>
                        <div className="flex items-center gap-1.5 text-[11px] text-slate-500 mt-1">
                          <Phone className="w-3 h-3 text-purple-600" />
                          <span className="font-mono">{u.phone}</span>
                        </div>
                        <span className="text-[10px] text-slate-400 block mt-0.5">
                          {u.governorate || 'اليمن'}
                        </span>
                      </div>
                      <button
                        onClick={() => handleDeleteUser(u.uid)}
                        className="p-2 text-slate-400 hover:text-rose-600 rounded-xl hover:bg-rose-50 transition-all"
                        title="حذف العميل"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* TRENDS TAB */}
          {activeTab === 'trends' && (
            <div className="space-y-4">
              <h3 className="font-bold text-sm text-slate-800">حملات الترندات المعروضة</h3>
              <div className="space-y-3">
                {campaigns.map((c) => (
                  <div
                    key={c.id}
                    className="bg-white p-4 rounded-2xl border border-slate-200/80 flex items-center justify-between"
                  >
                    <div className="flex items-center gap-3">
                      <img src={c.bgImage} alt={c.title} className="w-16 h-12 object-cover rounded-xl" />
                      <div>
                        <span className="text-purple-600 font-bold text-xs">{c.hashtag}</span>
                        <h4 className="text-xs font-bold text-slate-800">{c.title}</h4>
                      </div>
                    </div>
                    <span className="text-xs font-bold bg-purple-50 text-purple-700 px-2.5 py-1 rounded-xl">
                      {c.daysLeft || 'نشط'}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* SALES REPORT & PRINT TAB */}
          {activeTab === 'sales-report' && (
            <div className="space-y-5">
              {/* Header & Print Actions */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-4 rounded-2xl border border-slate-200">
                <div>
                  <h3 className="font-bold text-sm text-slate-800 flex items-center gap-2">
                    <FileText className="w-4 h-4 text-emerald-600" />
                    <span>تقرير وتفاصيل المبيعات الشامل</span>
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    استعراض المبيعات حسب المحافظات والفترات مع الباركود والكميات وإمكانية الطباعة
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={handlePrintReport}
                    className="flex items-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-4 py-2 rounded-xl transition-all shadow-xs cursor-pointer"
                  >
                    <Printer className="w-4 h-4" />
                    <span>طباعة التقرير (Print)</span>
                  </button>
                </div>
              </div>

              {/* Filter Controls */}
              <div className="bg-white p-4 rounded-2xl border border-slate-200 grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
                {/* Governorate Filter */}
                <div>
                  <label className="block text-[11px] font-bold text-slate-600 mb-1">المحافظة</label>
                  <select
                    value={reportGovernorate}
                    onChange={(e) => setReportGovernorate(e.target.value)}
                    className="w-full p-2 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-emerald-500 font-bold text-slate-700"
                  >
                    <option value="all">كل المحافظات</option>
                    <option value="صنعاء">صنعاء</option>
                    <option value="عدن">عدن</option>
                    <option value="تعز">تعز</option>
                    <option value="إب">إب</option>
                    <option value="الحديدة">الحديدة</option>
                    <option value="حضرموت">حضرموت</option>
                    <option value="ذمار">ذمار</option>
                    <option value="لحج">لحج</option>
                    <option value="أبين">أبين</option>
                    <option value="مأرب">مأرب</option>
                  </select>
                </div>

                {/* Start Date */}
                <div>
                  <label className="block text-[11px] font-bold text-slate-600 mb-1">من تاريخ</label>
                  <input
                    type="date"
                    value={reportStartDate}
                    onChange={(e) => setReportStartDate(e.target.value)}
                    className="w-full p-2 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-emerald-500 text-slate-700 font-mono"
                  />
                </div>

                {/* End Date */}
                <div>
                  <label className="block text-[11px] font-bold text-slate-600 mb-1">إلى تاريخ</label>
                  <input
                    type="date"
                    value={reportEndDate}
                    onChange={(e) => setReportEndDate(e.target.value)}
                    className="w-full p-2 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-emerald-500 text-slate-700 font-mono"
                  />
                </div>

                {/* Search Text */}
                <div>
                  <label className="block text-[11px] font-bold text-slate-600 mb-1">بحث بالاسم أو الصنف</label>
                  <div className="relative">
                    <input
                      type="text"
                      value={reportSearchQuery}
                      onChange={(e) => setReportSearchQuery(e.target.value)}
                      placeholder="بحث..."
                      className="w-full p-2 pl-7 rounded-xl border border-slate-200 focus:outline-hidden focus:ring-2 focus:ring-emerald-500 text-slate-700"
                    />
                    <Search className="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-2.5" />
                  </div>
                </div>
              </div>

              {/* Summary Stats Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] text-slate-500 font-bold block">إجمالي عدد الأصناف المباعة</span>
                  <span className="text-xl font-black text-purple-700 font-mono mt-1 block">
                    {salesReportData.totalItemsCount} صنف
                  </span>
                </div>

                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] text-slate-500 font-bold block">إجمالي عدد القطع (الكميات)</span>
                  <span className="text-xl font-black text-blue-600 font-mono mt-1 block">
                    {salesReportData.totalQuantity} قطعة
                  </span>
                </div>

                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] text-slate-500 font-bold block">إجمالي قيمة المبيعات التقديرية</span>
                  <span className="text-xl font-black text-emerald-600 font-mono mt-1 block">
                    {safeFormatNumber(salesReportData.totalRevenue)} ر.ي
                  </span>
                </div>
              </div>

              {/* Report Table */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden print:border-none print:shadow-none">
                <div className="overflow-x-auto">
                  <table className="w-full text-right text-xs">
                    <thead className="bg-slate-50 text-slate-600 border-b border-slate-200 font-bold text-[11px]">
                      <tr>
                        <th className="p-3">#</th>
                        <th className="p-3">الباركود</th>
                        <th className="p-3">اسم الصنف / المنتج</th>
                        <th className="p-3 text-center">الكمية</th>
                        <th className="p-3">سعر الوحدة</th>
                        <th className="p-3">الإجمالي</th>
                        <th className="p-3">المحافظة</th>
                        <th className="p-3">العميل</th>
                        <th className="p-3">التاريخ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {salesReportData.rows.length === 0 ? (
                        <tr>
                          <td colSpan={9} className="p-8 text-center text-slate-400 text-xs">
                            لا توجد مبيعات أو طلبات مطابقة لمعايير البحث المحددة.
                          </td>
                        </tr>
                      ) : (
                        salesReportData.rows.map((row, idx) => (
                          <tr key={row.id} className="hover:bg-slate-50/80 transition-colors">
                            <td className="p-3 font-mono text-slate-400 text-[11px]">{idx + 1}</td>
                            <td className="p-3">
                              <div className="flex flex-col items-start gap-0.5">
                                <div className="font-mono text-[10px] bg-slate-100 px-1.5 py-0.5 rounded-sm text-slate-700 tracking-wider">
                                  ||||| | ||||| | |||
                                </div>
                                <span className="font-mono text-[10px] text-slate-500">{row.barcode}</span>
                              </div>
                            </td>
                            <td className="p-3 font-bold text-slate-800">{row.productName}</td>
                            <td className="p-3 text-center font-bold font-mono text-blue-700">{row.quantity}</td>
                            <td className="p-3 font-mono text-slate-600">{safeFormatNumber(row.unitPrice)}</td>
                            <td className="p-3 font-black font-mono text-emerald-600">{safeFormatNumber(row.totalPrice)}</td>
                            <td className="p-3 text-slate-600">{row.governorate}</td>
                            <td className="p-3 text-slate-600">{row.customerName}</td>
                            <td className="p-3 font-mono text-slate-500 text-[11px]">{row.date}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
