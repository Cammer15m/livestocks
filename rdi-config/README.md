# RDI Configuration Guide

This directory contains configuration templates for Redis RDI (Redis Data Integration).

## Quick Setup

1. **Copy the template:**
   ```bash
   cp config.yaml.template config.yaml
   ```

2. **Get your Redis Cloud connection details:**
   - Sign up at [Redis Cloud](https://redis.com/try-free/)
   - Create a new database
   - Click "Connect" → "Redis CLI" to get connection string
   - Format: `redis://default:password@host:port`

3. **Update config.yaml with your Redis Cloud details:**
   ```yaml
   connections:
     target:
       host: redis-12345.c123.us-east-1-1.ec2.redns.redis-cloud.com
       port: 12345
       password: your_password_here
       username: default
       tls: true
   ```

## Configuration Files

- `config.yaml.template` - Main RDI configuration template
- `config.yaml` - Your customized configuration (create from template)

## Key Configuration Sections

### Target (Redis Cloud)
Configure your Redis Cloud connection details here.

### Source (PostgreSQL)
Pre-configured to connect to the PostgreSQL container with the music store data.

### Tables
Defines which PostgreSQL tables to replicate and how to structure the data in Redis:
- `Album` → `album:{AlbumId}`
- `Track` → `track:{TrackId}`
- `Genre` → `genre:{GenreId}`
- `MediaType` → `mediatype:{MediaTypeId}`
- `ctf_flags` → `flag:{lab_id}`

### Transforms
Optional data transformations applied during replication.

## Using RDI CLI

Once configured, you can use the RDI CLI container:

```bash
# Enter the RDI CLI container
docker exec -it rdi-ctf-cli bash

# Deploy the configuration
redis-di deploy --config /config/config.yaml

# Start the pipeline
redis-di start

# Check status
redis-di status

# View logs
redis-di logs

# Stop the pipeline
redis-di stop
```

## Troubleshooting

1. **Connection issues:** Verify Redis Cloud credentials and network connectivity
2. **TLS errors:** Ensure `tls: true` and check certificate settings
3. **Permission errors:** Verify Redis Cloud user has read/write permissions
4. **PostgreSQL connection:** Ensure the PostgreSQL container is running and accessible

## CTF Labs

The configuration is set up to support the CTF labs:
- Lab 01: Basic PostgreSQL to Redis replication
- Lab 02: Change Data Capture (CDC) streaming
- Lab 03: Advanced transformations and filtering
