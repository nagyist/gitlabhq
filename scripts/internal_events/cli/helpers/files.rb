# frozen_string_literal: true

# Helpers related reading/writing definition files
module InternalEventsCli
  module Helpers
    module Files
      def prompt_to_save_file(filepath, content)
        cli.say <<~TEXT.chomp
          #{format_info('Preparing to generate definition with these attributes:')}
          #{filepath}
          #{content}
        TEXT

        if File.exist?(filepath)
          cli.error("Oh no! This file already exists!\n")

          return if cli.no?(format_prompt('Overwrite file?'))

          write_to_file(filepath, content, 'update')
        elsif cli.yes?(format_prompt('Create file?'))
          write_to_file(filepath, content, 'create')
        end
      end

      def file_saved_message(verb, filepath)
        attributes = YAML.safe_load(File.read(filepath))
        errors = self.class::SCHEMA.validate(attributes)

        return "    #{format_selection(verb)} #{filepath}" if errors.none?

        format_prefix "    ", <<~TEXT
          #{format_selection(verb)} #{filepath}

          #{errors.map { |e| [format_warning('!! WARNING: '), JSONSchemer::Errors.pretty(e)].join }.join("\n")}

            These errors will cause one of the following specs to fail and should be resolved before merging your changes:
              - spec/lib/gitlab/tracking/event_definition_validate_all_spec.rb
              - spec/support/shared_examples/config/metrics/every_metric_definition_shared_examples.rb
        TEXT
      end

      def write_to_file(filepath, content, verb)
        File.write(filepath, content)

        file_saved_message(verb, filepath).tap { |message| cli.say message }
      end
    end
  end
end
