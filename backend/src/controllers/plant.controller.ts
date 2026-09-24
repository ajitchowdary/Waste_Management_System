import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

export async function receiveVehicleAtPlant(req: Request, res: Response): Promise<void> {
  try {
    const { vehicleQrCode } = req.body;

    if (!vehicleQrCode) {
      res.status(400).json({ error: 'Vehicle QR code is required' });
      return;
    }

    const vehicle = await prisma.vehicle.findFirst({
      where: {
        OR: [
          { qrCodePayload: vehicleQrCode.trim() },
          { vehicleNo: vehicleQrCode.trim().toUpperCase() },
        ],
      },
    });

    if (!vehicle) {
      res.status(404).json({ error: `Vehicle not found with QR: ${vehicleQrCode}` });
      return;
    }

    const pendingBags = await prisma.collectedBag.findMany({
      where: {
        vehicleId: vehicle.id,
        status: { in: ['COLLECTED', 'IN_TRANSIT'] },
      },
      include: {
        hospital: { select: { hospitalName: true, hospitalCode: true } },
        driver: { select: { driverName: true, driverCode: true, mobileNo: true } },
        route: { select: { routeName: true } },
        vehicle: { select: { vehicleNo: true, vehicleType: true } },
      },
    });

    if (pendingBags.length === 0) {
      res.status(200).json({
        message: 'No pending bags found for this vehicle. All bags are already processed.',
        vehicleNo: vehicle.vehicleNo,
        totalBagsReceived: 0,
        bagsDetails: [],
      });
      return;
    }

    const bagIdsToUpdate = pendingBags.map((b) => b.id);

    await prisma.collectedBag.updateMany({
      where: { id: { in: bagIdsToUpdate } },
      data: {
        status: 'PLANT_RECEIVED',
        plantReceivedAt: new Date(),
      },
    });

    const detailedList = pendingBags.map((b) => ({
      bagId: b.id,
      bagQrCode: b.bagQrCode,
      hospitalCode: b.hospital.hospitalCode,
      hospitalName: b.hospital.hospitalName,
      driverCode: b.driver.driverCode,
      driverName: b.driver.driverName,
      routeName: b.route.routeName,
      vehicleNo: b.vehicle.vehicleNo,
      status: 'PLANT_RECEIVED',
      collectedAt: b.collectedAt,
    }));

    res.status(200).json({
      message: `Successfully received and verified ${pendingBags.length} bags at treatment plant`,
      vehicleNo: vehicle.vehicleNo,
      totalBagsReceived: pendingBags.length,
      bagsDetails: detailedList,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
