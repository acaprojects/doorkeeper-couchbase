module Doorkeeper
    module Orm
        module Couchbase
            def self.initialize_models!
                require 'support/orm/couchbase/timestamps'
                require 'support/orm/couchbase/access_grant'
                require 'support/orm/couchbase/access_token'
                require 'support/orm/couchbase/application'
            end

            def self.initialize_application_owner!
                #require 'doorkeeper/models/concerns/ownership'
                #Doorkeeper::Application.send :include, Doorkeeper::Models::Ownership
            end

            def self.check_requirements!(_config); end
        end
    end
end
