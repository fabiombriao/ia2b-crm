import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';
import CrmV2Index from './pages/CrmV2Index.vue';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.CRM_V2,
  permissions: ['administrator', 'agent', 'custom_role'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm'),
    name: 'crm_v2_index',
    component: CrmV2Index,
    meta: commonMeta,
  },
];
