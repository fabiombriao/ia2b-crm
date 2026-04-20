<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import crmV2ContactsAPI from 'dashboard/api/crmV2/contacts';
import crmV2DealsAPI from 'dashboard/api/crmV2/deals';
import crmV2PipelinesAPI from 'dashboard/api/crmV2/pipelines';
import crmV2StatusAPI from 'dashboard/api/crmV2/status';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const isStatusLoading = ref(false);
const status = ref(null);

const isLoading = ref(false);
const isError = ref(false);
const context = ref(null);

const shouldShowCreateDealModal = ref(false);
const isFetchingPipelines = ref(false);
const isCreatingDeal = ref(false);
const pipelines = ref([]);
const selectedPipelineId = ref(null);
const selectedStageId = ref(null);
const dealTitle = ref('');
const dealValue = ref('');

const openDealsCount = computed(() => context.value?.deals?.length || 0);
const pendingActivitiesCount = computed(
  () => context.value?.activities?.length || 0
);

const isCrmEnabled = computed(() => status.value?.enabled === true);

const selectedPipeline = computed(
  () =>
    pipelines.value.find(
      pipeline => pipeline.id === selectedPipelineId.value
    ) || null
);

const availableStages = computed(() => {
  const stages = selectedPipeline.value?.stages || [];
  return [...stages].sort((a, b) => (a.position || 0) - (b.position || 0));
});

const isCreateDisabled = computed(() => {
  return (
    isCreatingDeal.value ||
    isFetchingPipelines.value ||
    !dealTitle.value?.trim() ||
    !selectedStageId.value
  );
});

const fetchContext = async () => {
  if (!isCrmEnabled.value) {
    context.value = null;
    return;
  }

  isLoading.value = true;
  isError.value = false;
  try {
    const response = await crmV2ContactsAPI.context(props.contactId);
    context.value = response.data;
  } catch (error) {
    isError.value = true;
  } finally {
    isLoading.value = false;
  }
};

const fetchStatus = async () => {
  isStatusLoading.value = true;
  try {
    const response = await crmV2StatusAPI.getCached();
    status.value = response.data;
  } catch (error) {
    status.value = null;
  } finally {
    isStatusLoading.value = false;
  }
};

const setDefaultPipelineAndStage = () => {
  if (!pipelines.value.length) {
    selectedPipelineId.value = null;
    selectedStageId.value = null;
    return;
  }

  const defaultPipeline =
    pipelines.value.find(pipeline => pipeline.default) || pipelines.value[0];
  selectedPipelineId.value = defaultPipeline.id;

  const defaultStage = [...(defaultPipeline.stages || [])].sort(
    (a, b) => (a.position || 0) - (b.position || 0)
  )[0];
  selectedStageId.value = defaultStage?.id || null;
};

const fetchPipelines = async () => {
  isFetchingPipelines.value = true;
  try {
    const response = await crmV2PipelinesAPI.get();
    pipelines.value = response.data?.payload || [];
    setDefaultPipelineAndStage();
  } catch (error) {
    pipelines.value = [];
    selectedPipelineId.value = null;
    selectedStageId.value = null;
    useAlert(t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.PIPELINES_ERROR'));
  } finally {
    isFetchingPipelines.value = false;
  }
};

const openCreateDealModal = async () => {
  if (!isCrmEnabled.value) {
    useAlert(t('CRM_V2.INSTALLATION_DISABLED'));
    return;
  }

  shouldShowCreateDealModal.value = true;
  dealTitle.value = '';
  dealValue.value = '';
  await fetchPipelines();
};

const closeCreateDealModal = () => {
  shouldShowCreateDealModal.value = false;
  dealTitle.value = '';
  dealValue.value = '';
};

const createDeal = async () => {
  if (isCreateDisabled.value) {
    return;
  }

  if (!isCrmEnabled.value) {
    useAlert(t('CRM_V2.INSTALLATION_DISABLED'));
    return;
  }

  isCreatingDeal.value = true;
  try {
    await crmV2DealsAPI.create({
      deal: {
        contact_id: Number(props.contactId),
        title: dealTitle.value.trim(),
        stage_id: Number(selectedStageId.value),
        value: dealValue.value === '' ? null : dealValue.value,
      },
    });
    await fetchContext();
    closeCreateDealModal();
    useAlert(t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.SUCCESS'));
  } catch (error) {
    useAlert(t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.ERROR'));
  } finally {
    isCreatingDeal.value = false;
  }
};

const openCrm = () => {
  window.location.assign(
    accountScopedRoute('crm_v2_index', {}, { contactId: props.contactId })
  );
};

watch(
  () => props.contactId,
  () => {
    fetchContext();
  }
);

watch(selectedPipelineId, () => {
  if (!availableStages.value.length) {
    selectedStageId.value = null;
    return;
  }

  const stage = availableStages.value[0];
  selectedStageId.value = stage?.id || null;
});

onMounted(() => {
  fetchStatus().finally(() => fetchContext());
});
</script>

<template>
  <div class="px-2 pt-3">
    <div class="rounded-lg border border-n-weak bg-n-surface-2 p-4">
      <div class="flex items-center justify-between gap-3">
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('CRM_V2.CONVERSATION_PANEL.TITLE') }}
        </p>
        <div class="flex items-center gap-3">
          <button
            type="button"
            class="text-sm text-n-blue-text hover:underline"
            @click="openCreateDealModal"
          >
            {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL') }}
          </button>
          <button
            type="button"
            class="text-sm text-n-blue-text hover:underline"
            @click="openCrm"
          >
            {{ t('CRM_V2.CONVERSATION_PANEL.OPEN_CRM') }}
          </button>
        </div>
      </div>

      <div
        v-if="!isCrmEnabled && !isStatusLoading"
        class="mt-3 text-xs text-n-slate-11"
      >
        {{ t('CRM_V2.INSTALLATION_DISABLED') }}
      </div>
      <div
        v-else-if="isStatusLoading || isLoading"
        class="mt-3 text-xs text-n-slate-11"
      >
        {{ t('CRM_V2.LOADING') }}
      </div>
      <div v-else-if="isError" class="mt-3 text-xs text-n-slate-11">
        {{ t('CRM_V2.ERROR') }}
      </div>
      <div v-else class="mt-3 grid grid-cols-2 gap-3">
        <div class="rounded-md border border-n-weak p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.CONVERSATION_PANEL.OPEN_DEALS') }}
          </p>
          <p class="mt-1 text-base font-semibold text-n-slate-12">
            {{ openDealsCount }}
          </p>
        </div>
        <div class="rounded-md border border-n-weak p-3">
          <p class="text-xs text-n-slate-11">
            {{ t('CRM_V2.CONVERSATION_PANEL.PENDING_ACTIVITIES') }}
          </p>
          <p class="mt-1 text-base font-semibold text-n-slate-12">
            {{ pendingActivitiesCount }}
          </p>
        </div>
      </div>
    </div>

    <woot-modal
      v-model:show="shouldShowCreateDealModal"
      :on-close="closeCreateDealModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <div class="flex w-full flex-col gap-6 px-6 py-6">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.TITLE') }}
        </h3>

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.DEAL_TITLE') }}
          </label>
          <input
            v-model="dealTitle"
            type="text"
            class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="
              t(
                'CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.DEAL_TITLE_PLACEHOLDER'
              )
            "
          />
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div class="flex flex-col gap-2">
            <label class="text-sm font-medium text-n-slate-12">
              {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.PIPELINE') }}
            </label>
            <select
              v-model="selectedPipelineId"
              class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isFetchingPipelines || !pipelines.length"
            >
              <option
                v-for="pipeline in pipelines"
                :key="pipeline.id"
                :value="pipeline.id"
              >
                {{ pipeline.name }}
              </option>
            </select>
            <p v-if="isFetchingPipelines" class="text-xs text-n-slate-11">
              {{ t('CRM_V2.LOADING') }}
            </p>
            <p
              v-else-if="!pipelines.length"
              class="text-xs leading-5 text-n-slate-11"
            >
              {{
                t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.NO_PIPELINES')
              }}
            </p>
          </div>

          <div class="flex flex-col gap-2">
            <label class="text-sm font-medium text-n-slate-12">
              {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.STAGE') }}
            </label>
            <select
              v-model="selectedStageId"
              class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="!availableStages.length"
            >
              <option
                v-for="stage in availableStages"
                :key="stage.id"
                :value="stage.id"
              >
                {{ stage.name }}
              </option>
            </select>
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.VALUE') }}
          </label>
          <input
            v-model="dealValue"
            type="number"
            step="0.01"
            inputmode="decimal"
            class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="
              t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.VALUE_PLACEHOLDER')
            "
          />
        </div>

        <div class="flex items-center justify-end gap-3">
          <NextButton
            solid
            blue
            :label="t('CRM_V2.CONVERSATION_PANEL.CREATE_DEAL_MODAL.SAVE')"
            :is-loading="isCreatingDeal"
            :disabled="isCreateDisabled"
            @click="createDeal"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
