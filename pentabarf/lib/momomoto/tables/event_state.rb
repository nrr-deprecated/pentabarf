module Momomoto
  class Event_state < Base
    def initialize
      super
      @domain = 'valuelist'
      @fields = {
        :event_state_id => Datatype::Integer.new( {:not_null=>true, :default=>true, :primary_key=>true, :serial=>true} ),
        :tag => Datatype::Varchar.new( {:not_null=>true, :length=>32} ),
        :rank => Datatype::Integer.new( {} )
      }
    end
  end
end
