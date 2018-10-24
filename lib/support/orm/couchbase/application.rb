
# Load these before the has_many
require File.expand_path("../access_grant", __FILE__)
require File.expand_path("../access_token", __FILE__)


module Doorkeeper
    class Application < CouchbaseOrm::Base
        design_document :dk_app


        include OAuth::Helpers
        include Models::Scopes


        attribute :name,
                  :uid,
                  :secret,
                  :scopes,
                  :redirect_uri, type: String

        attribute :skip_authorization, type: Boolean, default: false
        attribute :confidential, type: Boolean, default: false


        belongs_to :owner, polymorphic: true

        validates :owner, presence: true, if: :validate_owner?
        def validate_owner?
            Doorkeeper.configuration.confirm_application_owner?
        end


        has_many :access_grants, dependent: :destroy, class_name: 'Doorkeeper::AccessGrant'
        has_many :access_tokens, dependent: :destroy, class_name: 'Doorkeeper::AccessToken'


        class << self
            alias_method :by_uid, :find_by_id

            def by_uid_and_secret(uid, secret)
                app = find_by_id(uid)
                if app
                    return app.secret == secret ? app : nil
                end
                nil
            end

            def authorized_for(resource_owner)
                AccessToken.find_by_resource_owner_id(resource_owner.id).collect(&:application)
            end
        end


        private


        validates :name, :secret, :uid, presence: true
        validates :redirect_uri, redirect_uri: true
        validates :confidential, inclusion: { in: [true, false] }

        before_validation :generate_uid, :generate_secret, on: :create

        def has_scopes?
            true
        end

        def generate_uid
            if uid.blank?
                self.id = self.uid = UniqueToken.generate
            end
        end

        def generate_secret
            if secret.blank?
                self.secret = UniqueToken.generate
            end
        end
    end
end
