<script>
import { mapActions, mapState } from 'pinia';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { useNotes } from '~/notes/store/legacy_notes';

export default {
  components: {
    AwardsList,
  },
  props: {
    awards: {
      type: Array,
      required: true,
    },
    toggleAwardPath: {
      type: String,
      required: true,
    },
    noteId: {
      type: String,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
    defaultAwards: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState(useNotes, ['getUserData']),
  },
  methods: {
    ...mapActions(useNotes, ['toggleAwardRequest']),
    handleAward(awardName) {
      const data = {
        endpoint: this.toggleAwardPath,
        noteId: this.noteId,
        awardName,
      };

      this.toggleAwardRequest(data).catch(() =>
        createAlert({
          message: __('Something went wrong on our end.'),
        }),
      );
    },
  },
};
</script>

<template>
  <div class="note-awards">
    <awards-list
      :awards="awards"
      :can-award-emoji="canAwardEmoji"
      :current-user-id="getUserData.id"
      :default-awards="defaultAwards"
      @award="handleAward($event)"
    />
  </div>
</template>
