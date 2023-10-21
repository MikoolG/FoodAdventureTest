# config/initializers/sidekiq.rb
require 'sidekiq/scheduler'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path('../sidekiq_schedule.yml', __dir__))
    Sidekiq::Scheduler.reload_schedule!
  end
end
