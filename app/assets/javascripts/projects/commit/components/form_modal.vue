<script>
import { GlModal, GlForm, GlFormCheckbox, GlSprintf, GlFormGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import api from '~/api';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import csrf from '~/lib/utils/csrf';
import eventHub from '../event_hub';
import BranchesDropdown from './branches_dropdown.vue';
import ProjectsDropdown from './projects_dropdown.vue';

export default {
  components: {
    BranchesDropdown,
    ProjectsDropdown,
    GlModal,
    GlForm,
    GlFormCheckbox,
    GlSprintf,
    GlFormGroup,
  },
  inject: {
    prependedText: {
      default: '',
    },
  },
  props: {
    i18n: {
      type: Object,
      required: true,
    },
    openModal: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    isCherryPick: {
      type: Boolean,
      required: false,
      default: false,
    },
    primaryActionEventName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      checked: true,
      actionPrimary: {
        text: this.i18n.actionPrimaryText,
        attributes: {
          variant: 'confirm',
          category: 'primary',
          'data-testid': 'submit-commit',
        },
      },
      actionCancel: {
        text: this.i18n.actionCancelText,
        attributes: { 'data-testid': 'cancel-commit' },
      },
    };
  },
  computed: {
    ...mapState([
      'branch',
      'endpoint',
      'pushCode',
      'branchCollaboration',
      'modalTitle',
      'existingBranch',
      'targetProjectId',
      'targetProjectName',
    ]),
  },
  mounted() {
    eventHub.$on(this.openModal, this.show);
  },
  methods: {
    ...mapActions(['clearModal', 'setBranch', 'setSelectedBranch', 'setSelectedProject']),
    show() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    handlePrimary() {
      if (this.primaryActionEventName) {
        api.trackRedisHllUserEvent(this.primaryActionEventName);
      }

      this.$refs.form.$el.submit();
    },
    resetModalHandler() {
      this.clearModal();
      this.setSelectedBranch('');
      this.checked = true;
    },
  },
  csrf,
};
</script>
<template>
  <gl-modal
    v-bind="$attrs"
    data-testid="modal-commit"
    :modal-id="modalId"
    size="sm"
    :title="modalTitle"
    :action-cancel="actionCancel"
    :action-primary="actionPrimary"
    @hidden="resetModalHandler"
    @primary="handlePrimary"
  >
    <p v-if="prependedText.length" data-testid="prepended-text">
      <gl-sprintf :message="prependedText" />
    </p>

    <gl-form ref="form" :action="endpoint" method="post">
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />

      <gl-form-group
        v-if="isCherryPick"
        :label="i18n.projectLabel"
        label-for="start_project"
        data-testid="dropdown-group"
      >
        <input
          id="target_project_id"
          type="hidden"
          name="target_project_id"
          :value="targetProjectId"
        />

        <projects-dropdown :value="targetProjectName" @input="setSelectedProject" />
      </gl-form-group>

      <gl-form-group
        :label="i18n.branchLabel"
        label-for="start_branch"
        data-testid="dropdown-group"
      >
        <input id="start_branch" type="hidden" name="start_branch" :value="branch" />

        <branches-dropdown :value="branch" @input="setBranch" />
      </gl-form-group>

      <gl-form-checkbox
        v-if="pushCode"
        v-model="checked"
        name="create_merge_request"
        class="gl-mt-3"
      >
        <gl-sprintf :message="i18n.startMergeRequest">
          <template #newMergeRequest>
            <strong>{{ i18n.newMergeRequest }}</strong>
          </template>
        </gl-sprintf>
      </gl-form-checkbox>
      <input v-else type="hidden" name="create_merge_request" value="1" />
    </gl-form>

    <p v-if="!pushCode" class="gl-mb-0 gl-mt-5" data-testid="appended-text">
      <gl-sprintf v-if="branchCollaboration" :message="i18n.existingBranch">
        <template #branchName>
          <strong>{{ existingBranch }}</strong>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="i18n.branchInFork" />
    </p>
  </gl-modal>
</template>
