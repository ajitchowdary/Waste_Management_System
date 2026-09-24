import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import { apiRouter } from './routes/api.routes.js';
import { initDisposalScheduler } from './cron/disposal.cron.js';

const app = express();
const PORT = process.env.PORT || 5000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded driver photos statically
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// API Routes
app.use('/api', apiRouter);

// Health check endpoint
app.get('/health', (_req, res) => {
  res.json({ status: 'OK', message: 'Waste Management API is running', timestamp: new Date() });
});

// Start Background 6:00 PM Disposal Cron Job
initDisposalScheduler();

// Start HTTP Server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
  console.log(`📦 Health check: http://localhost:${PORT}/health`);
});
