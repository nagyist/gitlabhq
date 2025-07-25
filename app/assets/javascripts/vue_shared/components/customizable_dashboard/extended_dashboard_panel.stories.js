import { s__, __ } from '~/locale';
import { VARIANT_DANGER, VARIANT_WARNING, VARIANT_INFO } from '~/alert';
import ExtendedDashboardPanel from './extended_dashboard_panel.vue';

export default {
  component: ExtendedDashboardPanel,
  title: 'vue_shared/components/customizable_dashboard/extended_dashboard_panel',
};

const Template = (args, { argTypes }) => ({
  components: { ExtendedDashboardPanel },
  props: Object.keys(argTypes),
  template: `
    <extended-dashboard-panel v-bind="$props" style="min-height: 7rem;">
      <template #body>
        <p><code>#body</code> slot content</p>
      </template>
      <template #alert-message>
        <div><code>#alert-message</code> slot content</div>
      </template>
    </extended-dashboard-panel>
  `,
});

export const Default = Template.bind({});
Default.args = {
  title: s__('ProductAnalytics|Audience'),
  tooltip: null,
  loading: false,
  showAlertState: false,
  alertPopoverTitle: '',
  actions: [],
  editing: false,
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

export const Error = Template.bind({});
Error.args = {
  ...Default.args,
  alertPopoverTitle: __('An error has occurred'),
  showAlertState: true,
  alertVariant: VARIANT_DANGER,
};

export const Warning = Template.bind({});
Warning.args = {
  ...Default.args,
  alertPopoverTitle: __('This is really just a warning'),
  showAlertState: true,
  alertVariant: VARIANT_WARNING,
};

export const Information = Template.bind({});
Information.args = {
  ...Default.args,
  alertPopoverTitle: __('Some friendly information'),
  showAlertState: true,
  alertVariant: VARIANT_INFO,
};

export const Editing = Template.bind({});
Editing.args = {
  ...Default.args,
  editing: true,
  actions: [
    {
      text: __('Delete'),
      icon: 'remove',
      action: () => {},
    },
  ],
};

export const WithInformationalTooltip = Template.bind({});
WithInformationalTooltip.args = {
  ...Default.args,
  tooltip: {
    description: __('This is some information. %{linkStart}Learn more%{linkEnd}.'),
    descriptionLink: '#',
  },
};

export const WithLoadingDelayed = Template.bind({});
WithLoadingDelayed.args = {
  ...Default.args,
  loading: true,
  loadingDelayed: true,
};
