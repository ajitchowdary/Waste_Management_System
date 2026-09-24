import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

// Screen 5: Bags collection at Hospital (Scan Hospital QR + Scan Multiple Bag QRs)
export async function collectBagsAtHospital(req: Request, res: Response): Promise<void> {
  try {
    const { hospitalQrCode, bagQrCodes, driverMappingId, driverId, vehicleId, routeId } = req.body;

    if (!hospitalQrCode || !Array.isArray(bagQrCodes) || bagQrCodes.length === 0) {
      res.status(400).json({ error: 'Hospital QR code and at least 1 Bag QR code are required' });
      return;
    }

    const hospital = await prisma.hospital.findFirst({
      where: {
        OR: [
          { qrCodePayload: hospitalQrCode.trim() },
          { hospitalCode: hospitalQrCode.trim() },
        ],
      },
    });

    if (!hospital) {
      res.status(404).json({ error: `Hospital not found with QR code: ${hospitalQrCode}` });
      return;
    }

    let finalDriverId = driverId;
    let finalVehicleId = vehicleId;
    let finalRouteId = routeId;

    if (driverMappingId) {
      const mapping = await prisma.dailyDriverMapping.findUnique({
        where: { id: driverMappingId },
      });
      if (mapping) {
        finalDriverId = mapping.driverId;
        finalVehicleId = mapping.vehicleId;
        finalRouteId = mapping.routeId;
      }
    }

    if (!finalDriverId || !finalVehicleId || !finalRouteId) {
      res.status(400).json({
        error: 'Active Driver, Vehicle, and Route context are required to collect bags',
      });
      return;
    }

    const bagsToInsert = bagQrCodes.map((bagQr: string) => ({
      bagQrCode: bagQr.trim(),
      hospitalId: hospital.id,
      driverMappingId: driverMappingId || null,
      driverId: finalDriverId,
      vehicleId: finalVehicleId,
      routeId: finalRouteId,
      status: 'COLLECTED' as const,
      collectedAt: new Date(),
    }));

    const result = await prisma.collectedBag.createMany({
      data: bagsToInsert,
    });

    res.status(201).json({
      message: `Successfully collected ${result.count} bags from ${hospital.hospitalName}`,
      data: {
        hospitalName: hospital.hospitalName,
        hospitalCode: hospital.hospitalCode,
        bagsCount: result.count,
        scannedBags: bagQrCodes,
      },
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}

export async function getAllBags(req: Request, res: Response): Promise<void> {
  try {
    const { status } = req.query;
    const filter: any = {};
    if (status && typeof status === 'string' && status !== 'ALL') {
      filter.status = status;
    }

    const bags = await prisma.collectedBag.findMany({
      where: filter,
      include: {
        hospital: { select: { hospitalName: true, hospitalCode: true } },
        driver: { select: { driverName: true, driverCode: true, mobileNo: true } },
        route: { select: { routeName: true } },
        vehicle: { select: { vehicleNo: true, vehicleType: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ data: bags });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}

export async function getCollectedBagsSummary(_req: Request, res: Response): Promise<void> {
  try {
    const summary = await prisma.collectedBag.groupBy({
      by: ['status'],
      _count: { id: true },
    });
    res.json({ data: summary });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
