# encoding: utf-8
module Rack
  module Mongoid
    module Middleware

      # This middleware contains the behaviour needed to properly use the
      # identity map in Rack based applications. This middleware will properly
      # handle Rails or Rack streaming responses.
      class IdentityMap

        # Initialize the new middleware.
        #
        # @example Init the middleware.
        #   IdentityMap.new(app)
        #
        # @param [ Object ] app The application.
        #
        # @since 2.1.0
        def initialize(app)
          @app = app
        end

        # Make the request with the provided environment.
        #
        # @example Make the request.
        #   identity_map.call(env)
        #
        # @param [ Object ] env The environment.
        #
        # @return [ Array ] The status, headers, and response.
        #
        # @since 2.1.0
        def call(env)
          Rails.logger.info "Rack::Mongoid::Middleware::IdentityMap#call() Start"
          response = @app.call(env)
          response[2] = BodyProxy.new(response[2]) do
            ::Mongoid::IdentityMap.clear
            Rails.logger.info "Rack::Mongoid::Middleware::IdentityMap#call() Finished each() .  Cleared IdentityMap"
          end
          response
        rescue
          # If we get here then the body will probably not be
          # enumerated and we need to clear the identity map here
          ::Mongoid::IdentityMap.clear
          Rails.logger.info "Rack::Mongoid::Middleware::IdentityMap#call() Exception.  Cleared IdentityMap"
          raise
        end

        # Passenger 3 does not execute the block provided to a Rack::BodyProxy
        # so the identity map never gets cleared. Since there's no streaming
        # support in it anyways we do not need the proxy functionality.
        class Passenger

          # Initialize the new middleware.
          #
          # @example Init the middleware.
          #   IdentityMap.new(app)
          #
          # @param [ Object ] app The application.
          #
          # @since 3.0.11
          def initialize(app)
            @app = app
          end

          # Make the request with the provided environment.
          #
          # @example Make the request.
          #   identity_map.call(env)
          #
          # @param [ Object ] env The environment.
          #
          # @return [ Array ] The status, headers, and response.
          #
          # @since 3.0.11
          def call(env)
            ::Mongoid.unit_of_work { @app.call(env) }
          end
        end
      end
    end
  end
end
