import { Request, Response } from 'express';
import { prisma } from '../prisma.js';
import QRCode from 'qrcode';

export async function registerVehicle(req: Request, res: Response): Promise<void> {
  try {
    const { vehicleNo, vehicleType } = req.body;

    if (!vehicleNo || !vehicleType) {
      res.status(400).json({ error: 'Vehicle No and Vehicle Type (FOUR_WHEELER / SIX_WHEELER) are required' });
      return;
    }

    const formattedVehicleNo = vehicleNo.trim().toUpperCase();
    const typeEnum = vehicleType === '6_wheeler' || vehicleType === 'SIX_WHEELER' ? 'SIX_WHEELER' : 'FOUR_WHEELER';
    const qrCodePayload = `VEH:${formattedVehicleNo}`;

    const qrCodeBase64 = await QRCode.toDataURL(qrCodePayload);

    const vehicle = await prisma.vehicle.create({
      data: {
        vehicleNo: formattedVehicleNo,
        vehicleType: typeEnum,
        qrCodePayload,
      },
    });

    res.status(201).json({
      message: 'Vehicle registered successfully',
      data: {
        ...vehicle,
        qrCodePreview: qrCodeBase64,
      },
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Vehicle number already exists in the system' });
      return;
    }
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
}

export async function getAllVehicles(_req: Request, res: Response): Promise<void> {
  try {
    const vehicles = await prisma.vehicle.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json({ data: vehicles });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
