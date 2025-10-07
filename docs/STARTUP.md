# Food Truck Adventure - Startup Guide

## Quick Start (Recommended)

For daily development, use the automated startup script:

```bash
./bin/start
```

This script automatically:
- ✅ Cleans up stale processes
- ✅ Builds Tailwind CSS
- ✅ Checks & starts PostgreSQL
- ✅ Checks & starts Redis
- ✅ Verifies database exists
- ✅ **Imports food trucks if database is empty** (484 trucks from SF Open Data)
- ✅ Starts Sidekiq worker (background jobs)
- ✅ Starts Rails/Puma server (web)
- ✅ All services run as daemons

**Time:** ~10-15 seconds (first run with import: ~60 seconds)

To stop everything:
```bash
./bin/stop
```

---

## What Gets Started

### 1. Web Server (Rails/Puma)
- **Port:** 3000
- **URL:** http://localhost:3000
- **Process:** Runs as daemon (background)
- **Logs:** `log/development.log`

### 2. Background Worker (Sidekiq)
- **Purpose:** Processes background jobs
  - Adventure notifications (scheduled SMS)
  - Food truck route organization
  - Daily SF data import (midnight)
- **Process:** Runs as daemon (background)
- **Logs:** `log/sidekiq.log`

### 3. Asset Pipeline (Tailwind CSS)
- **Built once:** During `./bin/start`
- **File:** `app/assets/builds/tailwind.css`
- **Rebuilds:** Automatically when files change (in dev mode)

### 4. Database (PostgreSQL)
- **Service:** System service (always running)
- **Databases:**
  - `FoodAdventure_development`
  - `FoodAdventure_test`

### 5. Cache Store (Redis)
- **Service:** System service (always running)
- **Used by:** Sidekiq job queue, Action Cable

---

## Data Import

### Food Trucks (San Francisco)

**Automatic:** `./bin/start` checks if database is empty and imports automatically

**Manual Import:**
```bash
bundle exec rails runner "SfImportWorker.new.perform"
```

**What it does:**
- Fetches CSV from SF Open Data API
- Imports ~484 food trucks with locations
- Auto-categorizes by food type
- Marks missing trucks as inactive

**Scheduled:** Runs daily at midnight via Sidekiq scheduler

**Source:** https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat

---

## Monitoring Running Services

### Check Status
```bash
# See all processes
ps aux | grep -E "puma|sidekiq" | grep -v grep

# Check web server
curl -I http://localhost:3000

# Check Sidekiq
ps aux | grep sidekiq | grep -v grep
```

### View Logs (Real-time)
```bash
# Rails web server
tail -f log/development.log

# Sidekiq background worker
tail -f log/sidekiq.log

# Both at once
tail -f log/*.log
```

### Background Tasks in Claude Terminal

When using Claude Code, services start as background tasks that show in the terminal:
- You'll see "running X background tasks" indicator
- Use `/bashes` command to see all running tasks
- Each service has a unique ID (e.g., `06cda3`)

---

## Alternative: Manual Startup

If you prefer more control or need to debug:

### Terminal 1: Web Server
```bash
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle exec rails server -p 3000
```

### Terminal 2: Sidekiq Worker
```bash
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle exec sidekiq -C config/sidekiq.yml
```

### Terminal 3: Tailwind Watch (Optional)
```bash
export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle exec rails tailwindcss:watch
```

**Note:** This approach requires 2-3 terminal windows and doesn't auto-import data.

---

## Troubleshooting

### Port 3000 Already in Use
```bash
# Stop all services
./bin/stop

# Or manually kill
kill $(lsof -ti:3000)
```

### Services Won't Start

**Check system services:**
```bash
sudo systemctl status postgresql
sudo systemctl status redis-server
```

**Start if needed:**
```bash
sudo systemctl start postgresql
sudo systemctl start redis-server
```

### No Food Trucks Showing

**Check count:**
```bash
bundle exec rails runner "puts FoodTruck.count"
```

**If 0, import manually:**
```bash
bundle exec rails runner "SfImportWorker.new.perform"
```

### Google Maps Not Loading

**Possible causes:**
1. **No data:** Ensure food trucks imported (see above)
2. **API key:** The hardcoded key might be restricted/invalid
3. **Browser console:** Check for JavaScript errors (F12 → Console)

**Check API key in:**
- `app/views/layouts/application.html.erb` (line 31)

### Tailwind CSS Not Loading

**Rebuild assets:**
```bash
bundle exec rails tailwindcss:build
```

**Check file exists:**
```bash
ls -lh app/assets/builds/tailwind.css
```

### Sidekiq Jobs Not Running

**Check Sidekiq is running:**
```bash
ps aux | grep sidekiq | grep -v grep
```

**Check Redis:**
```bash
redis-cli ping  # Should return "PONG"
```

**View Sidekiq UI (optional):**
Add to `config/routes.rb`:
```ruby
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```
Then visit: http://localhost:3000/sidekiq

---

## Complete Fresh Start

If things are broken, do a complete reset:

```bash
# 1. Stop everything
./bin/stop
pkill -f "puma|sidekiq"

# 2. Reset database
bundle exec rails db:reset

# 3. Rebuild assets
bundle exec rails tailwindcss:build

# 4. Start fresh
./bin/start
```

---

## First Time Setup Checklist

After cloning the repository:

- [ ] Install Ruby 3.2.3
- [ ] Install PostgreSQL
- [ ] Install Redis
- [ ] Run `bundle install`
- [ ] Run `npm install`
- [ ] Run `bundle exec rails db:create db:migrate`
- [ ] Run `./bin/start` (will auto-import food trucks)
- [ ] Visit http://localhost:3000
- [ ] Verify Google Maps shows 484 food truck markers

---

## Production Deployment Notes

**The `./bin/start` script is for DEVELOPMENT ONLY.**

For production:
- Use proper process managers (systemd, Docker, Heroku)
- Environment variables for configuration
- See `docs/DEPLOYMENT.md` for details

---

## Development Workflow

### Daily Routine
```bash
# Morning
./bin/start

# Work on code...
# Rails auto-reloads changes
# Tailwind rebuilds on file changes

# Check logs if needed
tail -f log/development.log

# End of day
./bin/stop
```

### After Pulling Changes
```bash
# Update dependencies
bundle install

# Run migrations
bundle exec rails db:migrate

# Restart
./bin/restart
```

### Running Tests
```bash
# Services don't need to be running for tests
./bin/stop

# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/adventure_spec.rb
```

---

## Environment Variables

The startup script sets these automatically:

```bash
PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"
```

To make permanent, add to `~/.bashrc`:
```bash
echo 'export PATH="$HOME/.local/share/gem/ruby/3.2.0/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Performance Tips

### Faster Startup

If startup is slow:
1. **Skip data import:** Comment out import check in `bin/start`
2. **Use daemon mode:** Already enabled (Rails `-d` flag)
3. **Reduce Sidekiq workers:** Edit `config/sidekiq.yml` (default: 5)

### Development Speed

**Preload Rails:**
```bash
# Use Spring (included) for faster commands
spring rspec spec/models/adventure_spec.rb
```

**Database queries:**
- View in logs with syntax highlighting
- Use `bundle exec rails dbconsole` for direct access

---

## Related Documentation

- **Architecture:** `docs/ARCHITECTURE.md`
- **API Integration:** `docs/API_INTEGRATION.md`
- **Deployment:** `docs/DEPLOYMENT.md`
- **Quick Start:** `docs/QUICK_START.md`
- **Database:** `docs/DATABASE_SCHEMA.md`
