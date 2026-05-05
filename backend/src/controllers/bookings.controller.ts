import { Response, NextFunction } from 'express';
import { checkoutSchema, cancelSchema } from '../validators/schemas';
import * as bookingService from '../services/booking.service';
import { AuthRequest } from '../middleware/auth.middleware';

export async function checkout(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { paymentMethod } = checkoutSchema.parse(req.body);
    const booking = await bookingService.checkout(req.userId!, paymentMethod);
    res.status(201).json({ statusCode: 201, data: booking });
  } catch (err) {
    next(err);
  }
}

export async function listBookings(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const bookings = await bookingService.listBookings(req.userId!);
    res.json({ statusCode: 200, data: bookings });
  } catch (err) {
    next(err);
  }
}

export async function getBooking(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const booking = await bookingService.getBookingById(req.userId!, req.params.id);
    res.json({ statusCode: 200, data: booking });
  } catch (err) {
    next(err);
  }
}

export async function cancelBooking(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { reason } = cancelSchema.parse(req.body);
    const booking = await bookingService.cancelBooking(req.userId!, req.params.id, reason);
    res.json({ statusCode: 200, data: booking });
  } catch (err) {
    next(err);
  }
}
