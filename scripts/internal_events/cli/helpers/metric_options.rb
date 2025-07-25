# frozen_string_literal: true

# Helpers related to listing existing metric definitions
module InternalEventsCli
  module Helpers
    module MetricOptions
      # Creates a list of metrics to be used as options in a
      # select/multiselect menu; existing metrics and metrics for
      # unavailable identifiers are marked as disabled
      #
      # @param events [Array<ExistingEvent>]
      # @return [Array<Hash>] hash (compact) has keys/values:
      #   value: [Array<NewMetric>]
      #   name: [String] formatted description of the metrics
      #   disabled: [String] reason metrics are disabled
      def get_metric_options(events)
        selection = EventSelection.new(events)
        available_options = []
        disabled_options = []

        options = get_all_metric_options(selection.actions)

        options.each do |metric|
          identifier = metric.identifier.value

          # Hide the filtered version of an option if unsupported; it just adds noise without value. Still,
          # showing unsupported options is valuable, because it advertises possibilities and explains why
          # those options aren't available.
          next if metric.filtered? && !selection.can_be_unique?(identifier)
          next if metric.filtered? && !selection.can_filter_when_unique?(identifier)
          next if selection.exclude_filter_identifier?(identifier)

          option = Option.new(
            metric: metric,
            events_name: selection.events_name,
            filter_name: (selection.filter_name(identifier) if metric.filtered?),
            defined: false,
            supported: true
          )

          conflicting_timeframes = get_conflicting_timeframes(metric)
          available_timeframes = metric.time_frame.value - conflicting_timeframes

          if conflicting_timeframes.any?
            disabled_metric = metric.dup
            disabled_metric[:time_frame] = conflicting_timeframes

            disabled_option = option.dup
            disabled_option.defined = true
            disabled_option.metric = disabled_metric

            disabled_options << disabled_option.formatted
          end

          next if available_timeframes.none?

          metric[:time_frame] = available_timeframes.sort

          if selection.can_be_unique?(identifier)
            available_options << option.formatted
          else
            option.supported = false
            disabled_options << option.formatted
          end
        end

        # Push disabled options to the end for better skimability;
        # retain relative order for continuity
        available_options + disabled_options
      end

      private

      # Lists all potential metrics supported in service ping,
      # ordered by: identifier > filters > time_frame
      #
      # @param actions [Array<String>] event names
      # @return [Array<NewMetric>]
      def get_all_metric_options(actions)
        [
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'user'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'project'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'namespace'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'user', filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'project', filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'namespace', filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d all]),
          Metric.new(actions: actions, time_frame: %w[7d 28d all], filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'label'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'property'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'value'),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'label', filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'property', filters: []),
          Metric.new(actions: actions, time_frame: %w[7d 28d], identifier: 'value', filters: [])
        ]
      end

      def get_conflicting_timeframes(metric)
        return [] if metric.filters_expected?

        cli.global.metrics.flat_map do |existing_metric|
          next if existing_metric.filtered?
          next unless (existing_metric.unique_ids & metric.unique_ids).any?

          existing_metric.time_frame
        end.compact.uniq
      end

      # Represents the attributes of set of events that depend on
      # the other events in the set
      EventSelection = Struct.new(:events) do
        def actions
          events.map(&:action)
        end

        # Very brief summary of the provided events to use in a
        # basic description of the metric
        # This ignores filters for simplicity & skimability
        def events_name
          return actions.first if actions.length == 1

          "any of #{actions.length} events"
        end

        # Formatted list of filter options for these events, given
        # the provided uniqueness constraint
        def filter_name(identifier)
          filter_options.difference([identifier]).join('/')
        end

        # We accept different filters for each event, so we want
        # any filter options available for any event
        def filter_options
          events.flat_map(&:available_filters).uniq
        end

        # We require the same uniqueness constraint for all events,
        # so we want only the options they have in common
        def uniqueness_options
          [*shared_identifiers, *shared_filters, nil]
        end

        # Whether there are any filtering options other than the
        # selected uniqueness constraint
        def can_filter_when_unique?(identifier)
          can_be_unique?(identifier) && filter_options.difference([identifier]).any?
        end

        # Whether the given identifier is available for all events
        # and can be used as a uniqueness constraint
        def can_be_unique?(identifier)
          uniqueness_options.include?(identifier)
        end

        # Common values for identifiers shared across all the events
        def shared_identifiers
          events.map(&:identifiers).reduce(&:&)
        end

        # Common values for filters shared across all the events
        def shared_filters
          events.map(&:available_filters).reduce(&:&)
        end

        # Whether none of the events have additional properties
        # and the given identifier is an additional property.
        # In this case, it makes sense to exclude these from the
        # menu to keep the flow simple when the use-case is simple
        def exclude_filter_identifier?(identifier)
          return false if identifier.nil? || Metric::Identifier.new(identifier).default?

          filter_options.empty?
        end
      end

      # Formats & structures a single select/multiselect menu item
      #
      # @param identifier [String, nil] if present, used in unique-by-identifier metrics
      # @param events_name [String] how the selected events will be referred to as a group
      # @param filter_name [String] how the potential filters will be referred to as a group
      # @param metrics [Array<NewMetric>]
      # @option defined [Boolean] whether this metric already exists
      # @option supported [Boolean] whether unique metrics are supported for this identifier
      Option = Struct.new(:events_name, :filter_name, :metric, :defined, :supported,
        keyword_init: true) do
        include InternalEventsCli::Helpers::Formatting

        # @return [Hash] see #get_metric_options for format
        # ex) Monthly/Weekly count of unique users who triggered cli_template_included where label/property is...
        # ex) Monthly/Weekly count of unique users who triggered cli_template_included (user unavailable)
        def formatted
          name = [time_frame_phrase, identifier_phrase, filter_phrase].compact.join(' ')
          name = format_help(name) if disabled

          { name: name, disabled: disabled, value: metric }.compact
        end

        def identifier
          metric.identifier
        end

        # ex) "Monthly/Weekly"
        def time_frame_phrase
          phrase = metric.time_frame.description

          disabled ? phrase : format_info(phrase)
        end

        # ex) "count of unique users who triggered cli_template_included"
        def identifier_phrase
          phrase = identifier.description % events_name
          phrase.gsub!(unique_phrase, format_info(unique_phrase)) unless disabled

          phrase
        end

        # ex) "unique users"
        def unique_phrase
          "unique #{identifier.plural}"
        end

        # ex) "where label/property is..."
        def filter_phrase
          return unless filter_name
          return "where filtered" if disabled

          "#{format_info("where #{filter_name}")} is..."
        end

        # Returns the string to include at the end of disabled
        # menu items. Nil if menu item shouldn't be disabled
        def disabled
          if defined
            pastel.bold(format_help("(already defined)"))
          elsif !supported
            pastel.bold(format_help("(#{identifier.value} unavailable)"))
          end
        end
      end
    end
  end
end
