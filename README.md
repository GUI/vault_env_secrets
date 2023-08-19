# VaultEnvSecrets

A small gem to load secrets from [Vault](https://www.vaultproject.io) into environment variables by way of a [consul-template](https://github.com/hashicorp/consul-template) YAML template. Automatic integration with Rails is supported.

## Requirements/Assumptions

- By default, a `consul-template` config file needs to be present in `config/vault.hcl` that defines a `template` that will render secrets in a YAML output file to `tmp/vault/secrets.yml`.
- You must be authenticate to Vault in some fashion outside of this library (eg, `vault login` is used before startup and `~/.vault-token` is present, or `VAULT_TOKEN` is set, etc).
- For Rails integration, secrets will only be read once on application startup (so to pick up changes in development, you must restart the Rails server).

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
bundle add vault_env_secrets
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install vault_env_secrets
```

## Example Usage

This gem mostly defers to to [`consul-template`](https://github.com/hashicorp/consul-template), with the assumption that there will be a YAML output file that can be read in. There are a variety of ways to use this, but as an example:

1. Authenticate against Vault:

    ```sh
    vault login
    ```

2. Define a `consul-template` [configuration file](https://github.com/hashicorp/consul-template/blob/main/docs/configuration.md#configuration-file) in the default `config/vault.hcl` location:

    ```hcl
    vault {
      address = "https://vault.example.com/"
      renew_token = true

      retry {
        enabled = false
      }
    }

    template {
      source = "./config/vault/secrets.yml.ctmpl"
      destination = "./tmp/vault/secrets.yml"
      error_on_missing_key = true
      perms = 0600
    }
    ```

3. Define the template that the `config/vault.hcl` config file references (which should be configured to output to `tmp/vault/secrets.yml` by default). In this example the secret key base and database credentials are fetched from a `secret/my-app/<rails_env>/web` item:

    ```ctmpl
    {{ $rails_env := (envOrDefault "RAILS_ENV" "development") }}

    {{ with secret (printf "secret/my-app/%s/web" $deploy_env) }}
      {{ scratch.MapSet "secrets" "SECRET_KEY_BASE" .Data.data.secret_key_base }}
      {{ scratch.MapSet "secrets" "SECRET_DB_HOST" .Data.data.db_host }}
      {{ scratch.MapSet "secrets" "SECRET_DB_NAME" .Data.data.db_name }}
      {{ scratch.MapSet "secrets" "SECRET_DB_USERNAME" .Data.data.db_username }}
      {{ scratch.MapSet "secrets" "SECRET_DB_PASSWORD" .Data.data.db_password }}
    {{ end }}

    {{ scratch.Get "secrets" | toYAML }}
    ```

4. With the gem installed, any variables defined in the output YAML from the `consul-template` template will be set as environment variables on Rails startup. The environment variable names will depend on the names in the YAML output. So in the above example, `ENV["SECRET_KEY_BASE"]`, `ENV["SECRET_DB_HOST"]`, `ENV["SECRET_DB_PASSWORD"]`, etc would all be available to the app.

## Configuration

You may adjust VaultEnvSecrets configuration by adding a `config/initializers/vault_env_secrets.rb` file with setting changes. Note that the initializer must exist at this path and filename to be properly loaded (this ensures that VaultEnvSecrets is available early on in the Rails load process, so other parts of Rails and other gems can integrate with it).

#### `VaultEnvSecrets.enabled`

Optionally disable loading VaultEnvSecrets (for example, if this gem only needs to be active in certain Rails environments).

```ruby
VaultEnvSecrets.enabled = false # Defaults to `true`
```

#### `VaultEnvSecrets.consul_template_config`

Set a custom path to the `consul-template` config file.

```ruby
VaultEnvSecrets.consul_template_config = "config/my_config.hcl" # Defaults to `config/vault.hcl`
```

#### `VaultEnvSecrets.consul_template_output`

Set a custom path to the YAML output file generated from the `consul-template` template.

```ruby
VaultEnvSecrets.consul_template_output = "tmp/my_secrets.yml" # Defaults to `tmp/vault/secrets.yml`
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GUI/vault_env_secrets.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
