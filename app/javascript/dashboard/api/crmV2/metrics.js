/* global axios */
import ApiClient from '../ApiClient';

class CrmV2MetricsAPI extends ApiClient {
  constructor() {
    super('crm/metrics', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }
}

export default new CrmV2MetricsAPI();
