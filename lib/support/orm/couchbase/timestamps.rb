require 'date'

module Doorkeeper
    module Couchbase
        module Timestamps
            extend ActiveSupport::Concern


            included do
                attribute :revoked_at, type: Integer
                attribute :created_at, type: Integer, :default => lambda { Time.now.to_i + 1 }
            end


            def revoked_at
                revoked = self[:revoked_at]
                Time.at(revoked) unless revoked.nil?
            end

            def revoked_at=(time)
                if time
                    number = time.is_a?(Numeric) ? time.to_i : time.to_time.to_i
                    self[:revoked_at] = number
                else
                    self[:revoked_at] = nil
                end
            end

            def created_at
                Time.at(self[:created_at])
            end
        end
    end
end
