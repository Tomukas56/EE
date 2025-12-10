# ADR 001: Data Storage Strategy vs. Real-Time Fetching

## 1. Context
The "Energy Eniwhere" application needs to display thousands of charging stations on a map. The user has raised a question: **Should we store station data in our own database, or fetch it directly from CPO APIs via the internet every time the app is used?**

## 2. Options Analysis

### Option A: Pure Real-Time (Proxy Model)
The app requests stations from the Backend, which immediately forwards the request to all CPO APIs (Ignitis, Elinta, etc.), aggregates results, and returns them. **No data is stored.**

*   **Pros:**
    *   Data is always 100% fresh (real-time).
    *   No database storage costs for station data.
    *   No complex synchronization logic needed.
*   **Cons:**
    *   **Performance (Critical)**: Querying 5+ external APIs takes time (e.g., 500ms - 2s). The user waits this long every time they move the map.
    *   **Clustering Issues**: To cluster markers (e.g., "10 stations here"), you need *all* data. Fetching all data from all providers every time is extremely slow and bandwidth-heavy.
    *   **Reliability**: If one CPO API is down, that part of the map is blank.
    *   **Rate Limiting**: CPOs will block us if we spam their API for every user map interaction.

### Option B: Local Database / Hybrid (Aggregator Model) - **RECOMMENDED**
We store "Static Data" (Location, Name, ID) in our database and update it periodically (e.g., daily). We fetch "Dynamic Data" (Status) only when needed.

*   **Pros:**
    *   **Performance**: Querying our own optimized PostGIS database takes < 50ms. Map loads instantly.
    *   **User Experience**: Smooth panning/zooming and clustering.
    *   **Reliability**: Even if a CPO API is down, users can still see the station exists (just maybe not its live status).
    *   **Search/Filter**: We can perform complex queries (e.g., "Find CCS plugs > 50kW within 10km") efficiently without relying on CPO search capabilities.
*   **Cons:**
    *   **Staleness**: If a new station is built today, it won't appear until the nightly sync runs.
    *   **Complexity**: Need to write a "Sync Worker" to keep data updated.

## 3. Evaluation & Recommendation

| Feature | Real-Time (Proxy) | Local DB (Hybrid) | Winner |
| :--- | :--- | :--- | :--- |
| **Map Loading Speed** | Slow (Seconds) | Instant (Milliseconds) | **Local DB** |
| **Data Freshness** | Perfect | Good (Static), Perfect (Dynamic) | **Real-Time** |
| **Reliability** | Low (Depends on CPOs) | High (Independent) | **Local DB** |
| **Scalability** | Poor (API Limits) | High | **Local DB** |

### Conclusion
**We must use the Hybrid Approach (Option B).**

It is **inefficient** and **risky** to rely solely on real-time internet fetching for the map view because:
1.  Users expect maps to be responsive.
2.  Mobile data usage would be high.
3.  We cannot perform efficient filtering or clustering without local data.

**The Strategy:**
1.  **Store** locations locally (for speed).
2.  **Fetch** status over the internet (for accuracy) only for the stations the   user is currently looking at.
