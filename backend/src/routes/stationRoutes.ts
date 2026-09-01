import express, { type Request, type Response } from 'express';
import prisma from '../lib/prisma.js';

const router = express.Router();

function wantsJson(req: Request): boolean {
    const accept = req.get('accept') ?? '';
    return accept.includes('application/json');
}

function isBrowserDocument(req: Request): boolean {
    return req.get('sec-fetch-dest') === 'document' && !wantsJson(req);
}

function escapeHtml(value: string): string {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function page(title: string, body: string): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${escapeHtml(title)}</title>
  <style>
    :root { color-scheme: light; }
    body { font-family: system-ui, sans-serif; margin: 0; background: #f4f7fb; color: #122; }
    header { background: linear-gradient(90deg,#0066FF,#00D9C0); color: #fff; padding: 20px 24px; }
    header p { margin: 8px 0 0; opacity: .9; }
    main { padding: 20px 24px 48px; max-width: 1100px; }
    input { width: min(420px, 100%); padding: 10px 12px; border: 1px solid #cdd; border-radius: 8px; font-size: 16px; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; background: #fff; border-radius: 12px; overflow: hidden; }
    th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid #eef; font-size: 14px; }
    th { background: #eef6ff; }
    tr:hover td { background: #f8fbff; }
    a { color: #0066FF; }
    .muted { color: #667; }
    .card { background: #fff; padding: 20px; border-radius: 12px; }
    .conn { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 12px; }
    .badge { background: #eef6ff; padding: 6px 10px; border-radius: 999px; font-size: 13px; }
  </style>
</head>
<body>
${body}
</body>
</html>`;
}

/**
 * GET /api/stations
 * JSON for the app; HTML when opened in a browser (raw 1900+ row JSON looks blank).
 */
router.get('/', async (req: Request, res: Response) => {
    try {
        const stations = await prisma.station.findMany({
            where: { is_public: true },
            include: { connectors: true },
            orderBy: { name: 'asc' },
        });

        const response = stations.map(station => ({
            id: station.id,
            name: station.name,
            operator_name: station.operator_name,
            address: station.address,
            country_code: station.country_code,
            latitude: station.latitude ? Number(station.latitude) : null,
            longitude: station.longitude ? Number(station.longitude) : null,
            is_public: station.is_public,
            connector_count: station.connectors.length,
            available_connectors: station.connectors.filter(c => c.status === 'AVAILABLE').length,
            connector_types: [...new Set(station.connectors.map(c => c.type))],
            max_power_kw: station.connectors.reduce(
                (max, c) => Math.max(max, Number(c.max_power_kw) || 0),
                0,
            ),
        }));

        if (isBrowserDocument(req)) {
            const rows = response.map(station => `
              <tr>
                <td><a href="/api/stations/${encodeURIComponent(station.id)}">${escapeHtml(station.name)}</a></td>
                <td>${escapeHtml(station.country_code || '—')}</td>
                <td>${escapeHtml(station.operator_name || '—')}</td>
                <td>${escapeHtml(station.address)}</td>
                <td>${station.connector_count}</td>
              </tr>`).join('');

            res.type('html').send(page('Energy Eniwhere — Stations', `
              <header>
                <h1>Energy Eniwhere</h1>
                <p>${response.length} charging stations from Open Charge Map (LT, LV, EE, PL). Occupancy is not live.</p>
              </header>
              <main>
                <input id="q" type="search" placeholder="Filter by name, operator, address…" oninput="filterRows()"/>
                <table>
                  <thead><tr><th>Station</th><th>Country</th><th>Operator</th><th>Address</th><th>Connectors</th></tr></thead>
                  <tbody id="rows">${rows}</tbody>
                </table>
              </main>
              <script>
                function filterRows() {
                  const q = document.getElementById('q').value.toLowerCase();
                  for (const tr of document.querySelectorAll('#rows tr')) {
                    tr.style.display = tr.textContent.toLowerCase().includes(q) ? '' : 'none';
                  }
                }
              </script>
            `));
            return;
        }

        res.json(response);
    } catch (error) {
        console.error('Error fetching stations:', error);
        res.status(500).json({ error: 'Failed to fetch stations' });
    }
});

/**
 * GET /api/stations/:id
 */
router.get('/:id', async (req: Request, res: Response) => {
    try {
        const id = req.params.id;
        if (!id) {
            return res.status(400).json({ error: 'Station id is required' });
        }

        const station = await prisma.station.findUnique({
            where: { id },
            include: { connectors: true }
        });

        if (!station) {
            return res.status(404).json({ error: 'Station not found' });
        }

        const response = {
            id: station.id,
            name: station.name,
            operator_name: station.operator_name,
            address: station.address,
            country_code: station.country_code,
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

        if (isBrowserDocument(req)) {
            const connectors = response.connectors.map(c =>
                `<span class="badge">${escapeHtml(c.type)} ${c.max_power_kw} kW · ${escapeHtml(c.status)}</span>`
            ).join('');

            res.type('html').send(page(station.name, `
              <header>
                <h1>${escapeHtml(station.name)}</h1>
                <p><a href="/api/stations" style="color:#fff">← All stations</a></p>
              </header>
              <main>
                <div class="card">
                  <p><strong>Operator:</strong> ${escapeHtml(station.operator_name || '—')}</p>
                  <p><strong>Address:</strong> ${escapeHtml(station.address)}</p>
                  <p class="muted">${station.latitude ?? '—'}, ${station.longitude ?? '—'}</p>
                  ${station.website ? `<p><a href="${escapeHtml(station.website)}">${escapeHtml(station.website)}</a></p>` : ''}
                  <div class="conn">${connectors || '<span class="muted">No mapped connectors</span>'}</div>
                </div>
              </main>
            `));
            return;
        }

        res.json(response);
    } catch (error) {
        console.error('Error fetching station:', error);
        res.status(500).json({ error: 'Failed to fetch station' });
    }
});

export default router;
