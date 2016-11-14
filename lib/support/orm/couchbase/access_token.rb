
module Doorkeeper
    class AccessToken < CouchbaseOrm::Base
        design_document :dk_at


        include OAuth::Helpers
        include Models::Expirable
        include Models::Revocable
        include Models::Accessible
        include Models::Scopes

        include ::Doorkeeper::Couchbase::Timestamps

        attr_writer :use_refresh_token

        belongs_to  :application, class_name: 'Doorkeeper::Application', inverse_of: :access_grants

        attribute   :resource_owner_id,
                    :token,
                    :refresh_token,
                    :previous_refresh_token,
                    :scopes,
                    :redirect_uri, type: String

        attribute   :expires_in,   type: Integer


        validates :resource_owner_id, :application, :expires_in, :redirect_uri, presence: true
        ensure_unique :refresh_token, presence: false


        index_view :resource_owner_id
        view :by_application_id_and_resource_owner_id, map: <<-EMAP
            function(doc) {
                if(doc.type === 'dk_at' && doc.application_id && doc.resource_owner_id && !doc.revoked_at) {
                    emit([doc.application_id, doc.resource_owner_id], null);
                }
            }
        EMAP


        class << self
            def refresh_token_revoked_on_use?
                true
            end

            # Returns an instance of the Doorkeeper::AccessToken with
            # specific token value.
            #
            # @param token [#to_s]
            #   token value (any object that responds to `#to_s`)
            #
            # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
            #   if there is no record with such token
            #
            alias_method :by_token, :find_by_id

            # Returns an instance of the Doorkeeper::AccessToken
            # with specific token value.
            #
            # @param refresh_token [#to_s]
            #   refresh token value (any object that responds to `#to_s`)
            #
            # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
            #   if there is no record with such refresh token
            #
            def by_refresh_token(refresh_token)
                tok = self.find_by_refresh_token(refresh_token)
                return tok if tok

                # legacy - required for existing systems
                id = AccessToken.bucket.get("refresh-#{refresh_token}", quiet: true)
                find_by_id(id) if id
            end

            # Revokes AccessToken records that have not been revoked and associated
            # with the specific Application and Resource Owner.
            #
            # @param application_id [Integer]
            #   ID of the Application
            # @param resource_owner [ActiveRecord::Base]
            #   instance of the Resource Owner model
            #
            def revoke_all_for(application_id, resource_owner)
                by_application_id_and_resource_owner_id(key: [application_id, resource_owner.id]).stream do |at|
                    at.revoke
                end
            end

            # Looking for not revoked Access Token record that belongs to specific
            # Application and Resource Owner.
            #
            # @param application_id [Integer]
            #   ID of the Application model instance
            # @param resource_owner_id [Integer]
            #   ID of the Resource Owner model instance
            #
            # @return [Doorkeeper::AccessToken, nil] matching AccessToken object or
            #   nil if nothing was found
            #
            def last_authorized_token_for(application_id, resource_owner_id)
                result = by_application_id_and_resource_owner_id(key: [application_id, resource_owner_id]).first
                result[:revoked_at] ? result : nil
            end

            # Looking for not expired Access Token with a matching set of scopes
            # that belongs to specific Application and Resource Owner.
            #
            # @param application [Doorkeeper::Application]
            #   Application instance
            # @param resource_owner_or_id [ActiveRecord::Base, Integer]
            #   Resource Owner model instance or it's ID
            # @param scopes [String, Doorkeeper::OAuth::Scopes]
            #   set of scopes
            #
            # @return [Doorkeeper::AccessToken, nil] Access Token instance or
            #   nil if matching record was not found
            #
            def matching_token_for(application, resource_owner_or_id, scopes)
                resource_owner_id = resource_owner_or_id.try(:id) || resource_owner_or_id
                token = last_authorized_token_for(application.try(:id), resource_owner_id)
                if token && scopes_match?(token.scopes, scopes, application.try(:scopes))
                    token
                end
            end

            # Checks whether the token scopes match the scopes from the parameters or
            # Application scopes (if present).
            #
            # @param token_scopes [#to_s]
            #   set of scopes (any object that responds to `#to_s`)
            # @param param_scopes [String]
            #   scopes from params
            # @param app_scopes [String]
            #   Application scopes
            #
            # @return [Boolean] true if all scopes and blank or matches
            #   and false in other cases
            #
            def scopes_match?(token_scopes, param_scopes, app_scopes)
                (!token_scopes.present? && !param_scopes.present?) ||
                    Doorkeeper::OAuth::Helpers::ScopeChecker.match?(
                        token_scopes.to_s,
                        param_scopes,
                        app_scopes
                    )
            end

            # Looking for not expired AccessToken record with a matching set of
            # scopes that belongs to specific Application and Resource Owner.
            # If it doesn't exists - then creates it.
            #
            # @param application [Doorkeeper::Application]
            #   Application instance
            # @param resource_owner_id [ActiveRecord::Base, Integer]
            #   Resource Owner model instance or it's ID
            # @param scopes [#to_s]
            #   set of scopes (any object that responds to `#to_s`)
            # @param expires_in [Integer]
            #   token lifetime in seconds
            # @param use_refresh_token [Boolean]
            #   whether to use the refresh token
            #
            # @return [Doorkeeper::AccessToken] existing record or a new one
            #
            def find_or_create_for(application, resource_owner_id, scopes, expires_in, use_refresh_token)
                if Doorkeeper.configuration.reuse_access_token
                    access_token = matching_token_for(application, resource_owner_id, scopes)
                    if access_token && !access_token.expired?
                        return access_token
                    end
                end

                create!(
                    application_id:    application.try(:id),
                    resource_owner_id: resource_owner_id,
                    scopes:            scopes.to_s,
                    expires_in:        expires_in,
                    use_refresh_token: use_refresh_token
                )
            end
        end

        # Access Token type: Bearer.
        # @see https://tools.ietf.org/html/rfc6750
        #   The OAuth 2.0 Authorization Framework: Bearer Token Usage
        #
        def token_type
            'bearer'
        end

        def use_refresh_token?
            @use_refresh_token ||= false
            !!@use_refresh_token
        end

        # JSON representation of the Access Token instance.
        #
        # @return [Hash] hash with token data
        def as_json(_options = {})
            {
                resource_owner_id:  resource_owner_id,
                scopes:             scopes,
                expires_in_seconds: expires_in_seconds,
                application:        { uid: application.try(:uid) },
                created_at:         created_at.to_i
            }
        end


        # Lets make sure these keys are not clogging up the database forever
        def save(**options)
            if use_refresh_token?
                options[:ttl] = self.created_at + 6.months
            else
                options[:ttl] = self.created_at + self.expires_in + 30
            end
            super(**options)
        end



        # Indicates whether the token instance have the same credential
        # as the other Access Token.
        #
        # @param access_token [Doorkeeper::AccessToken] other token
        #
        # @return [Boolean] true if credentials are same of false in other cases
        #
        def same_credential?(access_token)
            application_id == access_token.application_id &&
            resource_owner_id == access_token.resource_owner_id
        end


        # Indicates if token is acceptable for specific scopes.
        #
        # @param scopes [Array<String>] scopes
        #
        # @return [Boolean] true if record is accessible and includes scopes or
        #   false in other cases
        #
        def acceptable?(scopes)
            accessible? && includes_scope?(*scopes)
        end

        private


        before_validation :generate_token, on: :create
        before_validation :generate_refresh_token, on: :create, if: :use_refresh_token?


        # Generates refresh token with UniqueToken generator.
        #
        # @return [String] refresh token value
        #
        def generate_refresh_token
            write_attribute :refresh_token, UniqueToken.generate
        end

        def generate_token
            self.created_at ||= Time.now.utc

            generator = Doorkeeper.configuration.access_token_generator.constantize
            self.id = self.token = generator.generate(
                resource_owner_id: resource_owner_id,
                scopes: scopes,
                application: application,
                expires_in: expires_in,
                created_at: created_at
            )
        rescue NoMethodError
            raise Errors::UnableToGenerateToken, "#{generator} does not respond to `.generate`."
        rescue NameError
            raise Errors::TokenGeneratorNotFound, "#{generator} not found"
        end
    end
end
