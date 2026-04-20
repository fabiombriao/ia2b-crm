<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import crmV2StatusAPI from 'dashboard/api/crmV2/status';
import crmV2MetricsAPI from 'dashboard/api/crmV2/metrics';
import crmV2DealsAPI from 'dashboard/api/crmV2/deals';

const { t } = useI18n();
const route = useRoute();

const isLoading = ref(true);
const isError = ref(false);

const status = ref(null);
const metrics = ref(null);
const deals = ref([]);

const contactId = computed(() => route.query?.contactId);

onMounted(async () => {
  isLoading.value = true;
  isError.value = false;
  try {
    const statusResponse = await crmV2StatusAPI.getCached();
    status.value = statusResponse.data;

    if (status.value?.enabled && status.value?.feature_enabled !== false) {
      const metricsResponse = await crmV2MetricsAPI.get();
      metrics.value = metricsResponse.data;

      if (contactId.value) {
        const dealsResponse = await crmV2DealsAPI.get({
          contactId: contactId.value,
        });
        deals.value = dealsResponse.data?.payload || [];
      } else {
        deals.value = [];
      }
    } else {
      metrics.value = null;
      deals.value = [];
    }
  } catch (error) {
    isError.value = true;
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('CRM_V2.TITLE') }}
      </h1>
    </div>

    <div v-if="isLoading" class="text-sm text-n-slate-11">
      {{ t('CRM_V2.LOADING') }}
    </div>

    <div v-else-if="isError" class="text-sm text-n-slate-11">
      {{ t('CRM_V2.ERROR') }}
    </div>

    <div v-else class="flex flex-col gap-4">
      <div v-if="!status?.enabled" class="rounded-lg border border-n-weak p-4">
        <p class="text-sm text-n-slate-11">
          {{ t('CRM_V2.INSTALLATION_DISABLED') }}
        </p>
      </div>

      <div
        v-if="status?.feature_enabled === false"
        class="rounded-lg border border-n-weak p-4"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CRM_V2.FEATURE_DISABLED') }}
        </p>
      </div>

      <div
        v-if="status?.enabled && status?.feature_enabled !== false"
        class="grid grid-cols-1 gap-4 md:grid-cols-4"
      >
        <div class="rounded-lg border border-n-weak p-4">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.METRICS.OPEN_DEALS') }}
          </p>
          <p class="mt-2 text-lg font-semibold text-n-slate-12">
            {{ metrics?.open_deals_count ?? 0 }}
          </p>
        </div>
        <div class="rounded-lg border border-n-weak p-4">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.METRICS.OPEN_VALUE') }}
          </p>
          <p class="mt-2 text-lg font-semibold text-n-slate-12">
            {{ metrics?.open_value ?? 0 }}
          </p>
        </div>
        <div class="rounded-lg border border-n-weak p-4">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.METRICS.WON_VALUE') }}
          </p>
          <p class="mt-2 text-lg font-semibold text-n-slate-12">
            {{ metrics?.won_value ?? 0 }}
          </p>
        </div>
        <div class="rounded-lg border border-n-weak p-4">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.METRICS.OVERDUE_ACTIVITIES') }}
          </p>
          <p class="mt-2 text-lg font-semibold text-n-slate-12">
            {{ metrics?.overdue_activities_count ?? 0 }}
          </p>
        </div>
      </div>

      <div
        v-if="status?.enabled && status?.feature_enabled !== false && contactId"
        class="rounded-lg border border-n-weak p-4"
      >
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('CRM_V2.DEALS.TITLE') }}
        </p>

        <div v-if="deals.length" class="mt-3 flex flex-col gap-2">
          <div
            v-for="deal in deals"
            :key="deal.id"
            class="flex items-center justify-between gap-3 rounded-md border border-n-weak bg-n-surface-1 px-3 py-2"
          >
            <div class="flex flex-col">
              <p class="text-sm font-medium text-n-slate-12">
                {{ deal.title }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ deal.stage?.name || '' }}
              </p>
            </div>
            <p class="text-xs text-n-slate-11">
              {{ deal.status }}
            </p>
          </div>
        </div>
        <p v-else class="mt-3 text-sm text-n-slate-11">
          {{ t('CRM_V2.DEALS.EMPTY') }}
        </p>
      </div>
    </div>
  </div>
</template>
