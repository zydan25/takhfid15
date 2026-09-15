import React, { useState } from 'react';
import { X, ChevronLeft, Grid } from 'lucide-react';
import type { Category, SubCategory } from '../types';

interface CategoryModalProps {
  isOpen: boolean;
  categories: Category[];
  selectedCategoryId: string;
  onClose: () => void;
  onSelectCategory: (categoryId: string) => void;
}

export const CategoryModal: React.FC<CategoryModalProps> = ({
  isOpen,
  categories,
  selectedCategoryId,
  onClose,
  onSelectCategory,
}) => {
  if (!isOpen) return null;

  const [activeCatId, setActiveCatId] = useState(selectedCategoryId || categories[0]?.id || 'women');
  const activeCategory = categories.find((c) => c.id === activeCatId) || categories[0];

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/60 backdrop-blur-xs transition-opacity duration-300">
      <div
        className="bg-white w-full max-w-md h-full shadow-2xl flex flex-col animate-in slide-in-from-left duration-300"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 bg-white">
          <div className="flex items-center gap-2">
            <Grid className="w-5 h-5 text-purple-700" />
            <h2 className="font-extrabold text-slate-800 text-base">جميع الأقسام</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-all"
            aria-label="إغلاق"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Categories Browser: Sidebar + Content */}
        <div className="flex-1 flex overflow-hidden">
          {/* Main Categories Sidebar */}
          <div className="w-28 bg-slate-50 border-l border-slate-200/80 overflow-y-auto py-2">
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setActiveCatId(cat.id)}
                className={`w-full py-3 px-2 text-right text-xs font-bold transition-all relative ${
                  activeCatId === cat.id
                    ? 'bg-white text-purple-700 font-black shadow-2xs'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
              >
                {activeCatId === cat.id && (
                  <span className="absolute right-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-purple-600 rounded-l-full" />
                )}
                <span className="block truncate">{cat.name}</span>
              </button>
            ))}
          </div>

          {/* Subcategories & Styles View */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {activeCategory && (
              <>
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-extrabold text-slate-800">{activeCategory.name}</h3>
                  <button
                    onClick={() => {
                      onSelectCategory(activeCategory.id);
                      onClose();
                    }}
                    className="text-xs text-purple-700 font-bold hover:underline"
                  >
                    عرض الكل
                  </button>
                </div>

                {/* Subcategories Grid */}
                {activeCategory.subCategories && (
                  <div className="grid grid-cols-2 gap-2.5">
                    {activeCategory.subCategories.map((sub) => (
                      <div
                        key={sub.id}
                        onClick={() => {
                          onSelectCategory(activeCategory.id);
                          onClose();
                        }}
                        className="bg-slate-50 hover:bg-purple-50/50 p-2.5 rounded-2xl border border-slate-100 text-center cursor-pointer transition-all group"
                      >
                        <img
                          src={sub.image}
                          alt={sub.name}
                          className="w-16 h-16 object-cover rounded-xl mx-auto mb-2 group-hover:scale-105 transition-transform"
                        />
                        <span className="text-xs font-bold text-slate-800 block truncate group-hover:text-purple-700">
                          {sub.name}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
