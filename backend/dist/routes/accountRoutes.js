import { Router } from 'express';
import prisma from '../lib/prisma.js';
const router = Router();
/**
 * DELETE /api/account?reporterId=
 * Lab DSR erasure: sessions, check-ins, pending submissions.
 * Published POIs stay; submitter id is anonymised. Not JWT-locked (same as other lab APIs).
 */
router.delete('/', async (req, res) => {
    try {
        const reporterId = String(req.query.reporterId || req.body?.reporterId || '').trim();
        if (!reporterId) {
            return res.status(400).json({ error: 'reporterId is required' });
        }
        const [sessions, checkIns, pendingSubs, otherSubs] = await prisma.$transaction([
            prisma.chargingSession.deleteMany({ where: { reporter_id: reporterId } }),
            prisma.siteCheckIn.deleteMany({ where: { reporter_id: reporterId } }),
            prisma.stationSubmission.deleteMany({
                where: { submitted_by: reporterId, status: 'PENDING' },
            }),
            prisma.stationSubmission.updateMany({
                where: { submitted_by: reporterId, status: { not: 'PENDING' } },
                data: { submitted_by: 'deleted' },
            }),
        ]);
        res.json({
            ok: true,
            reporter_id: reporterId,
            deleted: {
                charging_sessions: sessions.count,
                check_ins: checkIns.count,
                pending_submissions: pendingSubs.count,
            },
            anonymised_submissions: otherSubs.count,
        });
    }
    catch (error) {
        console.error('Error erasing account data:', error);
        res.status(500).json({ error: 'Failed to erase account data' });
    }
});
export default router;
//# sourceMappingURL=accountRoutes.js.map