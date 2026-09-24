import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

export async function createRoute(req: Request, res: Response): Promise<void> {
  try {
    const { routeName, hospitalIds } = req.body;

    if (!routeName || !Array.isArray(hospitalIds) || hospitalIds.length === 0) {
      res.status(400).json({ error: 'Route Name and at least one Hospital ID in sequence are required' });
      return;
    }

    const newRoute = await prisma.$transaction(async (tx) => {
      const route = await tx.route.create({
        data: {
          routeName: routeName.trim(),
        },
      });

      const routeHospitalsData = hospitalIds.map((hospId: string, index: number) => ({
        routeId: route.id,
        hospitalId: hospId,
        stopSequence: index + 1,
      }));

      await tx.routeHospital.createMany({
        data: routeHospitalsData,
      });

      return route;
    });

    const populatedRoute = await prisma.route.findUnique({
      where: { id: newRoute.id },
      include: {
        routeHospitals: {
          include: { hospital: true },
          orderBy: { stopSequence: 'asc' },
        },
      },
    });

    res.status(201).json({
      message: 'Route created successfully with hospital sequence',
      data: populatedRoute,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Route name already exists' });
      return;
    }
    res.status(500).json({ error: error.message });
  }
}

export async function getAllRoutes(_req: Request, res: Response): Promise<void> {
  try {
    const routes = await prisma.route.findMany({
      include: {
        routeHospitals: {
          include: { hospital: true },
          orderBy: { stopSequence: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ data: routes });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
