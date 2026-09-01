import { SubmissionStatus } from '@prisma/client';
import { Router, type Request, type Response, type NextFunction } from 'express';
import prisma from '../lib/prisma.js';

const router = Router();

function requireOwner(req: Request, res: Response, next: NextFunction) {
    const expected = process.env.APP_OWNER_PIN;
    const provided = req.get('X-Owner-Pin');
    if (!expected || provided !== expected) {
        return res.status(403).json({ error: 'App owner PIN required' });
    }
    next();
}

function serializeSubmission(row: {
    id: string;
    name: string;
    address: string;
    operator_name: string | null;
    latitude: { toNumber(): number } | number;
    longitude: { toNumber(): number } | number;
    connector_note: string | null;
    submitted_by: string;
    status: string;
    owner_note: string | null;
    published_station_id: string | null;
    createdAt: Date;
}) {
    const lat = typeof row.latitude === 'number' ? row.latitude : row.latitude.toNumber();
    const lng = typeof row.longitude === 'number' ? row.longitude : row.longitude.toNumber();
    return {
        id: row.id,
        name: row.name,
        address: row.address,
        operator_name: row.operator_name,
        latitude: lat,
        longitude: lng,
        connector_note: row.connector_note,
        submitted_by: row.submitted_by,
        status: row.status,
        owner_note: row.owner_note,
        published_station_id: row.published_station_id,
        created_at: row.createdAt.toISOString(),
    };
}

/**
 * POST /api/crowd/submissions
 * Driver marks a new station. It stays off the public map until the owner confirms.
 */
router.post('/submissions', async (req: Request, res: Response) => {
    try {
        const { name, address, operator_name, latitude, longitude, connector_note, submitted_by } =
            req.body ?? {};
        const lat = Number(latitude);
        const lng = Number(longitude);
        if (!name || !address || Number.isNaN(lat) || Number.isNaN(lng)) {
            return res.status(400).json({
                error: 'name, address, latitude and longitude are required',
            });
        }
        const row = await prisma.stationSubmission.create({
            data: {
                name: String(name).trim(),
                address: String(address).trim(),
                operator_name: operator_name ? String(operator_name).trim() : null,
                latitude: lat,
                longitude: lng,
                connector_note: connector_note ? String(connector_note).trim() : null,
                submitted_by: submitted_by ? String(submitted_by) : 'anonymous',
            },
        });
        res.status(201).json({
            ...serializeSubmission(row),
            message: 'Saved. It will appear on the map after the app owner confirms the physical location.',
        });
    } catch (error) {
        console.error('Error creating station submission:', error);
        res.status(500).json({ error: 'Failed to save station submission' });
    }
});

/**
 * GET /api/crowd/submissions?status=PENDING
 * App-owner inbox.
 */
router.get('/submissions', requireOwner, async (req: Request, res: Response) => {
    try {
        const status = typeof req.query.status === 'string' ? req.query.status : 'PENDING';
        const rows = await prisma.stationSubmission.findMany({
            ...(status === 'ALL'
                ? {}
                : {
                      where: {
                          status: Object.values(SubmissionStatus).includes(
                              status as SubmissionStatus,
                          )
                              ? (status as SubmissionStatus)
                              : SubmissionStatus.PENDING,
                      },
                  }),
            orderBy: { createdAt: 'desc' },
        });
        res.json(rows.map(serializeSubmission));
    } catch (error) {
        console.error('Error listing submissions:', error);
        res.status(500).json({ error: 'Failed to list submissions' });
    }
});

/**
 * POST /api/crowd/submissions/:id/confirm
 * Owner confirms the physical location → station is published on the map.
 */
router.post('/submissions/:id/confirm', requireOwner, async (req: Request, res: Response) => {
    try {
        const id = req.params.id;
        if (!id) {
            return res.status(400).json({ error: 'id is required' });
        }
        const submission = await prisma.stationSubmission.findUnique({ where: { id } });
        if (!submission) {
            return res.status(404).json({ error: 'Submission not found' });
        }
        if (submission.status === 'OWNER_CONFIRMED' && submission.published_station_id) {
            return res.json({
                ...serializeSubmission(submission),
                already_published: true,
            });
        }

        const base = {
            external_id: `user:${submission.id}`,
            name: submission.name,
            operator_name: submission.operator_name,
            address: submission.address,
            latitude: submission.latitude,
            longitude: submission.longitude,
            is_public: true,
        };
        const station = await prisma.station.create({
            data: submission.connector_note
                ? {
                      ...base,
                      connectors: {
                          create: {
                              evse_id: `user:${submission.id}:1`,
                              type: 'TYPE2' as const,
                              max_power_kw: 22,
                              status: 'UNKNOWN' as const,
                              tariff: submission.connector_note,
                          },
                      },
                  }
                : base,
        });

        const updated = await prisma.stationSubmission.update({
            where: { id },
            data: {
                status: 'OWNER_CONFIRMED',
                published_station_id: station.id,
                owner_note: typeof req.body?.owner_note === 'string' ? req.body.owner_note : null,
            },
        });

        res.json({
            ...serializeSubmission(updated),
            published_station_id: station.id,
        });
    } catch (error) {
        console.error('Error confirming submission:', error);
        res.status(500).json({ error: 'Failed to confirm submission' });
    }
});

router.post('/submissions/:id/reject', requireOwner, async (req: Request, res: Response) => {
    try {
        const id = req.params.id;
        if (!id) {
            return res.status(400).json({ error: 'id is required' });
        }
        const submission = await prisma.stationSubmission.findUnique({ where: { id } });
        if (!submission) {
            return res.status(404).json({ error: 'Submission not found' });
        }
        const updated = await prisma.stationSubmission.update({
            where: { id },
            data: {
                status: 'REJECTED',
                owner_note: typeof req.body?.owner_note === 'string' ? req.body.owner_note : 'Rejected',
            },
        });
        res.json(serializeSubmission(updated));
    } catch (error) {
        console.error('Error rejecting submission:', error);
        res.status(500).json({ error: 'Failed to reject submission' });
    }
});

const answers = new Set(['YES', 'NO', 'DISMISSED']);

/**
 * POST /api/crowd/check-in
 * Driver arrived: is it working? are there free connectors? Yes / No / Dismiss.
 */
router.post('/check-in', async (req: Request, res: Response) => {
    try {
        const { station_id, reporter_id, working, free_connectors, latitude, longitude } =
            req.body ?? {};
        if (!station_id || !answers.has(working) || !answers.has(free_connectors)) {
            return res.status(400).json({
                error: 'station_id, working and free_connectors (YES|NO|DISMISSED) are required',
            });
        }
        const station = await prisma.station.findUnique({ where: { id: String(station_id) } });
        if (!station) {
            return res.status(404).json({ error: 'Station not found' });
        }
        const row = await prisma.siteCheckIn.create({
            data: {
                station_id: String(station_id),
                reporter_id: reporter_id ? String(reporter_id) : 'anonymous',
                working,
                free_connectors,
                latitude: latitude == null ? null : Number(latitude),
                longitude: longitude == null ? null : Number(longitude),
            },
        });
        res.status(201).json({
            id: row.id,
            station_id: row.station_id,
            working: row.working,
            free_connectors: row.free_connectors,
        });
    } catch (error) {
        console.error('Error saving check-in:', error);
        res.status(500).json({ error: 'Failed to save check-in' });
    }
});

export default router;
