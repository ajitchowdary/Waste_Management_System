import 'dotenv/config';
import process from 'node:process';
import { prisma } from '../src/prisma.js';

async function seed() {
  console.log('🌱 Seeding initial sample data (Hospitals, Drivers, Vehicles, and Users)...');

  // 1. Seed Sample Hospitals
  const sampleHospitals = [
    {
      hospitalCode: 'HOSP_APOLLO_01',
      hospitalName: 'Apollo Speciality Hospital',
      qrCodePayload: 'HOSP:HOSP_APOLLO_01',
      address: 'Main Health City, Sector 4',
    },
    {
      hospitalCode: 'HOSP_FORTIS_02',
      hospitalName: 'Fortis Multi-Care Hospital',
      qrCodePayload: 'HOSP:HOSP_FORTIS_02',
      address: 'Ring Road, North Zone',
    },
    {
      hospitalCode: 'HOSP_MAX_03',
      hospitalName: 'Max Super Care Hospital',
      qrCodePayload: 'HOSP:HOSP_MAX_03',
      address: 'Central Avenue, Block B',
    },
    {
      hospitalCode: 'HOSP_AIIMS_04',
      hospitalName: 'AIIMS Central Care',
      qrCodePayload: 'HOSP:HOSP_AIIMS_04',
      address: 'Govt Medical Enclave',
    },
  ];

  for (const h of sampleHospitals) {
    await prisma.hospital.upsert({
      where: { hospitalCode: h.hospitalCode },
      update: {},
      create: h,
    });
  }

  // 2. Seed Sample Driver
  const sampleDriver = await prisma.driver.upsert({
    where: { mobileNo: '9876543210' },
    update: {},
    create: {
      driverCode: 'DRV_3210_1001',
      driverName: 'Ramesh Kumar',
      mobileNo: '9876543210',
      isActive: true,
    },
  });

  // 3. Seed Sample Vehicle
  await prisma.vehicle.upsert({
    where: { vehicleNo: 'AP39HG9999' },
    update: {},
    create: {
      vehicleNo: 'AP39HG9999',
      vehicleType: 'FOUR_WHEELER',
      qrCodePayload: 'VEH:AP39HG9999',
      status: 'ACTIVE',
    },
  });

  // 4. Seed Role-Based Users (Admin, Driver, Plant Operator)
  await prisma.user.upsert({
    where: { username: 'admin' },
    update: { role: 'ADMIN' },
    create: {
      username: 'admin',
      password: 'admin123',
      fullName: 'System Administrator',
      role: 'ADMIN',
    },
  });

  await prisma.user.upsert({
    where: { username: 'driver' },
    update: { role: 'DRIVER', driverId: sampleDriver.id },
    create: {
      username: 'driver',
      password: 'driver123',
      fullName: 'Ramesh Kumar (Driver)',
      role: 'DRIVER',
      driverId: sampleDriver.id,
    },
  });

  await prisma.user.upsert({
    where: { username: 'operator' },
    update: { role: 'PLANT_OPERATOR' },
    create: {
      username: 'operator',
      password: 'operator123',
      fullName: 'Suresh Reddy (Plant Operator)',
      role: 'PLANT_OPERATOR',
    },
  });

  console.log('✅ Seed completed successfully with RBAC demo accounts!');
  await prisma.$disconnect();
}

seed().catch((e) => {
  console.error('❌ Error seeding:', e);
  process.exit(1);
});
