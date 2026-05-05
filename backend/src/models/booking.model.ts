import mongoose, { Document, Schema } from 'mongoose';

export type BookingStatus =
  | 'pending'
  | 'confirmed'
  | 'completed'
  | 'cancelled'
  | 'failed';

export type PaymentMethod = 'cash' | 'pay_on_arrival' | 'payhere';
export type PaymentStatus = 'unpaid' | 'paid' | 'failed' | 'refunded';

export interface IAuditEntry {
  fromStatus: BookingStatus | null;
  toStatus: BookingStatus;
  timestamp: Date;
  reason?: string;
}

export interface IBookingItem {
  serviceId: mongoose.Types.ObjectId;
  serviceTitle: string;
  slotDate: string;
  slotTime: string;
  quantity: number;
  price: number;
}

export interface IBooking extends Document {
  userId: mongoose.Types.ObjectId;
  items: IBookingItem[];
  totalAmount: number;
  status: BookingStatus;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  paymentReference?: string;
  cancelCutoff: Date;
  auditLog: IAuditEntry[];
  createdAt: Date;
  updatedAt: Date;
}

// Guard: only these transitions are allowed
export const ALLOWED_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  pending: ['confirmed', 'failed', 'cancelled'],
  confirmed: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
  failed: [],
};

const auditSchema = new Schema<IAuditEntry>(
  {
    fromStatus: { type: String, default: null },
    toStatus: { type: String, required: true },
    timestamp: { type: Date, default: () => new Date() },
    reason: { type: String },
  },
  { _id: false }
);

const bookingItemSchema = new Schema<IBookingItem>(
  {
    serviceId: { type: Schema.Types.ObjectId, ref: 'Service', required: true },
    serviceTitle: { type: String, required: true },
    slotDate: { type: String, required: true },
    slotTime: { type: String, required: true },
    quantity: { type: Number, default: 1 },
    price: { type: Number, required: true },
  },
  { _id: false }
);

const bookingSchema = new Schema<IBooking>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    items: [bookingItemSchema],
    totalAmount: { type: Number, required: true },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'completed', 'cancelled', 'failed'],
      default: 'pending',
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'pay_on_arrival', 'payhere'],
      required: true,
    },
    paymentStatus: {
      type: String,
      enum: ['unpaid', 'paid', 'failed', 'refunded'],
      default: 'unpaid',
    },
    paymentReference: { type: String },
    cancelCutoff: { type: Date, required: true },
    auditLog: [auditSchema],
  },
  { timestamps: true }
);

bookingSchema.index({ userId: 1, createdAt: -1 });
bookingSchema.index({ userId: 1, status: 1 });

export const Booking = mongoose.model<IBooking>('Booking', bookingSchema);
