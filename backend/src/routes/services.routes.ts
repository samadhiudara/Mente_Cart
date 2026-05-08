import { Router } from 'express';
import * as servicesController from '../controllers/services.controller';

export const servicesRouter = Router();

servicesRouter.get('/', servicesController.listServices);
servicesRouter.get('/categories', servicesController.getCategories);
servicesRouter.get('/:id', servicesController.getService);
