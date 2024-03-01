# VaultEnvSecrets

A small gem to load secrets from [Vault](https://www.vaultproject.io) into environment variables by way of a [gomplate](https://gomplate.ca) JSON template. Automatic integration with Rails is supported.

## Requirements/Assumptions

- By default, a `gomplate` template needs to be present in `config/vault_secrets.json.tmpl` that defines a template that will render secrets to JSON output.
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

This gem mostly defers to to [`gomplate`](https://gomplate.ca), with the assumption that there will be a JSON output file that can be read in. There are a variety of ways to use this, but as an example:

1. Authenticate against Vault:

    ```sh
    vault login
    ```

2. Define a `gomplate` [configuration file](https://docs.gomplate.ca/config/) in `.gomplate.yaml` to declare your Vault datasource:

    ```hcl
    datasources:
      vault:
        url: "vault://vault.example.com/secret/data"
    ```

3. Define the template in the default `config/vault_secrets.json.tmpl` location. In this example the secret key base and database credentials are fetched from a `secret/my-app/<rails_env>/web` item:

    ```ctmpl
    {{ $rails_env := (env.Getenv "RAILS_ENV" "development") }}
    {{ $secrets := coll.Dict }}

    {{ with (datasource "vault" (printf "my-app/%s/web" $rails_env)).data }}
      {{ $secrets = coll.Merge $secrets (coll.Dict
        "SECRET_KEY_BASE" .secret_key_base
        "SECRET_DB_HOST" .db_host
        "SECRET_DB_NAME" .db_name
        "SECRET_DB_USERNAME" .db_username
        "SECRET_DB_PASSWORD" .db_password
      )}}
    {{ end }}

    {{ $secrets | data.ToJSON }}
    ```

4. With the gem installed, any variables defined in the output JSON from the `gomplate` template will be set as environment variables on Rails startup. The environment variable names will depend on the names in the JSON output. So in the above example, `ENV["SECRET_KEY_BASE"]`, `ENV["SECRET_DB_HOST"]`, `ENV["SECRET_DB_PASSWORD"]`, etc would all be available to the app.

## Configuration

You may adjust VaultEnvSecrets configuration by adding a `config/initializers/vault_env_secrets.rb` file with setting changes. Note that the initializer must exist at this path and filename to be properly loaded (this ensures that VaultEnvSecrets is available early on in the Rails load process, so other parts of Rails and other gems can integrate with it).

#### `VaultEnvSecrets.enabled`

Optionally disable loading VaultEnvSecrets (for example, if this gem only needs to be active in certain Rails environments).

```ruby
VaultEnvSecrets.enabled = false # Defaults to `true`
```

#### `VaultEnvSecrets.template_path`

Set a custom path to the `gomplate` JSON template file.

```ruby
VaultEnvSecrets.template_path = "config/my_secrets.json.tmpl" # Defaults to `config/vault_secrets.json.tmpl`
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GUI/vault_env_secrets.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
