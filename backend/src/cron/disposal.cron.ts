import cron from 'node-cron';
import { prisma } from '../prisma.js';

export function initDisposalScheduler() {
  console.log('⏰ [Scheduler] Disposal cron initialized for 6:00 PM daily (0 18 * * *).');

  cron.schedule('0 18 * * *', async () => {
    console.log('🔄 [Scheduler] Running 6:00 PM daily waste disposal job...');
    try {
      const result = await prisma.collectedBag.updateMany({
        where: {
          status: 'PLANT_RECEIVED',
          disposedAt: null,
        },
        data: {
          status: 'DISPOSED',
          disposedAt: new Date(),
        },
      });

      console.log(`✅ [Scheduler] Successfully marked ${result.count} bags as DISPOSED at ${new Date().toISOString()}`);
    } catch (error) {
      console.error('❌ [Scheduler] Error running disposal job:', error);
    }
  });
}
