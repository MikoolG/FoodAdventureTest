# frozen_string_literal: true

# config/initializers/sidekiq.rb
require 'sidekiq/scheduler'

Sidekiq.configure_server do |config|
  # Setting up the Redis connection
  config.redis = { url: ENV['REDIS_URL'] }

  # Scheduling configuration
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path('../sidekiq_schedule.yml', __dir__))
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end
