module Sprig
  module Helpers
    def seed_directory
      Sprig.configuration.directory
    end

    def seed_base
      Sprig.configuration.base_directory
    end

    def sprig_environment
      # FIXME use record environment
      Sprig.configuration.environment
    end

    def sprig(directive_definitions)
      hopper = []
      DirectiveList.new(directive_definitions).add_seeds_to_hopper(hopper)
      Planter.new(hopper).sprig
    end

    def sprig_record(klass, seed_id)
      SprigRecordStore.instance.get(klass, seed_id)
    end

    def sprig_file(relative_path)
      # FIXME use record seed_directory
      File.new(seed_base.join(relative_path))
    end
  end
end
