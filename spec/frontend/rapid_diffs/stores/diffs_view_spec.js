import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { setCookie } from '~/lib/utils/common_utils';
import {
  DIFF_VIEW_COOKIE_NAME,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import vuexStore from '~/mr_notes/stores';

const defaultState = {
  updateUserEndpoint: '/update',
  streamUrl: '/stream',
};

jest.mock('~/lib/utils/common_utils');
jest.mock('~/diffs/utils/queue_events');

describe('Diffs view store', () => {
  let store;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onPut(defaultState.updateUserEndpoint).reply(HTTP_STATUS_OK);
    const pinia = createTestingPinia({
      stubActions: false,
      initialState: {
        diffsView: defaultState,
      },
    });
    setActivePinia(pinia);
    store = useDiffsView();
    useDiffsList().reloadDiffs.mockResolvedValue();
    jest.spyOn(vuexStore, 'dispatch').mockResolvedValue();
  });

  describe('#loadMetadata', () => {
    it('uses Vuex store to load metadata', () => {
      const spy = jest.spyOn(vuexStore, 'dispatch');
      store.metadataEndpoint = '/metadata';
      store.loadMetadata();
      expect(vuexStore.state.diffs.endpointMetadata).toBe('/metadata');
      expect(vuexStore.state.diffs.diffViewType).toBe('inline');
      expect(vuexStore.state.diffs.showWhitespace).toBe(true);
      expect(spy).toHaveBeenCalledWith('diffs/fetchDiffFilesMeta');
    });

    it('copies values from Vuex store for diff stats', async () => {
      vuexStore.state.diffs.addedLines = 1;
      vuexStore.state.diffs.removedLines = 2;
      vuexStore.state.diffs.realSize = '3';
      vuexStore.state.diffs.size = 2;
      vuexStore.state.diffs.plainDiffPath = 'plain/diffs';
      vuexStore.state.diffs.emailPatchPath = 'email/patch';
      vuexStore.state.diffs.renderOverflowWarning = true;
      await store.loadMetadata();
      expect(store.diffStats).toStrictEqual({
        addedLines: 1,
        removedLines: 2,
        diffsCount: 3,
        realSize: '3',
        size: 2,
        plainDiffPath: 'plain/diffs',
        emailPatchPath: 'email/patch',
        renderOverflowWarning: true,
      });
    });
  });

  describe('#updateDiffView', () => {
    it('calls reloadDiffs on diffsList store', () => {
      const spy = useDiffsList().reloadDiffs.mockResolvedValue();
      store.updateDiffView();
      expect(spy).toHaveBeenCalledWith(`${defaultState.streamUrl}?view=inline&w=0`);
    });
  });

  describe('#updateViewType', () => {
    it('handles switch to parallel view', () => {
      store.updateViewType('parallel');
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=parallel&w=0`,
      );
      expect(setCookie).toHaveBeenCalledWith(DIFF_VIEW_COOKIE_NAME, 'parallel');
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_DIFF_VIEW_SETTING,
        TRACKING_DIFF_VIEW_PARALLEL,
      ]);
      expect(store.viewType).toEqual('parallel');
    });

    it('handles switch to inline view', () => {
      store.updateViewType('inline');
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=0`,
      );
      expect(setCookie).toHaveBeenCalledWith(DIFF_VIEW_COOKIE_NAME, 'inline');
      expect(queueRedisHllEvents).toHaveBeenCalledWith([
        TRACKING_CLICK_DIFF_VIEW_SETTING,
        TRACKING_DIFF_VIEW_INLINE,
      ]);
      expect(store.viewType).toEqual('inline');
    });
  });

  describe('#updateShowWhitespace', () => {
    it('handles switch to hide whitespace', () => {
      store.updateShowWhitespace(false);
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=1`,
      );
      expect(store.showWhitespace).toEqual(false);
    });

    it('handles switch to show whitespace', () => {
      store.updateShowWhitespace(true);
      expect(useDiffsList().reloadDiffs).toHaveBeenCalledWith(
        `${defaultState.streamUrl}?view=inline&w=0`,
      );
      expect(store.showWhitespace).toEqual(true);
    });

    it('stores setting for authenticated users', async () => {
      store.updateShowWhitespace(true);
      await waitForPromises();
      expect(
        mockAxios.history.put.some(
          (item) => JSON.parse(item.data).show_whitespace_in_diffs === true,
        ),
      ).toBe(true);
    });
  });
});
