module Sprig
  module Seed
    class Entry

      COMPUTED_VALUE_REGEX = /<%[=]?(.*)%>/

      # handle literal id or single/double quoted id uniformly
      SPRIG_RECORD_REGEX = /(?:sprig_record\(([A-Z][^,\s]*)\s*,\s*(?:([^"'\s)]+)|"([^"]*)"|'([^']*)')\s*\))+/

      def initialize(factory, attrs)
        @factory = factory
        self.sprig_id = attrs.delete(:sprig_id) || attrs.delete('sprig_id') || SecureRandom.uuid
        @attributes = attrs
      end

      def dependency_id
        @dependency_id ||= Dependency.for(klass, sprig_id).id
      end

      def dependencies
        unless @dependencies
          @dependencies = []
          scan_dependencies(@attributes)
          @dependencies.uniq!
        end
        @dependencies
      end

      def before_save
        # TODO: make these filters take chains like rails before_filters
        if (keys = options[:delete_existing_by])
          klass.delete_all(conditions(keys))
        end
      end

      def save_record
        record.save
      end

      def save_to_store
        SprigRecordStore.instance.save(klass, sprig_id, record)
      end

      def success_log_text
        "#{klass.name} with sprig_id #{sprig_id} successfully saved."
      end

      def error_log_text
        "There was an error saving #{klass.name} with sprig_id #{sprig_id}.\nErrors:\n#{@record.errors.messages}"
      end

      def record
        @record ||= new_or_existing_record
      end

      def klass
        factory.klass
      end

      def options
        factory.options
      end

      attr_reader :factory, :attributes, :sprig_id

      private

      def sprig_id=(sprig_id)
        @sprig_id = sprig_id.to_s
      end

      def scan_dependencies(value)
        case value
        when Array
          value.each { |item| scan_dependencies(item) }
        when Hash
          value.values.each { |item| scan_dependencies(item) }
        when String
          # ERB style embedded value?
          if (matched = COMPUTED_VALUE_REGEX.match(value))
            # detect and accumulate dependencies, match word, or single/double quoted string
            matched[1].scan(SPRIG_RECORD_REGEX).each { |dep_match|
              # add dependency for klass and sprig_id
              @dependencies << Dependency.for(dep_match[0], (dep_match[1]||dep_match[2]||dep_match[3]))
            }
          end
        end
      end

      def resolved_attributes
        @resolved_attributes ||= resolve_computed(@attributes)
      end

      def resolve_computed(value)
        case value
        when Array
          value.each_with_index { |item,index| value[index] = resolve_computed(item) }
        when Hash
          value.each { |name,item| value[name] = resolve_computed(item) }
        when String
          # evaluate any computed values
          if (matched = COMPUTED_VALUE_REGEX.match(value))
            value = factory.instance_eval(matched[1])
          end
        end
        value
      end

      def new_or_existing_record
        if (keys = options[:find_existing_by]) && (rec = klass.where(conditions(keys)).first)
          resolved_attributes.each { |name,value| rec.send(:"#{name}=", value) }
          rec
        else
          klass.new(resolved_attributes)
        end
      end

      def assign_attributes
        resolved_attributes.each do |attribute|
          orm_record.send(:"#{attribute.name}=", attribute.value)
        end
      end

      def conditions(keys)
        keys = Array(keys)
        conditions = resolved_attributes.slice(*keys)
        raise AttributeNotFoundError, "Missing attributes: #{keys - conditions.keys}." unless conditions.count == keys.count
        conditions
      end
    end
  end
end
