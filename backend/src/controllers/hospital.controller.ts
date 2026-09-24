import { Request, Response } from 'express';
import { prisma } from '../prisma.js';
import QRCode from 'qrcode';

export async function createHospital(req: Request, res: Response): Promise<void> {
  try {
    const { hospitalCode, hospitalName, address } = req.body;
    if (!hospitalCode || !hospitalName) {
      res.status(400).json({ error: 'Hospital code and name are required' });
      return;
    }

    const qrCodePayload = `HOSP:${hospitalCode.trim().toUpperCase()}`;
    const qrCodeBase64 = await QRCode.toDataURL(qrCodePayload);

    const hospital = await prisma.hospital.create({
      data: {
        hospitalCode: hospitalCode.trim().toUpperCase(),
        hospitalName,
        qrCodePayload,
        address,
      },
    });

    res.status(201).json({
      message: 'Hospital created successfully',
      data: { ...hospital, qrCodePreview: qrCodeBase64 },
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Hospital code already exists' });
      return;
    }
    res.status(500).json({ error: error.message });
  }
}

export async function getAllHospitals(_req: Request, res: Response): Promise<void> {
  try {
    const hospitals = await prisma.hospital.findMany({
      orderBy: { hospitalName: 'asc' },
    });
    res.json({ data: hospitals });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
