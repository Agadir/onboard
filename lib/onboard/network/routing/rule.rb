class OnBoard
  module Network
    module Routing
      class Rule

        def self.getAll
          all = []
          `ip rule show`.each_line do |line|
            if line =~ /^(\d+):\s+from\s+(\S+)\s+(fwmark\s+(\S+)\s+)?(lookup|table)\s+(\S+)/
              all << self.new(
                :prio   => $1,
                :from   => $2,
                :fwmark => $4,
                :table  => $6
              )
            end
          end
          return all
        end

        attr_reader :prio, :from, :table, :fwmark

        def initialize(h)
          @prio   = h[:prio]
          @from   = h[:from]
          @table  = h[:table]
          @fwmark = h[:fwmark]
        end

        def data
          {
            'prio'  => @prio,
            'from'  => @from,
            'table' => @table
          }
        end

      end
    end
  end
end