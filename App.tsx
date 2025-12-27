import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import POS from './components/POS';
import Inventory from './components/Inventory';
import Dashboard from './components/Dashboard';
import { Product, Sale, View } from './types';

const INITIAL_PRODUCTS: Product[] = [
  { id: '1', name: 'Café Expresso', price: 5.50, cost: 1.20, stock: 100, category: 'Bebidas', description: 'Café forte e encorpado.', image: 'https://picsum.photos/id/1060/200/200' },
  { id: '2', name: 'Pão de Queijo', price: 4.00, cost: 1.50, stock: 50, category: 'Alimentos', description: 'Tradicional pão de queijo mineiro.', image: 'https://picsum.photos/id/1084/200/200' },
  { id: '3', name: 'Suco de Laranja', price: 8.00, cost: 3.00, stock: 30, category: 'Bebidas', description: 'Suco natural feito na hora.', image: 'https://picsum.photos/id/1080/200/200' },
  { id: '4', name: 'Bolo de Cenoura', price: 7.50, cost: 2.50, stock: 15, category: 'Alimentos', description: 'Com cobertura de chocolate.', image: 'https://picsum.photos/id/292/200/200' },
];

const App: React.FC = () => {
  const [currentView, setCurrentView] = useState<View>(View.POS);
  
  // Theme State
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const saved = localStorage.getItem('theme');
    return saved === 'dark';
  });

  const [products, setProducts] = useState<Product[]>(() => {
    const saved = localStorage.getItem('products');
    return saved ? JSON.parse(saved) : INITIAL_PRODUCTS;
  });
  const [sales, setSales] = useState<Sale[]>(() => {
    const saved = localStorage.getItem('sales');
    return saved ? JSON.parse(saved) : [];
  });

  // Apply Theme
  useEffect(() => {
    const root = window.document.documentElement;
    if (isDarkMode) {
      root.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      root.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [isDarkMode]);

  // Persistence
  useEffect(() => {
    localStorage.setItem('products', JSON.stringify(products));
  }, [products]);

  useEffect(() => {
    localStorage.setItem('sales', JSON.stringify(sales));
  }, [sales]);

  // Actions
  const handleAddProduct = (product: Product) => {
    setProducts(prev => [...prev, product]);
  };

  const handleUpdateProduct = (updated: Product) => {
    setProducts(prev => prev.map(p => p.id === updated.id ? updated : p));
  };

  const handleDeleteProduct = (id: string) => {
    setProducts(prev => prev.filter(p => p.id !== id));
  };

  const handleCompleteSale = (sale: Sale) => {
    // 1. Add sale record
    setSales(prev => [sale, ...prev]);
    
    // 2. Decrement stock
    setProducts(prev => prev.map(p => {
      const soldItem = sale.items.find(i => i.id === p.id);
      if (soldItem) {
        return { ...p, stock: p.stock - soldItem.quantity };
      }
      return p;
    }));
  };

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900 overflow-hidden font-sans transition-colors duration-200">
      <Sidebar 
        currentView={currentView} 
        onChangeView={setCurrentView} 
        isDarkMode={isDarkMode}
        toggleTheme={() => setIsDarkMode(!isDarkMode)}
      />
      
      <main className="flex-1 overflow-hidden relative">
        {currentView === View.POS && (
          <POS products={products} onCompleteSale={handleCompleteSale} />
        )}
        {currentView === View.INVENTORY && (
          <Inventory 
            products={products}
            onAddProduct={handleAddProduct}
            onUpdateProduct={handleUpdateProduct}
            onDeleteProduct={handleDeleteProduct}
          />
        )}
        {currentView === View.DASHBOARD && (
          <Dashboard sales={sales} />
        )}
      </main>
    </div>
  );
};

export default App;