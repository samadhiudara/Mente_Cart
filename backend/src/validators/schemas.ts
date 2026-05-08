import { z } from 'zod';

// Auth
export const signupSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required').max(100),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1, 'Password required'),
});

// Services query
export const servicesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  category: z.string().optional(),
  search: z.string().optional(),
});

// Cart
export const addCartItemSchema = z.object({
  serviceId: z.string().length(24, 'Invalid serviceId'),
  slotDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD'),
  slotTime: z.string().regex(/^\d{2}:\d{2}$/, 'Time must be HH:MM'),
  quantity: z.number().int().min(1).default(1),
});

export const updateCartItemSchema = z.object({
  slotDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  slotTime: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  quantity: z.number().int().min(1).optional(),
});

// Checkout
export const checkoutSchema = z.object({
  paymentMethod: z.enum(['cash', 'pay_on_arrival', 'payhere']),
});

// Cancel
export const cancelSchema = z.object({
  reason: z.string().optional(),
});
