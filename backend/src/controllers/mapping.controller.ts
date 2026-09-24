import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

export async function createDriverMapping(req: Request, res: Response): Promise<void> {
  try {
    const { driverId, vehicleId, routeId } = req.body;

    if (!driverId || !vehicleId || !routeId) {
      res.status(400).json({ error: 'Driver ID, Vehicle ID, and Route ID are all required' });
      return;
    }

    const [driver, vehicle, route] = await Promise.all([
      prisma.driver.findUnique({ where: { id: driverId } }),
      prisma.vehicle.findUnique({ where: { id: vehicleId } }),
      prisma.route.findUnique({
        where: { id: routeId },
        include: {
          routeHospitals: {
            include: { hospital: true },
            orderBy: { stopSequence: 'asc' },
          },
        },
      }),
    ]);

    if (!driver) {
      res.status(404).json({ error: 'Driver not found' });
      return;
    }
    if (!vehicle) {
      res.status(404).json({ error: 'Vehicle not found' });
      return;
    }
    if (!route) {
      res.status(404).json({ error: 'Route not found' });
      return;
    }

    const mapping = await prisma.dailyDriverMapping.create({
      data: {
        driverId,
        vehicleId,
        routeId,
        status: 'IN_PROGRESS',
      },
      include: {
        driver: true,
        vehicle: true,
        route: {
          include: {
            routeHospitals: {
              include: { hospital: true },
              orderBy: { stopSequence: 'asc' },
            },
          },
        },
      },
    });

    res.status(201).json({
      message: 'Driver, vehicle, and route mapped successfully for current shift',
      data: mapping,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}

export async function getActiveShiftByDriver(req: Request, res: Response): Promise<void> {
  try {
    const { driverId } = req.params;
    const mapping = await prisma.dailyDriverMapping.findFirst({
      where: {
        driverId,
        status: 'IN_PROGRESS',
      },
      include: {
        driver: true,
        vehicle: true,
        route: {
          include: {
            routeHospitals: {
              include: { hospital: true },
              orderBy: { stopSequence: 'asc' },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!mapping) {
      res.status(404).json({ message: 'No active shift found for this driver' });
      return;
    }

    res.json({ data: mapping });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
