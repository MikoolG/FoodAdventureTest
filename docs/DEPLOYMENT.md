# Deployment Guide

## Current Deployment

**Platform**: Heroku
**URL**: https://food-truck-adventure-222aa5bc5600.herokuapp.com/

## Heroku Deployment Setup

### Prerequisites
- Heroku CLI installed
- Git repository initialized
- Heroku account with app created

### Initial Setup

1. **Create Heroku App**
   ```bash
   heroku create food-truck-adventure
   ```

2. **Add PostgreSQL**
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

3. **Add Redis (for Sidekiq)**
   ```bash
   heroku addons:create heroku-redis:mini
   ```

4. **Set Rails Master Key**
   ```bash
   heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
   ```

5. **Configure Buildpacks**
   ```bash
   heroku buildpacks:add heroku/nodejs
   heroku buildpacks:add heroku/ruby
   ```

### Environment Configuration

**Required Config Vars**:
```bash
heroku config:set RAILS_ENV=production
heroku config:set RACK_ENV=production
heroku config:set RAILS_SERVE_STATIC_FILES=true
heroku config:set RAILS_LOG_TO_STDOUT=enabled
```

**Redis URL** (auto-set by heroku-redis addon):
```bash
# Verify it's set
heroku config:get REDIS_URL
```

### Procfile Configuration

The repository includes `Procfile` for production:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

**Enable Worker Dyno**:
```bash
heroku ps:scale worker=1
```

### Database Setup

```bash
# Run migrations
heroku run rails db:migrate

# Seed database (if needed)
heroku run rails db:seed

# Import food truck data
heroku run rails runner "SfImportWorker.new.perform"
```

### Deployment Process

```bash
# Deploy latest changes
git push heroku main

# View logs
heroku logs --tail

# Restart dynos if needed
heroku restart
```

### Monitoring

**Application Logs**:
```bash
heroku logs --tail --source app
```

**Sidekiq Logs**:
```bash
heroku logs --tail --ps worker
```

**Database**:
```bash
heroku pg:info
heroku pg:psql  # Connect to database
```

**Redis**:
```bash
heroku redis:info
heroku redis:cli
```

### Scheduled Jobs

Sidekiq-scheduler runs within the worker dyno. Daily import job configured in `config/sidekiq_schedule.yml`:

```yaml
sf_import_worker:
  cron: "0 0 * * *"  # Midnight UTC daily
  class: SfImportWorker
```

**Note**: Heroku dynos use UTC timezone. Adjust cron if specific timezone needed.

### Scaling

**Web Dynos**:
```bash
heroku ps:scale web=2  # Scale to 2 dynos
```

**Worker Dynos**:
```bash
heroku ps:scale worker=2  # Scale to 2 workers
```

**Database**:
```bash
# Upgrade to larger plan
heroku addons:upgrade heroku-postgresql:standard-0
```

---

## Alternative Deployment: Docker

### Dockerfile (Example)

```dockerfile
FROM ruby:3.2.0

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Install npm packages
COPY package.json ./
RUN npm install

# Copy application
COPY . .

# Precompile assets
RUN RAILS_ENV=production bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  web:
    build: .
    command: bundle exec puma -C config/puma.rb
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/food_development
      REDIS_URL: redis://redis:6379/0

  worker:
    build: .
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/food_development
      REDIS_URL: redis://redis:6379/0

volumes:
  postgres_data:
```

**Usage**:
```bash
docker-compose up -d
docker-compose run web rails db:create db:migrate
docker-compose run web rails runner "SfImportWorker.new.perform"
```

---

## Production Checklist

### Pre-Deployment
- [ ] All tests passing (`bundle exec rspec`)
- [ ] Rubocop violations resolved (`bundle exec rubocop`)
- [ ] Database migrations tested locally
- [ ] Credentials encrypted and master key secured
- [ ] Twilio webhook URL updated to production domain
- [ ] Assets precompile successfully
- [ ] Environment variables configured

### Post-Deployment
- [ ] Migrations run successfully
- [ ] Initial data import completed
- [ ] Sidekiq worker dyno running
- [ ] Test SMS flow end-to-end
- [ ] Error tracking configured (Sentry, Rollbar, etc.)
- [ ] Monitoring dashboards set up
- [ ] Backup strategy verified

### Security
- [ ] SSL/TLS enabled (automatic on Heroku)
- [ ] Twilio webhook signature validation active
- [ ] Database credentials rotated
- [ ] API keys in encrypted credentials, not env vars
- [ ] CORS configured if API endpoints added
- [ ] Rate limiting on webhook endpoint (if high traffic)

### Performance
- [ ] Database indexes verified
- [ ] N+1 queries eliminated (use Bullet gem in dev)
- [ ] Assets served via CDN (consider CloudFront)
- [ ] Redis connection pool sized appropriately
- [ ] Puma worker count tuned for dyno size

---

## Rollback Procedures

### Code Rollback
```bash
# Heroku keeps release history
heroku releases
heroku rollback v123  # Roll back to specific version
```

### Database Rollback
```bash
# Run down migration
heroku run rails db:migrate:down VERSION=20231021224249

# Or restore from backup
heroku pg:backups:restore DATABASE_URL
```

### Sidekiq Job Management
```bash
# Clear all jobs (if bad job deployed)
heroku run rails console
# In console:
Sidekiq::Queue.new.clear
Sidekiq::ScheduledSet.new.clear
```

---

## Monitoring & Alerting

### Recommended Tools

**Error Tracking**:
- Sentry (https://sentry.io)
- Rollbar (https://rollbar.com)

**Performance Monitoring**:
- New Relic (https://newrelic.com)
- Scout APM (https://scoutapm.com)

**Uptime Monitoring**:
- Pingdom
- UptimeRobot

### Key Metrics to Monitor

1. **Application**:
   - Request rate and response times
   - Error rate (4xx, 5xx)
   - Background job queue depth
   - Failed job count

2. **Database**:
   - Connection pool usage
   - Slow query count
   - Disk usage

3. **Sidekiq**:
   - Jobs processed per minute
   - Job failure rate
   - Queue latency
   - Worker utilization

4. **Twilio**:
   - SMS delivery rate
   - Failed messages
   - Webhook latency

### Custom Monitoring

**Sidekiq Web UI** (add to routes for admin):
```ruby
# config/routes.rb
require 'sidekiq/web'

Rails.application.routes.draw do
  # Protect with authentication in production
  mount Sidekiq::Web => '/sidekiq'
end
```

**Health Check Endpoint**:
```ruby
# config/routes.rb
get '/health', to: 'health#show'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    render json: {
      status: 'ok',
      database: database_alive?,
      redis: redis_alive?
    }
  end

  private

  def database_alive?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue
    false
  end

  def redis_alive?
    Sidekiq.redis(&:ping)
    true
  rescue
    false
  end
end
```

---

## Disaster Recovery

### Backup Strategy

**Database Backups** (Heroku Postgres):
```bash
# Manual backup
heroku pg:backups:capture

# Schedule automatic backups
heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Los_Angeles'

# Download backup
heroku pg:backups:download
```

**Restore Process**:
```bash
# List available backups
heroku pg:backups

# Restore from backup
heroku pg:backups:restore b101 DATABASE_URL
```

### Data Loss Scenarios

**Food Truck Data Loss**:
- Re-run import: `heroku run rails runner "SfImportWorker.new.perform"`
- CSV source is persistent (SF Open Data)

**Adventure Data Loss**:
- No external backup (user-generated data)
- Critical to have regular database backups
- Consider archiving completed adventures to separate table/storage

**Credentials Loss**:
- Master key stored securely offline
- Twilio credentials recoverable from Twilio console
- Document credential rotation procedure
