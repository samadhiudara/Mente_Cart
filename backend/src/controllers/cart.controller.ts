import { Response, NextFunction } from 'express';
import { addCartItemSchema, updateCartItemSchema } from '../validators/schemas';
import * as cartService from '../services/cart.service';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getCart(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const cart = await cartService.getCart(req.userId!);
    res.json({ statusCode: 200, data: cart });
  } catch (err) {
    next(err);
  }
}

export async function addItem(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { serviceId, slotDate, slotTime, quantity } = addCartItemSchema.parse(req.body);
    const cart = await cartService.addItem(req.userId!, serviceId, slotDate, slotTime, quantity);
    res.status(201).json({ statusCode: 201, data: cart });
  } catch (err) {
    next(err);
  }
}

export async function updateItem(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const updates = updateCartItemSchema.parse(req.body);
    const cart = await cartService.updateItem(req.userId!, req.params.itemId, updates);
    res.json({ statusCode: 200, data: cart });
  } catch (err) {
    next(err);
  }
}

export async function removeItem(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const cart = await cartService.removeItem(req.userId!, req.params.itemId);
    res.json({ statusCode: 200, data: cart });
  } catch (err) {
    next(err);
  }
}
