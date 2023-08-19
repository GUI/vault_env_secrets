# frozen_string_literal: true

require_relative "lib/vault_env_secrets/version"

Gem::Specification.new do |spec|
  spec.name = "vault_env_secrets"
  spec.version = VaultEnvSecrets::VERSION
  spec.authors = ["Nick Muerdter"]
  spec.email = ["12112+GUI@users.noreply.github.com"]

  spec.summary = "Load secrets from Vault into environment variables (via consul-template config and with Rails integration)"
  spec.homepage = "https://github.com/GUI/vault_env_secrets"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/GUI/vault_env_secrets/tree/v#{VaultEnvSecrets::VERSION}"
  spec.metadata["changelog_uri"] = "https://github.com/GUI/vault_env_secrets/blob/v#{VaultEnvSecrets::VERSION}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
