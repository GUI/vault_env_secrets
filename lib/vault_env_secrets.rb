# frozen_string_literal: true

require "json"
require "open3"
require "pathname"

require_relative "vault_env_secrets/errors"
require_relative "vault_env_secrets/version"

module VaultEnvSecrets
  @enabled = true
  @template_path = "config/vault_secrets.json.tmpl"

  class << self
    attr_accessor :enabled
    attr_accessor :template_path

    def load(env: {})
      if enabled
        # Check that the expected template file exists.
        path = Pathname.new(template_path)
        if defined?(::Rails) && path.relative?
          path = Rails.root.join(template_path)
        end
        unless path.exist?
          raise Error.new("vault template path (#{path.to_s.inspect}) does not exist")
        end

        # Run gomplate to render any template files.
        output, status = Open3.capture2(env, "gomplate", "--file", path.to_s)
        unless status.success?
          raise Error.new("vault template gomplate render failed: #{status.to_s}")
        end

        # Read the output JSON and set any of the variables as environment
        # variables.
        secrets = JSON.parse(output)
        if secrets
          # Make sure the JSON output is an expected hash.
          unless secrets.is_a?(Hash)
            raise Error.new("JSON in vault template output does not of expected Hash type (#{path.to_s.inspect})")
          end

          secrets.each do |key, value|
            # Reject nested values that can't be set as simple string values
            # for environment variable purposes.
            if value.is_a?(Array) || value.is_a?(Hash)
              raise Error.new("JSON in vault template output has nested data that cannot be set as environment variables (#{path.to_s.inspect}: #{key.inspect} type #{value.class.name})")
            end

            ENV[key] = value.to_s
          end
        end
      end
    end
  end
end

if defined?(::Rails)
  require_relative "vault_env_secrets/railtie"
end
