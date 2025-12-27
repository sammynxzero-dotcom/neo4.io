export interface Product {
  id: string;
  name: string;
  price: number;
  cost: number;
  stock: number;
  category: string;
  description: string;
  image?: string;
  barcode?: string;
}

export interface CartItem extends Product {
  quantity: number;
}

export type PaymentMethod = 'cash' | 'card' | 'pix';

export interface Payment {
  method: PaymentMethod;
  amount: number;
}

export interface Sale {
  id: string;
  date: string; // ISO string
  items: CartItem[];
  subtotal: number;
  discount: number;
  total: number;
  payments: Payment[]; // Changed from single paymentMethod to array
}

export interface SalesAnalysis {
  summary: string;
  recommendations: string[];
}

export enum View {
  POS = 'POS',
  INVENTORY = 'INVENTORY',
  DASHBOARD = 'DASHBOARD',
  SETTINGS = 'SETTINGS'
}

export interface AIProductSuggestion {
  description: string;
  category: string;
  suggestedPrice: number;
}