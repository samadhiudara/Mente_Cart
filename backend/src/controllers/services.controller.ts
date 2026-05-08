import { Request, Response, NextFunction } from 'express';
import { servicesQuerySchema } from '../validators/schemas';
import * as servicesService from '../services/services.service';

export async function listServices(req: Request, res: Response, next: NextFunction) {
  try {
    const query = servicesQuerySchema.parse(req.query);
    const result = await servicesService.listServices(query);
    res.json({ statusCode: 200, data: result });
  } catch (err) {
    next(err);
  }
}

export async function getService(req: Request, res: Response, next: NextFunction) {
  try {
    const service = await servicesService.getServiceById(req.params.id);
    res.json({ statusCode: 200, data: service });
  } catch (err) {
    next(err);
  }
}

export async function getCategories(_req: Request, res: Response, next: NextFunction) {
  try {
    const categories = await servicesService.getCategories();
    res.json({ statusCode: 200, data: categories });
  } catch (err) {
    next(err);
  }
}
