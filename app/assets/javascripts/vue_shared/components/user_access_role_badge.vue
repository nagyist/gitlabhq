<script>
/**
 * This component applies particular styling to GlBadge that isn't
 * available in the current GlBadge variants.
 * Where possible, prefer one of the supported GlBadge variants.
 * Discussion issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1247
 */
import { GlBadge } from '@gitlab/ui';

export default {
  name: 'UserAccessRoleBadge',
  components: {
    GlBadge,
  },
};
</script>

<template>
  <gl-badge class="!gl-bg-transparent !gl-shadow-inner-1-gray-100">
    <slot></slot>
  </gl-badge>
</template>
