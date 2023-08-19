require "rails/railtie"

module VaultEnvSecrets
  class Railtie < ::Rails::Railtie
    # Load the secret keys as early as possible, so it can be used in other
    # parts of the Rails configuration, like database.yml files.
    config.before_configuration do
      # Load the optional initializer manually (since this before_configuration
      # phase is before when initializers are usually loaded), so that any
      # customizations can be read in.
      initializer = ::Rails.root.join("config", "initializers", "vault_env_secrets.rb")
      require initializer if File.exist?(initializer)

      VaultEnvSecrets.load
    end

    # Try to ensure our own "before_configuration" hook gets loaded before any
    # others that have already been loaded, so that these secrets can be used
    # as part of other gem's own before_configuration hooks (eg, in the
    # "config" gem's settings.yml files).
    load_hooks = ActiveSupport.instance_variable_get(:@load_hooks)
    if load_hooks && load_hooks[:before_configuration]
      load_hooks[:before_configuration] = load_hooks[:before_configuration].rotate(-1)
    end
  end
end
