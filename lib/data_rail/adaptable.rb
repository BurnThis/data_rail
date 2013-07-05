require 'data_rail/adapted_collection'

module DataRail
  module Adaptable
    def adapt(*adapters)
      DataRail::AdaptedCollection.new(self, adapters)
    end
  end
end
