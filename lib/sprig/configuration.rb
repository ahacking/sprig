module Sprig
  class Configuration

    attr_writer :base_directory

    attr_writer :environment

    attr_writer :directory


    def directory
      Rails.root.join(base_directory, environment)
    end

    def base_directory
      @base_directory || 'db/seeds'
    end

    def environment
      @environment || Rails.env
    end
  end
end
