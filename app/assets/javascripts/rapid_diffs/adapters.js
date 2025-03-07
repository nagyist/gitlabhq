import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';
import { OptionsMenuAdapter } from '~/rapid_diffs/options_menu/adapter';
import { ToggleFileAdapter } from '~/rapid_diffs/toggle_file/adapter';

const RAPID_DIFFS_VIEWERS = {
  text_inline: 'text_inline',
  text_parallel: 'text_parallel',
};

const COMMON_ADAPTERS = [ExpandLinesAdapter, OptionsMenuAdapter, ToggleFileAdapter];

export const VIEWER_ADAPTERS = {
  [RAPID_DIFFS_VIEWERS.text_inline]: COMMON_ADAPTERS,
  [RAPID_DIFFS_VIEWERS.text_parallel]: COMMON_ADAPTERS,
};
