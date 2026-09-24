import { Request, Response } from 'express';
import { prisma } from '../prisma.js';

export async function loginUser(req: Request, res: Response): Promise<void> {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      res.status(400).json({ error: 'Username and password are required' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { username: username.trim().toLowerCase() },
      include: {
        driver: true,
      },
    });

    if (!user || user.password !== password.trim()) {
      res.status(401).json({ error: 'Invalid username or password' });
      return;
    }

    // Return user info and role
    res.json({
      message: 'Login successful',
      data: {
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        role: user.role, // 'ADMIN', 'DRIVER', 'PLANT_OPERATOR'
        driverId: user.driverId,
        driver: user.driver,
        token: `mock-jwt-token-${user.id}-${Date.now()}`,
      },
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}

export async function registerUser(req: Request, res: Response): Promise<void> {
  try {
    const { username, password, fullName, role, driverId } = req.body;

    if (!username || !password || !fullName) {
      res.status(400).json({ error: 'Username, password, and Full Name are required' });
      return;
    }

    const newUser = await prisma.user.create({
      data: {
        username: username.trim().toLowerCase(),
        password: password.trim(),
        fullName: fullName.trim(),
        role: role || 'DRIVER',
        driverId: driverId || null,
      },
      include: { driver: true },
    });

    res.status(201).json({
      message: 'User created successfully',
      data: newUser,
    });
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'Username already taken' });
      return;
    }
    res.status(500).json({ error: error.message });
  }
}

export async function getAllUsers(_req: Request, res: Response): Promise<void> {
  try {
    const users = await prisma.user.findMany({
      include: { driver: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ data: users });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
