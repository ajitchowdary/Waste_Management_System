import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

export async function registerDriver(req: Request, res: Response): Promise<void> {
  try {
    const { driverName, mobileNo, driverCode } = req.body;
    const photoFile = req.file;

    if (!driverName || !mobileNo) {
      res.status(400).json({ error: 'Driver Name and Mobile No are required' });
      return;
    }

    const generatedDriverCode = driverCode || `DRV_${mobileNo.slice(-4)}_${Date.now().toString().slice(-4)}`;
    const photoUrl = photoFile ? `/uploads/${photoFile.filename}` : null;

    const driver = await prisma.driver.create({
      data: {
        driverCode: generatedDriverCode,
        driverName: driverName.trim(),
        mobileNo: mobileNo.trim(),
        photoUrl,
      },
    });

    res.status(201).json({
      message: 'Driver registered successfully',
      data: driver,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Driver mobile number or driver code already registered' });
      return;
    }
    res.status(500).json({ error: error.message });
  }
}

export async function getAllDrivers(_req: Request, res: Response): Promise<void> {
  try {
    const drivers = await prisma.driver.findMany({
      where: { isActive: true },
      orderBy: { driverName: 'asc' },
    });
    res.json({ data: drivers });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
