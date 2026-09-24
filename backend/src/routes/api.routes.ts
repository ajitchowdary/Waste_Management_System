import { Router } from 'express';
import { upload } from '../middleware/upload.js';
import { loginUser, registerUser, getAllUsers } from '../controllers/auth.controller.js';
import { registerVehicle, getAllVehicles } from '../controllers/vehicle.controller.js';
import { createHospital, getAllHospitals } from '../controllers/hospital.controller.js';
import { createRoute, getAllRoutes } from '../controllers/route.controller.js';
import { registerDriver, getAllDrivers } from '../controllers/driver.controller.js';
import { createDriverMapping, getActiveShiftByDriver } from '../controllers/mapping.controller.js';
import { collectBagsAtHospital, getAllBags, getCollectedBagsSummary } from '../controllers/bag.controller.js';
import { receiveVehicleAtPlant } from '../controllers/plant.controller.js';

export const apiRouter = Router();

// Authentication (RBAC)
apiRouter.post('/auth/login', loginUser);
apiRouter.post('/auth/register', registerUser);
apiRouter.get('/auth/users', getAllUsers);

// Screen 1: Vehicle Management
apiRouter.post('/vehicles/register', registerVehicle);
apiRouter.get('/vehicles', getAllVehicles);

// Hospital Management
apiRouter.post('/hospitals', createHospital);
apiRouter.get('/hospitals', getAllHospitals);

// Screen 2: Vehicle Route Map
apiRouter.post('/routes/create', createRoute);
apiRouter.get('/routes', getAllRoutes);

// Screen 3: Driver Registration (with Photo Upload)
apiRouter.post('/drivers/register', upload.single('photo'), registerDriver);
apiRouter.get('/drivers', getAllDrivers);

// Screen 4: Driver + Vehicle + Route Mapping (Shift start)
apiRouter.post('/trips/mapping', createDriverMapping);
apiRouter.get('/trips/active-shift/:driverId', getActiveShiftByDriver);

// Screen 5 & Screen 6: Bags Data & Tracking for Admin
apiRouter.post('/bags/collect', collectBagsAtHospital);
apiRouter.get('/bags', getAllBags);
apiRouter.get('/bags/summary', getCollectedBagsSummary);

// Screen 6: Vehicle Scan at Treatment Plant
apiRouter.post('/plant/receive-vehicle', receiveVehicleAtPlant);
