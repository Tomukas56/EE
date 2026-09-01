import { Router, type Request, type Response } from 'express';
import prisma from '../lib/prisma.js';

const router = Router();

const LAB_EUR_PER_KWH = 0.32;

function serialize(session: {
    id: string;
    station_id: string;
    reporter_id: string;
    connector_type: string | null;
    max_power_kw: unknown;
    started_at: Date;
    ended_at: Date | null;
    energy_kwh: unknown;
    cost_eur: unknown;
    status: string;
    payment_method: string | null;
    station?: { name: string };
}) {
    return {
        id: session.id,
        station_id: session.station_id,
        station_name: session.station?.name ?? '',
        reporter_id: session.reporter_id,
        connector_type: session.connector_type ?? 'TYPE2',
        start_time: session.started_at.toISOString(),
        end_time: session.ended_at?.toISOString() ?? null,
        energy_kwh: session.energy_kwh != null ? Number(session.energy_kwh) : 0,
        cost_eur: session.cost_eur != null ? Number(session.cost_eur) : 0,
        status: session.status,
        payment_method: session.payment_method,
    };
}

router.get('/', async (req: Request, res: Response) => {
    try {
        const reporterId = String(req.query.reporterId || '').trim();
        if (!reporterId) {
            return res.status(400).json({ error: 'reporterId is required' });
        }
        const status = typeof req.query.status === 'string' ? req.query.status : undefined;
        const sessions = await prisma.chargingSession.findMany({
            where: {
                reporter_id: reporterId,
                ...(status ? { status } : {}),
            },
            include: { station: true },
            orderBy: { started_at: 'desc' },
            take: 100,
        });
        res.json(sessions.map(serialize));
    } catch (error) {
        console.error('Error listing sessions:', error);
        res.status(500).json({ error: 'Failed to list sessions' });
    }
});

router.post('/', async (req: Request, res: Response) => {
    try {
        const stationId = String(req.body?.station_id || '').trim();
        const reporterId = String(req.body?.reporter_id || '').trim();
        if (!stationId || !reporterId) {
            return res.status(400).json({ error: 'station_id and reporter_id are required' });
        }

        const station = await prisma.station.findUnique({
            where: { id: stationId },
            include: { connectors: true },
        });
        if (!station) {
            return res.status(404).json({ error: 'Station not found' });
        }

        const open = await prisma.chargingSession.findFirst({
            where: { reporter_id: reporterId, status: 'charging' },
            include: { station: true },
        });
        if (open) {
            return res.status(409).json({
                error: 'A charging session is already open',
                session: serialize(open),
            });
        }

        const connectorType =
            typeof req.body?.connector_type === 'string'
                ? req.body.connector_type
                : station.connectors[0]?.type ?? 'TYPE2';
        const maxPower =
            station.connectors.reduce(
                (max, c) => Math.max(max, Number(c.max_power_kw) || 0),
                0,
            ) || 22;

        const created = await prisma.chargingSession.create({
            data: {
                station_id: stationId,
                reporter_id: reporterId,
                connector_type: connectorType,
                max_power_kw: maxPower,
                status: 'charging',
            },
            include: { station: true },
        });
        res.status(201).json(serialize(created));
    } catch (error) {
        console.error('Error starting session:', error);
        res.status(500).json({ error: 'Failed to start session' });
    }
});

router.post('/:id/stop', async (req: Request, res: Response) => {
    try {
        const id = String(req.params.id || '').trim();
        if (!id) {
            return res.status(400).json({ error: 'Session id is required' });
        }
        const session = await prisma.chargingSession.findUnique({
            where: { id },
            include: { station: true },
        });
        if (!session) {
            return res.status(404).json({ error: 'Session not found' });
        }
        if (session.status !== 'charging') {
            return res.json(serialize(session));
        }

        const ended = new Date();
        const hours = Math.max((ended.getTime() - session.started_at.getTime()) / 3_600_000, 1 / 60);
        const powerKw = Number(session.max_power_kw) || 22;
        const energy = Math.round(hours * powerKw * 100) / 100;
        const cost = Math.round(energy * LAB_EUR_PER_KWH * 100) / 100;

        const updated = await prisma.chargingSession.update({
            where: { id },
            data: {
                ended_at: ended,
                energy_kwh: energy,
                cost_eur: cost,
                status: 'completed',
                payment_method: 'lab-estimate',
            },
            include: { station: true },
        });
        res.json(serialize(updated));
    } catch (error) {
        console.error('Error stopping session:', error);
        res.status(500).json({ error: 'Failed to stop session' });
    }
});

export default router;
