import { Service } from '../models/service.model';
import { AppError } from '../utils/AppError';

interface ListServicesQuery {
  page: number;
  limit: number;
  category?: string;
  search?: string;
}

export async function listServices({ page, limit, category, search }: ListServicesQuery) {
  const filter: Record<string, unknown> = { isActive: true };

  if (category) {
    filter.category = category;
  }

  if (search) {
    filter.$or = [
      { title: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
    ];
  }

  const skip = (page - 1) * limit;
  const [services, total] = await Promise.all([
    Service.find(filter)
      .select('-slots') // don't return all slots in list view
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 }),
    Service.countDocuments(filter),
  ]);

  return {
    data: services,
    page,
    limit,
    total,
    hasMore: skip + services.length < total,
  };
}

export async function getServiceById(id: string) {
  const service = await Service.findById(id);
  if (!service || !service.isActive) {
    throw new AppError(404, 'Service not found', 'NOT_FOUND');
  }

  // Return available slots only (not fully booked)
  const availableSlots = service.slots.filter(
    (s) => s.booked < s.capacity
  );

  return {
    ...service.toObject(),
    slots: availableSlots,
  };
}

export async function getCategories() {
  return Service.distinct('category', { isActive: true });
}
