/* global axios */
import ApiClient from '../ApiClient';

class CrmV2ContactsAPI extends ApiClient {
  constructor() {
    super('crm/contacts', { accountScoped: true });
  }

  context(contactId) {
    return axios.get(`${this.url}/${contactId}/context`);
  }
}

export default new CrmV2ContactsAPI();
