module Sprig
  module Seed
    class Factory
      def self.new_from_directive(directive)
        raise ArgumentError, 'Must provide a Directive' unless directive.is_a? Directive

        klass      = directive.klass
        datasource = directive.datasource
        options    = directive.options

        new(klass, datasource, options)
      end

      def initialize(klass, datasource, options)
        self.klass             = klass
        self.datasource        = datasource
        self.initial_options   = options
      end

      def add_seeds_to_hopper(hopper)
        mapper = data_mapper
        datasource.records.each do |record_data|
          hopper << Entry.new(self, mapper ? mapper.call(record_data) : record_data)
        end
      end

      attr_reader :datasource, :klass

      def options
        @options ||= datasource.options.merge(initial_options)
      end

      def seed_directory
        datasource.directory
      end

      def seed_base
        datasource.base_directory
      end

      def sprig_environment
        datasource.environment
      end

      def sprig_file(relative_path)
        File.new(datasource.directory.join(relative_path))
      end

      private

      attr_reader :initial_options

      def klass=(klass)
        raise ArgumentError, 'Must provide a Class as first argument' unless klass.is_a? Class

        @klass = klass
      end

      def datasource=(datasource)
        raise ArgumentError, 'Datasource must respond to #records and #options' unless datasource.respond_to?(:records) && datasource.respond_to?(:options)

        @datasource = datasource
      end

      def data_mapper
        options[:data_mapper]
      end

      def data
        @data ||= datasource.to_hash
      end

      def initial_options=(initial_options)
        initial_options ||= {}
        @initial_options = initial_options.to_hash
      end
    end
  end
end
