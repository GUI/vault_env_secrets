# frozen_string_literal: true

require "pathname"
require "yaml"

require_relative "vault_env_secrets/errors"
require_relative "vault_env_secrets/version"

module VaultEnvSecrets
  @enabled = true
  @consul_template_config = "config/vault.hcl"
  @consul_template_output = "tmp/vault/secrets.yml"

  class << self
    attr_accessor :enabled
    attr_accessor :consul_template_config
    attr_accessor :consul_template_output

    def load(env: {})
      if enabled
        # Check that the expected consul-template config file exists.
        config_path = Pathname.new(consul_template_config)
        if defined?(::Rails) && config_path.relative?
          config_path = Rails.root.join(consul_template_config)
        end
        unless config_path.exist?
          raise Error.new("consul-template config path (#{config_path.to_s.inspect}) does not exist")
        end

        # Run consul-template to render any template files.
        system(env, "consul-template", "-config", config_path.to_s, "-once", exception: true)

        # Check that the expected output file exists.
        output_path = Pathname.new(consul_template_output)
        if defined?(::Rails) && output_path.relative?
          output_path = Rails.root.join(consul_template_output)
        end
        unless output_path.exist?
          raise Error.new("consul-template rendered output path (#{output_path.to_s.inspect}) does not exist")
        end

        # Read the output YAML file and set any of the variables as environment
        # variables.
        secrets = YAML.safe_load_file(output_path)
        if secrets
          # Make sure the YAML output is an expected hash.
          unless secrets.is_a?(Hash)
            raise Error.new("YAML in consul-template output file does not of expected Hash type (#{output_path.to_s.inspect})")
          end

          secrets.each do |key, value|
            # Reject nested values that can't be set as simple string values
            # for environment variable purposes.
            if value.is_a?(Array) || value.is_a?(Hash)
              raise Error.new("YAML in consul-template output file has nested data that cannot be set as environment variables (#{output_path.to_s.inspect}: #{key.inspect} type #{value.class.name})")
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
