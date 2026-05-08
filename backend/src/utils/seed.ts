import 'dotenv/config';
import mongoose from 'mongoose';
import { Service } from '../models/service.model';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/mentecart';

function generateSlots(count = 14) {
  const slots = [];
  for (let d = 0; d < count; d++) {
    const date = new Date();
    date.setDate(date.getDate() + d + 1);
    const dateStr = date.toISOString().split('T')[0];
    for (const time of ['09:00', '11:00', '13:00', '15:00', '17:00']) {
      slots.push({
        date: dateStr,
        time,
        capacity: Math.floor(Math.random() * 3) + 2,
        booked: 0,
      });
    }
  }
  return slots;
}

const SERVICES = [
  {
    title: 'Home Deep Cleaning',
    description: 'Full home deep cleaning by certified professionals. We bring all supplies.',
    price: 75.0,
    duration: 180,
    category: 'Cleaning',
    image: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
    capacityPerSlot: 3,
  },
  {
    title: 'Regular Home Cleaning',
    description: 'Weekly or bi-weekly home cleaning service. Keep your home spotless.',
    price: 45.0,
    duration: 120,
    category: 'Cleaning',
    image: 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400',
    capacityPerSlot: 4,
  },
  {
    title: 'Plumbing Inspection',
    description: 'Complete plumbing inspection and minor repairs by a licensed plumber.',
    price: 90.0,
    duration: 60,
    category: 'Plumbing',
    image: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400',
    capacityPerSlot: 2,
  },
  {
    title: 'Pipe Repair & Replacement',
    description: 'Leak fixing, pipe replacement and drain unclogging.',
    price: 120.0,
    duration: 90,
    category: 'Plumbing',
    image: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
    capacityPerSlot: 2,
  },
  {
    title: 'Math Tutoring (1 hr)',
    description: 'One-on-one math tutoring for grades 6-12 by experienced tutors.',
    price: 40.0,
    duration: 60,
    category: 'Tutoring',
    image: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=400',
    capacityPerSlot: 1,
  },
  {
    title: 'English Tutoring (1 hr)',
    description: 'English language and literature tutoring. All levels welcome.',
    price: 38.0,
    duration: 60,
    category: 'Tutoring',
    image: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400',
    capacityPerSlot: 1,
  },
  {
    title: 'Haircut & Styling',
    description: 'Professional haircut and styling at your home by expert stylists.',
    price: 55.0,
    duration: 60,
    category: 'Beauty',
    image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
    capacityPerSlot: 2,
  },
  {
    title: 'Manicure & Pedicure',
    description: 'Full nail care service including manicure and pedicure.',
    price: 65.0,
    duration: 90,
    category: 'Beauty',
    image: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400',
    capacityPerSlot: 2,
  },
  {
    title: 'Electrical Safety Check',
    description: 'Full home electrical safety inspection by a certified electrician.',
    price: 85.0,
    duration: 60,
    category: 'Electrical',
    image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400',
    capacityPerSlot: 2,
  },
  {
    title: 'AC Service & Maintenance',
    description: 'Air conditioning unit servicing, cleaning and gas refill.',
    price: 60.0,
    duration: 75,
    category: 'Electrical',
    image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
    capacityPerSlot: 3,
  },
];

async function seed() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  await Service.deleteMany({});
  console.log('Cleared existing services');

  const services = SERVICES.map((s) => ({ ...s, slots: generateSlots() }));
  await Service.insertMany(services);
  console.log(`Seeded ${services.length} services`);

  await mongoose.disconnect();
  console.log('Done!');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
