/* global axios */
import ApiClient from '../ApiClient';

class CrmV2DealsAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  get(params = {}) {
    const { contactId } = params;
    const queryParams = new URLSearchParams();
    if (contactId) queryParams.set('contact_id', contactId);

    const requestUrl = queryParams.toString()
      ? `${this.url}?${queryParams.toString()}`
      : this.url;

    return axios.get(requestUrl);
  }

  create(deal) {
    return axios.post(this.url, deal);
  }
}

export default new CrmV2DealsAPI();
