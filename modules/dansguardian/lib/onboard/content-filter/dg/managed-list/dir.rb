# A directory of DansGuardian lists

class OnBoard
  module ContentFilter
    class DG
      module ManagedList
        class Dir
          def initialize(h)
            @relative_path = h[:relative_path]
          end
        end
      end
    end
  end
end
