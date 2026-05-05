import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import pinoHttp from 'pino-http';
import mongoose from 'mongoose';
import { logger } from './utils/logger';
import { errorHandler } from './middleware/errorHandler';
import { authRouter } from './routes/auth.routes';
import { servicesRouter } from './routes/services.routes';
import { cartRouter } from './routes/cart.routes';
import { bookingsRouter } from './routes/bookings.routes';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(pinoHttp({ logger }));

// Routes
app.use('/auth', authRouter);
app.use('/services', servicesRouter);
app.use('/cart', cartRouter);
app.use('/bookings', bookingsRouter);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler (must be last)
app.use(errorHandler);

// Connect DB then start
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/mentecart';

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    logger.info('Connected to MongoDB');
    app.listen(PORT, () => {
      logger.info({ port: PORT }, 'MenteCart API running');
    });
  })
  .catch((err) => {
    logger.error({ err }, 'Failed to connect to MongoDB');
    process.exit(1);
  });

export default app;
