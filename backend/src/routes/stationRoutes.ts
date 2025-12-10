import express from 'express';
import prisma from '../lib/prisma.js';

const router = express.Router();

/**
 * GET /api/stations
 * List all stations
 */
router.get('/', async (req, res) => {
    try {
        const stations = await prisma.station.findMany({
            include: {
                connectors: true
            }
        });

        // Format response
        const response = stations.map(station => ({
            id: station.id,
            name: station.name,
            operator_name: station.operator_name,
            address: station.address,
            latitude: station.latitude ? Number(station.latitude) : null,
            longitude: station.longitude ? Number(station.longitude) : null,
            is_public: station.is_public,
            connector_count: station.connectors.length,
            available_connectors: station.connectors.filter(c => c.status === 'AVAILABLE').length
        }));

        res.json(response);
    } catch (error) {
        console.error('Error fetching stations:', error);
        res.status(500).json({ error: 'Failed to fetch stations' });
    }
});

/**
 * GET /api/stations/:id
 * Get detailed station information
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const station = await prisma.station.findUnique({
            where: { id },
            include: {
                connectors: true
            }
        });

        if (!station) {
            return res.status(404).json({ error: 'Station not found' });
        }

        // Format response
        const response = {
            id: station.id,
            name: station.name,
            operator_name: station.operator_name,
            address: station.address,
            latitude: station.latitude ? Number(station.latitude) : null,
            longitude: station.longitude ? Number(station.longitude) : null,
            is_public: station.is_public,
            website: station.website,
            phone: station.phone,
            opening_hours: station.opening_hours,
            connectors: station.connectors.map(connector => ({
                id: connector.id,
                evse_id: connector.evse_id,
                type: connector.type,
                max_power_kw: Number(connector.max_power_kw),
                status: connector.status,
                tariff: connector.tariff
            }))
        };

        res.json(response);
    } catch (error) {
        console.error('Error fetching station:', error);
        res.status(500).json({ error: 'Failed to fetch station' });
    }
});

export default router;
