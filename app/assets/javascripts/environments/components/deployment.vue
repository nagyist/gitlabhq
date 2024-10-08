<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlBadge,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
  GlTruncate,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert } from '~/alert';
import deploymentDetails from '../graphql/queries/deployment_details.query.graphql';
import DeploymentStatusLink from './deployment_status_link.vue';
import Commit from './commit.vue';

export default {
  components: {
    ClipboardButton,
    Commit,
    DeploymentStatusLink,
    GlBadge,
    GlIcon,
    GlLink,
    GlSprintf,
    GlTruncate,
    GlLoadingIcon,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip,
  },
  inject: ['projectPath'],
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    latest: {
      type: Boolean,
      default: false,
      required: false,
    },
    visible: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    status() {
      return this.deployment?.status;
    },
    iid() {
      return this.deployment?.iid;
    },
    isTag() {
      return this.deployment?.tag;
    },
    shortSha() {
      return this.commit?.shortId;
    },
    timeStamp() {
      return this.deployment?.deployedAt ? __('Deployed %{timeago}') : __('Created %{timeago}');
    },
    displayTimeAgo() {
      return this.deployment?.deployedAt || this.deployment?.createdAt;
    },
    createdAt() {
      return this.deployment?.createdAt;
    },
    commit() {
      return this.deployment?.commit;
    },
    commitPath() {
      return this.commit?.commitPath;
    },
    user() {
      return this.deployment?.user;
    },
    username() {
      return `@${this.user.username}`;
    },
    userPath() {
      return this.user?.path;
    },
    deployable() {
      return this.deployment?.deployable;
    },
    jobName() {
      return this.deployable?.name;
    },
    jobPath() {
      return this.deployable?.buildPath;
    },
    ref() {
      return this.deployment?.ref;
    },
    refName() {
      return this.ref?.name;
    },
    refPath() {
      return this.ref?.refPath;
    },
    needsApproval() {
      return this.deployment.pendingApprovalCount > 0;
    },
    hasTags() {
      return this.tags?.length > 0;
    },
    displayTags() {
      return this.tags?.slice(0, 5);
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    tags: {
      query: deploymentDetails,
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.deployment.iid,
        };
      },
      update(data) {
        return data?.project?.deployment?.tags;
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.LOAD_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
      skip() {
        return !this.visible;
      },
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
    deploymentId: s__('Deployment|Deployment ID'),
    copyButton: __('Copy commit SHA'),
    commitSha: __('Commit SHA'),
    triggerer: s__('Deployment|Triggerer'),
    needsApproval: s__('Deployment|Needs Approval'),
    job: __('Job'),
    api: __('API'),
    branch: __('Branch'),
    tags: __('Tags'),
  },
  headerClasses: [
    'gl-flex',
    'gl-items-start',
    'md:gl-items-center',
    'gl-justify-between',
    'gl-pr-6',
  ],
  headerDetailsClasses: [
    'gl-flex',
    'gl-flex-col',
    'md:gl-flex-row',
    'gl-items-start',
    'md:gl-items-center',
    'gl-text-sm',
    'gl-text-gray-700',
  ],
  deploymentStatusClasses: [
    'gl-flex',
    'gl-gap-x-3',
    'gl-mr-0',
    'md:gl-mr-5',
    'gl-mb-3',
    'md:gl-mb-0',
  ],
};
</script>
<template>
  <div>
    <div :class="$options.headerClasses">
      <div :class="$options.headerDetailsClasses">
        <div :class="$options.deploymentStatusClasses">
          <deployment-status-link
            v-if="status"
            :deployment="deployment"
            :deployment-job="deployable"
            :status="status"
          />
          <gl-badge v-if="needsApproval" variant="warning">
            {{ $options.i18n.needsApproval }}
          </gl-badge>
          <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
        </div>
        <div class="gl-flex gl-items-center gl-gap-x-5">
          <div
            v-if="iid"
            v-gl-tooltip
            class="gl-flex"
            :title="$options.i18n.deploymentId"
            :aria-label="$options.i18n.deploymentId"
          >
            <gl-icon ref="deployment-iid-icon" name="deployments" />
            <span class="gl-ml-2">#{{ iid }}</span>
          </div>
          <div
            v-if="shortSha"
            data-testid="deployment-commit-sha"
            class="gl-flex gl-items-center gl-font-monospace"
          >
            <gl-icon ref="deployment-commit-icon" name="commit" class="gl-mr-2" />
            <gl-link v-gl-tooltip :title="$options.i18n.commitSha" :href="commitPath">
              {{ shortSha }}
            </gl-link>
            <clipboard-button
              :text="shortSha"
              category="tertiary"
              :title="$options.i18n.copyButton"
              size="small"
            />
          </div>
          <time-ago-tooltip
            v-if="displayTimeAgo"
            :time="displayTimeAgo"
            class="gl-flex"
            data-testid="deployment-timestamp"
          >
            <template #default="{ timeAgo }">
              <gl-icon name="calendar" class="gl-mr-2" />
              <span class="gl-mr-2 gl-whitespace-nowrap">
                <gl-sprintf :message="timeStamp">
                  <template #timeago>{{ timeAgo }}</template>
                </gl-sprintf>
              </span>
            </template>
          </time-ago-tooltip>
        </div>
      </div>
    </div>
    <commit v-if="commit" :commit="commit" class="gl-mt-3" />
    <div class="gl-mt-3"><slot name="approval"></slot></div>
    <div class="gl-mt-5 gl-flex gl-flex-col gl-pr-4 md:gl-flex-row md:gl-items-center md:gl-pr-0">
      <div v-if="user" class="gl-flex gl-flex-col md:gl-max-w-3/20">
        <span class="gl-text-gray-500">{{ $options.i18n.triggerer }}</span>
        <gl-link :href="userPath" class="gl-mt-3 gl-font-monospace">
          <gl-truncate :text="username" with-tooltip />
        </gl-link>
      </div>
      <div class="gl-mt-4 gl-flex gl-flex-col md:gl-mt-0 md:gl-max-w-3/20 md:gl-pl-7">
        <span class="gl-text-gray-500" :class="{ 'gl-ml-3': !deployable }">
          {{ $options.i18n.job }}
        </span>
        <gl-link v-if="jobPath" :href="jobPath" class="gl-mt-3 gl-font-monospace">
          <gl-truncate :text="jobName" with-tooltip position="middle" />
        </gl-link>
        <span v-else-if="jobName" class="gl-mt-3 gl-font-monospace">
          <gl-truncate :text="jobName" with-tooltip position="middle" />
        </span>
        <gl-badge v-else class="gl-mt-3 gl-font-monospace" variant="info">
          {{ $options.i18n.api }}
        </gl-badge>
      </div>
      <div
        v-if="ref && !isTag"
        class="gl-mt-4 gl-flex gl-flex-col md:gl-mt-0 md:gl-max-w-3/20 md:gl-pl-7"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.branch }}</span>
        <gl-link :href="refPath" class="gl-mt-3 gl-font-monospace">
          <gl-truncate :text="refName" with-tooltip />
        </gl-link>
      </div>
      <div
        v-if="hasTags || $apollo.queries.tags.loading"
        class="gl-mt-4 gl-flex gl-flex-col md:gl-mt-0 md:gl-max-w-3/20 md:gl-pl-7"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.tags }}</span>
        <gl-loading-icon
          v-if="$apollo.queries.tags.loading"
          class="gl-mt-3 gl-font-monospace"
          size="sm"
          inline
        />
        <div v-if="hasTags" class="gl-flex gl-flex-row">
          <gl-link
            v-for="(tag, ndx) in displayTags"
            :key="tag.name"
            :href="tag.path"
            class="gl-mr-3 gl-mt-3 gl-font-monospace"
          >
            {{ tag.name }}<span v-if="ndx + 1 < tags.length">, </span>
          </gl-link>
          <div v-if="tags.length > 5" class="gl-mr-3 gl-mt-3 gl-font-monospace">...</div>
        </div>
      </div>
    </div>
  </div>
</template>
