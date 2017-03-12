
module Doorkeeper
    class AccessGrant < CouchbaseOrm::Base
        design_document :dk_ag


        include OAuth::Helpers
        include Models::Expirable
        include Models::Revocable
        include Models::Accessible
        include Models::Scopes

        include ::Doorkeeper::Couchbase::Timestamps


        belongs_to  :application, class_name: 'Doorkeeper::Application', inverse_of: :access_grants

        attribute   :resource_owner_id,
                    :token,
                    :scopes,
                    :redirect_uri, type: String

        attribute   :expires_in,   type: Integer
        

        class << self
            alias_method :by_token, :find_by_id
        end


        validates :resource_owner_id, :application, :token, :expires_in, :redirect_uri, presence: true


        before_validation :generate_token, on: :create

        
        # Lets make sure these keys are not clogging up the database forever
        def save(**options)
            options[:ttl] = self.created_at + self.expires_in + 30
            super(**options)
        end

        def transaction; yield; end
        def lock!; end


        private


        # Generates token value with UniqueToken class.
        #
        # @return [String] token value
        #
        def generate_token
            if self.token.blank?
                self.id = self.token = UniqueToken.generate
            end
        end
    end
end
