import { Request, Response, NextFunction } from 'express';
import { signupSchema, loginSchema } from '../validators/schemas';
import * as authService from '../services/auth.service';
import { AuthRequest } from '../middleware/auth.middleware';

export async function signup(req: Request, res: Response, next: NextFunction) {
  try {
    const { email, password, name } = signupSchema.parse(req.body);
    const result = await authService.signup(email, password, name);
    res.status(201).json({ statusCode: 201, data: result });
  } catch (err) {
    next(err);
  }
}

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const result = await authService.login(email, password);
    res.json({ statusCode: 200, data: result });
  } catch (err) {
    next(err);
  }
}

export async function getMe(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const user = await authService.getMe(req.userId!);
    res.json({ statusCode: 200, data: user });
  } catch (err) {
    next(err);
  }
}
