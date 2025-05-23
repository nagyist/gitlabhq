# frozen_string_literal: true

class QueueBackfillFreeSharedRunnersMinutesLimit < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillFreeSharedRunnersMinutesLimit"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 100

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175354
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175354
  end
end
