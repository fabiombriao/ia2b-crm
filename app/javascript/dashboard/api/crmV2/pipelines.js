import ApiClient from '../ApiClient';

class CrmV2PipelinesAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }
}

export default new CrmV2PipelinesAPI();
