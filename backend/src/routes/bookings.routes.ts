import { Router } from 'express';
import * as bookingsController from '../controllers/bookings.controller';
import { authenticate } from '../middleware/auth.middleware';

export const bookingsRouter = Router();

bookingsRouter.use(authenticate);

bookingsRouter.post('/checkout', bookingsController.checkout);
bookingsRouter.get('/', bookingsController.listBookings);
bookingsRouter.get('/:id', bookingsController.getBooking);
bookingsRouter.post('/:id/cancel', bookingsController.cancelBooking);
