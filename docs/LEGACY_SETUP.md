# Legacy Local Installation (Advanced Users Only)

⚠️ **Warning**: This approach modifies your system and installs packages globally. Use the Docker approach instead unless you specifically need local installation.

## Why Docker is Better

- ✅ **No system pollution** - Everything isolated in containers
- ✅ **Easy cleanup** - Just remove containers
- ✅ **Consistent environment** - Works the same everywhere
- ✅ **No sudo required** - No system package installation
- ✅ **Safe** - Won't affect your system's PostgreSQL, Python, etc.

## Local Installation (Not Recommended)

If you absolutely must install locally, you'll need to manually:

### 1. Install Dependencies
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib python3 python3-pip git

# macOS
brew install postgresql python3 git

# RHEL/CentOS
sudo yum install postgresql postgresql-server python3 python3-pip git
```

### 2. Set Up PostgreSQL
```bash
# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql -c "CREATE USER rdi_user WITH PASSWORD 'rdi_password';"
sudo -u postgres psql -c "CREATE DATABASE rdi_db OWNER rdi_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rdi_db TO rdi_user;"

# Load sample data
PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost < seed/music_database.sql
```

### 3. Install Python Dependencies
```bash
pip3 install -r requirements.txt
pip3 install -r scripts/requirements.txt
pip3 install -r scripts/requirements_rdi.txt
```

### 4. Configure Environment
```bash
cp .env.example .env
# Edit .env with your Redis connection details
```

### 5. Start Services
```bash
# Start RDI connector
python3 scripts/rdi_connector.py

# In another terminal, start web interface
python3 scripts/rdi_web.py

# Access at http://localhost:8080
```

## Manual Cleanup

If you used local installation, you'll need to manually clean up:

### Remove PostgreSQL Data
```bash
sudo -u postgres psql -c "DROP DATABASE IF EXISTS rdi_db;"
sudo -u postgres psql -c "DROP USER IF EXISTS rdi_user;"
```

### Remove Python Packages (Optional)
```bash
pip3 uninstall redis psycopg2-binary flask pandas sqlalchemy python-dotenv requests
```

### Remove PostgreSQL (Optional - Be Careful!)
```bash
# Ubuntu/Debian
sudo apt-get remove --purge postgresql postgresql-*
sudo apt-get autoremove

# macOS
brew uninstall postgresql

# RHEL/CentOS
sudo yum remove postgresql postgresql-*
```

## Why We Don't Recommend This

1. **System Pollution**: Installs packages globally that may conflict with other projects
2. **Complex Cleanup**: Requires manual removal of databases, users, and packages
3. **Platform Differences**: Different commands for different operating systems
4. **Permission Issues**: Requires sudo access for system packages
5. **Dependency Conflicts**: May break other Python projects
6. **Hard to Reproduce**: Different results on different systems

## Use Docker Instead!

The Docker approach solves all these problems:

```bash
# Simple, clean, safe
git clone https://github.com/Cammer15m/Redis_RDI_CTF
cd Redis_RDI_CTF
docker-compose up --build
```

No system changes, no cleanup needed, works everywhere the same way!
