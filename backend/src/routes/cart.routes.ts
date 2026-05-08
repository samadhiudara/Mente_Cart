import { Router } from 'express';
import * as cartController from '../controllers/cart.controller';
import { authenticate } from '../middleware/auth.middleware';

export const cartRouter = Router();

cartRouter.use(authenticate);

cartRouter.get('/', cartController.getCart);
cartRouter.post('/items', cartController.addItem);
cartRouter.patch('/items/:itemId', cartController.updateItem);
cartRouter.delete('/items/:itemId', cartController.removeItem);
