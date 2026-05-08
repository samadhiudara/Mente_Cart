import mongoose from 'mongoose';
import { Cart } from '../models/cart.model';
import { Service } from '../models/service.model';
import { AppError } from '../utils/AppError';

const CART_EXPIRY_MINUTES = parseInt(process.env.CART_EXPIRY_MINUTES || '15', 10);

function cartExpiry(): Date {
  const d = new Date();
  d.setMinutes(d.getMinutes() + CART_EXPIRY_MINUTES);
  return d;
}

export async function getCart(userId: string) {
  let cart = await Cart.findOne({ userId }).populate('items.serviceId', 'title image duration');
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
  }

  // Remove expired items
  const now = new Date();
  const originalCount = cart.items.length;
  cart.items = cart.items.filter((item) => item.expiresAt > now);
  if (cart.items.length !== originalCount) {
    await cart.save();
  }

  return buildCartSummary(cart);
}

export async function addItem(
  userId: string,
  serviceId: string,
  slotDate: string,
  slotTime: string,
  quantity: number
) {
  const service = await Service.findById(serviceId);
  if (!service || !service.isActive) {
    throw new AppError(404, 'Service not found', 'NOT_FOUND');
  }

  // Find the slot
  const slot = service.slots.find(
    (s) => s.date === slotDate && s.time === slotTime
  );
  if (!slot) {
    throw new AppError(404, 'Slot not found', 'SLOT_NOT_FOUND');
  }

  const available = slot.capacity - slot.booked;
  if (available < quantity) {
    throw new AppError(409, `Only ${available} spot(s) available`, 'SLOT_FULL');
  }

  let cart = await Cart.findOne({ userId });
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
  }

  // Remove expired items first
  const now = new Date();
  cart.items = cart.items.filter((item) => item.expiresAt > now);

  // Check for duplicate slot booking
  const duplicate = cart.items.find(
    (i) =>
      i.serviceId.toString() === serviceId &&
      i.slotDate === slotDate &&
      i.slotTime === slotTime
  );
  if (duplicate) {
    throw new AppError(
      409,
      'This service/slot is already in your cart',
      'CART_DUPLICATE'
    );
  }

  cart.items.push({
    _id: new mongoose.Types.ObjectId(),
    serviceId: new mongoose.Types.ObjectId(serviceId),
    slotDate,
    slotTime,
    quantity,
    price: service.price,
    expiresAt: cartExpiry(),
  });

  await cart.save();
  return buildCartSummary(cart);
}

export async function updateItem(
  userId: string,
  itemId: string,
  updates: { slotDate?: string; slotTime?: string; quantity?: number }
) {
  const cart = await Cart.findOne({ userId });
  if (!cart) throw new AppError(404, 'Cart not found', 'NOT_FOUND');

  const item = cart.items.find((i) => i._id.toString() === itemId);
  if (!item) throw new AppError(404, 'Cart item not found', 'NOT_FOUND');

  if (item.expiresAt < new Date()) {
    cart.items = cart.items.filter((i) => i._id.toString() !== itemId);
    await cart.save();
    throw new AppError(410, 'Cart item has expired', 'CART_ITEM_EXPIRED');
  }

  if (updates.slotDate) item.slotDate = updates.slotDate;
  if (updates.slotTime) item.slotTime = updates.slotTime;
  if (updates.quantity) item.quantity = updates.quantity;
  item.expiresAt = cartExpiry(); // Refresh expiry on update

  await cart.save();
  return buildCartSummary(cart);
}

export async function removeItem(userId: string, itemId: string) {
  const cart = await Cart.findOne({ userId });
  if (!cart) throw new AppError(404, 'Cart not found', 'NOT_FOUND');

  const before = cart.items.length;
  cart.items = cart.items.filter((i) => i._id.toString() !== itemId);
  if (cart.items.length === before) {
    throw new AppError(404, 'Cart item not found', 'NOT_FOUND');
  }

  await cart.save();
  return buildCartSummary(cart);
}

function buildCartSummary(cart: InstanceType<typeof Cart>) {
  const total = cart.items.reduce(
    (sum, i) => sum + i.price * i.quantity,
    0
  );
  return {
    _id: cart._id,
    userId: cart.userId,
    items: cart.items,
    itemCount: cart.items.length,
    total: Math.round(total * 100) / 100,
  };
}
