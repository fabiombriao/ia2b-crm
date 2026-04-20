/* global axios */
import ApiClient from '../ApiClient';

const DEFAULT_TTL_MS = 5 * 60 * 1000;
const statusCache = new Map();

class CrmV2StatusAPI extends ApiClient {
  constructor() {
    super('crm/status', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  getCached({ ttlMs = DEFAULT_TTL_MS, force = false } = {}) {
    const accountId = this.accountIdFromRoute;
    if (!accountId) return this.get();

    const cached = statusCache.get(accountId);
    const isValid =
      cached?.data &&
      typeof cached.fetchedAt === 'number' &&
      Date.now() - cached.fetchedAt < ttlMs;

    if (!force && isValid) return Promise.resolve({ data: cached.data });
    if (!force && cached?.inFlight) return cached.inFlight;

    const inFlight = this.get()
      .then(response => {
        statusCache.set(accountId, {
          data: response.data,
          fetchedAt: Date.now(),
          inFlight: null,
        });
        return response;
      })
      .catch(error => {
        statusCache.set(accountId, {
          data: cached?.data ?? null,
          fetchedAt: cached?.fetchedAt ?? 0,
          inFlight: null,
        });
        throw error;
      });

    statusCache.set(accountId, {
      data: cached?.data ?? null,
      fetchedAt: cached?.fetchedAt ?? 0,
      inFlight,
    });

    return inFlight;
  }
}

export default new CrmV2StatusAPI();
