module Rack
  module Mongoid
    module Middleware

      # Based on Rack::BodyProxy but overrides each() instead of close()
      # as close() is not reliably called
      class BodyProxy
        def initialize(body, &block)
          @body, @block, @finished = body, block, false
        end

        def respond_to?(*args)
          super or @body.respond_to?(*args)
        end

        def each(*args, &block)
          @body.each(*args, &block)
        ensure
          unless @finished
            @finished = true
            @block.call
          end
        end

        def method_missing(*args, &block)
          @body.__send__(*args, &block)
        end
      end
    end
  end
end
