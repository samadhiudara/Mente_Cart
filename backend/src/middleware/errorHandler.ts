import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../utils/AppError';
import { logger } from '../utils/logger';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  if (err instanceof ZodError) {
    res.status(400).json({
      statusCode: 400,
      message: 'Validation error',
      errorCode: 'VALIDATION_ERROR',
      errors: err.errors,
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      statusCode: err.statusCode,
      message: err.message,
      errorCode: err.errorCode,
    });
    return;
  }

  logger.error({ err }, 'Unhandled error');
  res.status(500).json({
    statusCode: 500,
    message: 'Internal server error',
    errorCode: 'INTERNAL_ERROR',
  });
}
