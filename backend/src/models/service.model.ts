import mongoose, { Document, Schema } from 'mongoose';

export interface ITimeSlot {
  date: string;        // ISO date "2024-08-15"
  time: string;        // "09:00"
  capacity: number;
  booked: number;
}

export interface IService extends Document {
  title: string;
  description: string;
  price: number;
  duration: number;    // in minutes
  category: string;
  image: string;
  capacityPerSlot: number;
  slots: ITimeSlot[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const timeSlotSchema = new Schema<ITimeSlot>(
  {
    date: { type: String, required: true },
    time: { type: String, required: true },
    capacity: { type: Number, required: true, min: 1 },
    booked: { type: Number, default: 0, min: 0 },
  },
  { _id: true }
);

const serviceSchema = new Schema<IService>(
  {
    title: { type: String, required: true, trim: true, index: true },
    description: { type: String, required: true },
    price: { type: Number, required: true, min: 0 },
    duration: { type: Number, required: true, min: 1 },
    category: { type: String, required: true, index: true },
    image: { type: String, default: '' },
    capacityPerSlot: { type: Number, required: true, min: 1 },
    slots: [timeSlotSchema],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

serviceSchema.index({ title: 'text', description: 'text' });

export const Service = mongoose.model<IService>('Service', serviceSchema);
