import mongoose from 'mongoose';
import {
  Booking,
  BookingStatus,
  ALLOWED_TRANSITIONS,
  PaymentMethod,
} from '../models/booking.model';
import { Cart } from '../models/cart.model';
import { Service } from '../models/service.model';
import { AppError } from '../utils/AppError';
import { logger } from '../utils/logger';

const MAX_BOOKINGS_PER_DAY = parseInt(process.env.MAX_BOOKINGS_PER_DAY || '3', 10);

export async function checkout(userId: string, paymentMethod: PaymentMethod) {
  const cart = await Cart.findOne({ userId });
  if (!cart || cart.items.length === 0) {
    throw new AppError(400, 'Cart is empty', 'CART_EMPTY');
  }

  // Remove expired items
  const now = new Date();
  cart.items = cart.items.filter((item) => item.expiresAt > now);
  if (cart.items.length === 0) {
    await cart.save();
    throw new AppError(410, 'All cart items have expired', 'CART_EXPIRED');
  }

  // Check per-day booking limit
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const todayCount = await Booking.countDocuments({
    userId,
    createdAt: { $gte: todayStart, $lte: todayEnd },
    status: { $nin: ['cancelled', 'failed'] },
  });

  if (todayCount + 1 > MAX_BOOKINGS_PER_DAY) {
    throw new AppError(
      429,
      `Maximum ${MAX_BOOKINGS_PER_DAY} bookings per day exceeded`,
      'BOOKING_LIMIT_EXCEEDED'
    );
  }

  // Atomically decrement capacity for each cart item
  // If any slot is full we rollback all decrements
  const decremented: Array<{ serviceId: string; slotDate: string; slotTime: string; qty: number }> = [];

  try {
    for (const item of cart.items) {
      const result = await Service.findOneAndUpdate(
        {
          _id: item.serviceId,
          'slots.date': item.slotDate,
          'slots.time': item.slotTime,
          $expr: {
            $lt: [
              {
                $add: [
                  {
                    $let: {
                      vars: {
                        slot: {
                          $arrayElemAt: [
                            {
                              $filter: {
                                input: '$slots',
                                cond: {
                                  $and: [
                                    { $eq: ['$$this.date', item.slotDate] },
                                    { $eq: ['$$this.time', item.slotTime] },
                                  ],
                                },
                              },
                            },
                            0,
                          ],
                        },
                      },
                      in: '$$slot.booked',
                    },
                  },
                  item.quantity,
                ],
              },
              {
                $let: {
                  vars: {
                    slot: {
                      $arrayElemAt: [
                        {
                          $filter: {
                            input: '$slots',
                            cond: {
                              $and: [
                                { $eq: ['$$this.date', item.slotDate] },
                                { $eq: ['$$this.time', item.slotTime] },
                              ],
                            },
                          },
                        },
                        0,
                      ],
                    },
                  },
                  in: '$$slot.capacity',
                },
              },
            ],
          },
        },
        {
          $inc: { 'slots.$[slot].booked': item.quantity },
        },
        {
          arrayFilters: [
            { 'slot.date': item.slotDate, 'slot.time': item.slotTime },
          ],
          new: true,
        }
      );

      if (!result) {
        throw new AppError(
          409,
          `Slot ${item.slotDate} ${item.slotTime} is fully booked`,
          'SLOT_FULL'
        );
      }

      decremented.push({
        serviceId: item.serviceId.toString(),
        slotDate: item.slotDate,
        slotTime: item.slotTime,
        qty: item.quantity,
      });
    }
  } catch (err) {
    // Rollback all successfully decremented slots
    logger.warn({ decremented }, 'Rolling back capacity decrements');
    for (const d of decremented) {
      await Service.updateOne(
        { _id: d.serviceId, 'slots.date': d.slotDate, 'slots.time': d.slotTime },
        { $inc: { 'slots.$[slot].booked': -d.qty } },
        { arrayFilters: [{ 'slot.date': d.slotDate, 'slot.time': d.slotTime }] }
      );
    }
    throw err;
  }

  // Determine initial status
  const isUnpaid = paymentMethod === 'cash' || paymentMethod === 'pay_on_arrival';
  const initialStatus: BookingStatus = isUnpaid ? 'confirmed' : 'pending';

  // Cancel cutoff: 24 hours before the earliest slot
  const cancelCutoff = new Date();
  cancelCutoff.setHours(cancelCutoff.getHours() + 24);

  const totalAmount = cart.items.reduce((s, i) => s + i.price * i.quantity, 0);

  const booking = await Booking.create({
    userId: new mongoose.Types.ObjectId(userId),
    items: cart.items.map((i) => ({
      serviceId: i.serviceId,
      serviceTitle: (i as any).serviceId?.title || 'Service',
      slotDate: i.slotDate,
      slotTime: i.slotTime,
      quantity: i.quantity,
      price: i.price,
    })),
    totalAmount: Math.round(totalAmount * 100) / 100,
    status: initialStatus,
    paymentMethod,
    paymentStatus: isUnpaid ? 'unpaid' : 'unpaid',
    cancelCutoff,
    auditLog: [
      {
        fromStatus: null,
        toStatus: initialStatus,
        timestamp: new Date(),
        reason: 'Booking created',
      },
    ],
  });

  // Clear cart
  cart.items = [];
  await cart.save();

  return booking;
}

export async function listBookings(userId: string) {
  return Booking.find({ userId }).sort({ createdAt: -1 });
}

export async function getBookingById(userId: string, bookingId: string) {
  const booking = await Booking.findOne({ _id: bookingId, userId });
  if (!booking) throw new AppError(404, 'Booking not found', 'NOT_FOUND');
  return booking;
}

export async function cancelBooking(
  userId: string,
  bookingId: string,
  reason?: string
) {
  const booking = await Booking.findOne({ _id: bookingId, userId });
  if (!booking) throw new AppError(404, 'Booking not found', 'NOT_FOUND');

  const allowed = ALLOWED_TRANSITIONS[booking.status];
  if (!allowed.includes('cancelled')) {
    throw new AppError(
      409,
      `Cannot cancel a booking with status "${booking.status}"`,
      'INVALID_STATUS_TRANSITION'
    );
  }

  if (new Date() > booking.cancelCutoff) {
    throw new AppError(
      409,
      'Cancellation window has passed',
      'CANCEL_CUTOFF_PASSED'
    );
  }

  const prevStatus = booking.status;
  booking.status = 'cancelled';
  booking.auditLog.push({
    fromStatus: prevStatus,
    toStatus: 'cancelled',
    timestamp: new Date(),
    reason: reason || 'Cancelled by user',
  });

  await booking.save();

  // Release capacity back
  for (const item of booking.items) {
    await Service.updateOne(
      { _id: item.serviceId, 'slots.date': item.slotDate, 'slots.time': item.slotTime },
      { $inc: { 'slots.$[slot].booked': -item.quantity } },
      { arrayFilters: [{ 'slot.date': item.slotDate, 'slot.time': item.slotTime }] }
    );
  }

  return booking;
}

export async function transitionStatus(
  bookingId: string,
  to: BookingStatus,
  reason?: string
) {
  const booking = await Booking.findById(bookingId);
  if (!booking) throw new AppError(404, 'Booking not found', 'NOT_FOUND');

  const allowed = ALLOWED_TRANSITIONS[booking.status];
  if (!allowed.includes(to)) {
    throw new AppError(
      409,
      `Transition from "${booking.status}" to "${to}" not allowed`,
      'INVALID_STATUS_TRANSITION'
    );
  }

  const prev = booking.status;
  booking.status = to;
  booking.auditLog.push({ fromStatus: prev, toStatus: to, timestamp: new Date(), reason });
  await booking.save();
  return booking;
}
