# Quick Start Guide

## Professional Startup/Shutdown Process

This project includes custom scripts for managing all services in one command.

### Start the Application

```bash
./bin/start
```

This will:
- ✅ Build Tailwind CSS assets
- ✅ Check and start PostgreSQL
- ✅ Check and start Redis
- ✅ Check/create database if needed
- ✅ Start Rails web server (port 3000)
- ✅ Start Sidekiq background worker
- ✅ Run in background so you can continue using terminal

**Output:**
```
🚚 Starting Food Truck Adventure...

📦 Building Tailwind CSS...
🐘 Checking PostgreSQL...
🔴 Checking Redis...
🗄️  Checking database...

✅ Starting application services...
   Web server: http://localhost:3000
   Sidekiq: Background job processor

🎉 Food Truck Adventure is running!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 Web:     http://localhost:3000
  📋 Logs:    tail -f log/development.log
  🔄 Sidekiq: tail -f log/sidekiq.log
  🛑 Stop:    ./bin/stop
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Stop the Application

```bash
./bin/stop
```

Cleanly stops:
- Web server (Rails/Puma)
- Background worker (Sidekiq)
- All related processes

### Restart the Application

```bash
./bin/restart
```

Equivalent to `./bin/stop && ./bin/start`

---

## Alternative: Manual Control

If you prefer more control, you can run services individually:

### Terminal 1: Web Server + CSS

```bash
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bin/dev
```

### Terminal 2: Background Worker

```bash
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle exec sidekiq
```

---

## First Time Setup

Only needed once after cloning:

```bash
# Install dependencies
bundle install
npm install

# Setup database
bundle exec rails db:create db:migrate

# Import food truck data (optional)
bundle exec rails runner "SfImportWorker.new.perform"
```

---

## Common Tasks

### View Logs

```bash
# Rails application logs
tail -f log/development.log

# Sidekiq worker logs
tail -f log/sidekiq.log

# Both at once
tail -f log/*.log
```

### Run Tests

```bash
bundle exec rspec
```

### Rails Console

```bash
bundle exec rails console
```

### Import Food Truck Data

```bash
bundle exec rails runner "SfImportWorker.new.perform"
```

### Database Operations

```bash
# Reset database (WARNING: deletes all data)
bundle exec rails db:reset

# Run pending migrations
bundle exec rails db:migrate

# Rollback last migration
bundle exec rails db:rollback
```

---

## Troubleshooting

### Port 3000 Already in Use

```bash
# Stop all services
./bin/stop

# Or manually kill process on port 3000
kill $(lsof -ti:3000)
```

### PostgreSQL Not Running

```bash
sudo systemctl start postgresql
sudo systemctl status postgresql
```

### Redis Not Running

```bash
sudo systemctl start redis-server
redis-cli ping  # Should return "PONG"
```

### Assets Not Loading (Tailwind CSS)

```bash
# Rebuild assets
bundle exec rails tailwindcss:build

# Then restart
./bin/restart
```

### "Command not found: bundle"

```bash
# Add gem bin to PATH
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"

# Or permanently (already done in setup)
echo 'export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Service Status

Check if services are running:

```bash
# Check if web server is running
curl http://localhost:3000

# Check PostgreSQL
sudo systemctl status postgresql

# Check Redis
redis-cli ping

# Check what's running on port 3000
lsof -i :3000
```

---

## Development Workflow

### Typical Daily Workflow

```bash
# Morning: Start the app
./bin/start

# Work on features, tests pass automatically
# Browse to http://localhost:3000 to test

# View logs as needed
tail -f log/development.log

# End of day: Stop the app
./bin/stop
```

### After Pulling Changes

```bash
# Update dependencies
bundle install

# Run any new migrations
bundle exec rails db:migrate

# Restart to pick up changes
./bin/restart
```

### Before Committing

```bash
# Run tests
bundle exec rspec

# Check code style
bundle exec rubocop

# Auto-fix style issues
bundle exec rubocop -a
```

---

## Production Deployment

For Heroku deployment, see `docs/DEPLOYMENT.md`

For Docker deployment:
```bash
docker-compose up -d
```

---

## Architecture

- **Web Server**: Puma (Rails default)
- **Background Jobs**: Sidekiq + Redis
- **Database**: PostgreSQL
- **Asset Pipeline**: Sprockets + Tailwind CSS
- **Process Manager**: Foreman (development)

See `docs/ARCHITECTURE.md` for detailed architecture documentation.
