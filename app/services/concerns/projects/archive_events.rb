# frozen_string_literal: true

module Projects
  module ArchiveEvents
    def publish_events
      publish_project_archived_event
    end

    def publish_project_archived_event
      event = Projects::ProjectArchivedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id
      })

      Gitlab::EventStore.publish(event)
    end
  end
end
