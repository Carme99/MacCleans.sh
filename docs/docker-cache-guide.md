# Docker Cache Management Best Practices

[![Docker](https://img.shields.io/badge/Docker-Container%20Guide-blue.svg)]()
[![DevOps](https://img.shields.io/badge/DevOps-Best%20Practices-green.svg)]()

Master Docker cache management to reclaim disk space without breaking your containerized workflows.

## Understanding Docker's Disk Usage

Docker can consume massive amounts of disk space through:
- Container images
- Build cache layers
- Stopped containers
- Unused volumes
- Networks

**Typical size**: 1GB - 20GB+ (can easily reach 50-100GB if unchecked!)

## Docker Storage Breakdown

### 1. Images

**What they are**: Templates for containers (like a VM snapshot)

**Where they live**: `/var/lib/docker/overlay2/`

**Size**: 100MB - 5GB each

**Example sizes**:
- `node:20`: ~950MB
- `python:3.11`: ~900MB
- `postgres:15`: ~400MB
- `nginx:latest`: ~180MB

**How they accumulate**:
```bash
# Pulling different versions
docker pull node:18
docker pull node:19
docker pull node:20

# All three images now stored (2.8GB total!)
```

### 2. Containers

**What they are**: Running or stopped instances of images

**Size**: Varies (container layer + filesystem changes)

**Problem**: Stopped containers stay on disk

```bash
# Create container
docker run --name myapp node:20 npm start

# Stop it
docker stop myapp

# Container still on disk even though stopped!
```

### 3. Volumes

**What they are**: Persistent data storage for containers

**Size**: Highly variable (databases, logs, uploads)

**Example**:
- Postgres volume: 5GB - 50GB+
- MongoDB volume: 10GB - 100GB+
- Log volumes: 1GB - 20GB

**Caution**: ⚠️ Volumes contain actual data (not just caches)!

### 4. Build Cache

**What it is**: Cached layers from `docker build`

**Size**: 500MB - 10GB+

**How it works**:
```dockerfile
FROM node:20
RUN apt-get update && apt-get install -y git  # Layer 1 (cached)
COPY package.json .                            # Layer 2 (cached)
RUN npm install                                 # Layer 3 (cached)
COPY . .                                        # Layer 4 (changes often)
```

Each `RUN`, `COPY`, `ADD` creates a cached layer. Over time, old layers accumulate.

### 5. Networks

**What they are**: Virtual networks for container communication

**Size**: Negligible (~1MB metadata each)

**Problem**: Unused networks accumulate

## Checking Docker Disk Usage

### See Everything

```bash
docker system df
```

**Output example**:
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          15        5         8.5GB     6.2GB (73%)
Containers      20        3         1.2GB     800MB (67%)
Local Volumes   10        4         15GB      10GB (67%)
Build Cache     50        0         3.5GB     3.5GB (100%)
```

**What this means**:
- 15 images, only 5 in use → 6.2GB can be freed
- 20 containers, only 3 running → 800MB can be freed
- 10 volumes, only 4 in use → 10GB can be freed
- All build cache unused → 3.5GB can be freed

### Detailed View

```bash
# Verbose output
docker system df -v
```

Shows individual images, containers, volumes with sizes.

### Images Only

```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Containers Only

```bash
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Size}}"
```

## Docker Cleanup Strategies

### Strategy 1: Remove Stopped Containers

**What it does**: Deletes containers that aren't running

```bash
docker container prune
```

**Safe?** ✅ Yes, if you don't need to restart them

**Caution**: Any data INSIDE the container (not in volumes) is lost

**When to use**: Regular cleanup (containers should be ephemeral anyway)

### Strategy 2: Remove Unused Images

**What it does**: Deletes images not used by any container

```bash
docker image prune -a
```

**Safe?** ⚠️ Mostly - you'll need to re-pull images

**Caution**: Next `docker run` will download images again (slower)

**When to use**: Aggressive cleanup, won't need images soon

### Strategy 3: Remove Build Cache

**What it does**: Clears all build cache layers

```bash
docker builder prune -a
```

**Safe?** ✅ Yes for caches

**Caution**: Next `docker build` will be slower (no layer cache)

**When to use**: You're done building for a while

### Strategy 4: Remove Unused Volumes

**What it does**: Deletes volumes not attached to containers

```bash
docker volume prune
```

**Safe?** ⚠️ **DANGEROUS** - volumes contain data!

**Caution**: **Permanent data loss** if you delete the wrong volume

**When to use**: Only when certain volumes are truly unused

**Best practice**: List volumes first
```bash
docker volume ls
# Identify unused ones
docker volume rm specific-volume-name
```

### Strategy 5: Nuclear Option (Clean Everything)

**What it does**: Removes EVERYTHING unused

```bash
docker system prune -a --volumes
```

**Safe?** ⚠️ **USE WITH EXTREME CAUTION**

**What it deletes**:
- All stopped containers
- All unused images
- All unused networks
- All build cache
- All unused volumes (**INCLUDING DATA!**)

**When to use**:
- Fresh start needed
- Disk emergency
- Development machine (not production!)
- You have backups of volume data

**MacCleans equivalent**:
```bash
sudo ./clean-mac-space.sh --profile aggressive
# Includes Docker cleanup (safe version - no volumes by default)
```

## Safe Docker Cleanup (MacCleans Approach)

MacCleans uses this command:

```bash
docker system prune -af --volumes
```

**Flags explained**:
- `-a`: Remove all unused images (not just dangling)
- `-f`: Force (no confirmation prompt)
- `--volumes`: Remove unused volumes

**Why it's safer**: MacCleans only runs if Docker command exists + user didn't skip

**How to skip it**:
```bash
sudo ./clean-mac-space.sh --skip-docker
```

## When to Clean Docker Caches

### ✅ Good Times to Clean

**1. Disk space critical (>90% full)**
```bash
docker system prune -a
```
Reclaim 5-20GB quickly

**2. After finishing a project**
```bash
# Done with project, remove its images
docker rmi $(docker images -q myproject*)
```

**3. Switching projects**
```bash
# Clean slate for new project
docker system prune -a
```

**4. Build issues (corrupted cache)**
```bash
docker builder prune -a
```
Fresh build often fixes weird issues

**5. Regular maintenance (monthly)**
```bash
# Automated via MacCleans
sudo ./clean-mac-space.sh --threshold 80
```

**6. Before important builds**
```bash
# Clean cache to ensure deterministic build
docker builder prune -a
docker build --no-cache -t myapp .
```

### ❌ Bad Times to Clean

**1. During active development**
- You benefit from build cache
- Rebuild will be slow (5-30 minutes)

**2. Right before deployment**
- Need images to push to registry
- Don't want surprises

**3. When containers are running**
```bash
# Check first
docker ps

# If containers running, don't prune volumes!
```

**4. Production servers** (mostly)
- Production should pull from registry
- Prune carefully (keep running images)

**5. If you don't understand volumes**
- Learn first, clean later
- Volumes contain data!

## Docker Best Practices to Minimize Waste

### 1. Multi-Stage Builds

Reduces final image size:

```dockerfile
# Bad (large image)
FROM node:20
COPY . .
RUN npm install
RUN npm run build
CMD ["npm", "start"]
# Final image: 1.2GB

# Good (smaller image)
FROM node:20 AS builder
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build

FROM node:20-slim
COPY --from=builder /app/dist /app
CMD ["node", "app/server.js"]
# Final image: 250MB
```

**Benefit**: 70-80% smaller images

### 2. Use .dockerignore

Prevent unnecessary files in build context:

```
# .dockerignore
node_modules
.git
.env
*.log
.DS_Store
coverage
```

**Benefit**: Faster builds, smaller images

### 3. Minimize Layers

Combine commands:

```dockerfile
# Bad (many layers)
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean
# 4 layers

# Good (one layer)
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# 1 layer
```

**Benefit**: Smaller cache, faster builds

### 4. Tag Images Properly

Don't let `<none>` images accumulate:

```bash
# Bad
docker build .
# Creates untagged image

# Good
docker build -t myapp:1.0 .
docker build -t myapp:latest .
```

**Benefit**: Easy cleanup of old versions

### 5. Clean Up in CI/CD

Add to your pipeline:

```yaml
# .github/workflows/docker-build.yml
- name: Cleanup
  run: docker system prune -f
```

**Benefit**: Prevents disk full on build servers

### 6. Use Volume Mounts for Dev Data

Don't put dev data in volumes for disposable containers:

```bash
# Bad (data in volume - persists after cleanup)
docker run -v mydata:/data postgres

# Good for dev (bind mount - outside Docker)
docker run -v $(pwd)/data:/data postgres
```

**Benefit**: Data stays on host, easier to manage

## Recovering from Docker Disk Issues

### Symptom: "No space left on device"

**Quick fix**:
```bash
# Free up space immediately
docker system prune -a -f

# Check space
df -h
```

### Symptom: Builds failing with space errors

**Fix**:
```bash
# Clear build cache
docker builder prune -a -f

# Rebuild
docker build --no-cache -t myapp .
```

### Symptom: Can't pull images

**Fix**:
```bash
# Remove old images
docker image prune -a -f

# Try pull again
docker pull node:20
```

### Symptom: Docker daemon won't start

**Fix**:
```bash
# Check disk usage
docker system df

# If needed, manually remove images
rm -rf ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw

# Restart Docker Desktop
```

## Monitoring Docker Disk Usage

### Manual Check

```bash
# Quick overview
docker system df

# Detailed
docker system df -v | head -20
```

### Automated Monitoring

Create a script:

```bash
#!/bin/bash
# ~/Scripts/docker-monitor.sh

THRESHOLD_GB=15

USAGE=$(docker system df | grep 'Local Volumes' | awk '{print $4}' | sed 's/GB//')

if (( $(echo "$USAGE > $THRESHOLD_GB" | bc -l) )); then
    echo "Docker volumes using ${USAGE}GB (threshold: ${THRESHOLD_GB}GB)"
    echo "Consider running: docker system prune -a"
fi
```

Schedule with cron:
```bash
0 9 * * * ~/Scripts/docker-monitor.sh
```

### MacCleans Integration

```bash
# Clean Docker automatically when disk >80%
sudo ./clean-mac-space.sh --threshold 80

# Docker cleanup included by default
```

## Docker Cleanup Cheat Sheet

| Task | Command | Safe? | Frees |
|------|---------|-------|-------|
| Remove stopped containers | `docker container prune` | ✅ Yes | 100MB-2GB |
| Remove unused images | `docker image prune -a` | ⚠️ Rebuild needed | 1-10GB |
| Remove build cache | `docker builder prune -a` | ✅ Yes | 500MB-5GB |
| Remove unused volumes | `docker volume prune` | ⚠️ DATA LOSS! | 1-50GB |
| Remove everything | `docker system prune -a --volumes` | ⚠️ DANGEROUS | 5-50GB+ |
| MacCleans cleanup | `sudo ./clean-mac-space.sh` | ✅ Safe | 5-20GB |

## Common Mistakes to Avoid

### ❌ Mistake 1: Deleting Volumes with Data

```bash
# WRONG - loses database data
docker system prune -a --volumes -f
```

**Fix**: Backup volumes first or exclude from prune

### ❌ Mistake 2: Not Using .dockerignore

```bash
# Copies entire node_modules (500MB) into build
# Slows build, wastes cache
```

**Fix**: Add `node_modules` to `.dockerignore`

### ❌ Mistake 3: Pulling `latest` Repeatedly

```bash
docker pull node:latest
# Creates duplicate images with same tag
```

**Fix**: Use specific versions (`node:20.5.1`)

### ❌ Mistake 4: Not Cleaning CI Runners

```bash
# GitHub Actions runner fills up over time
```

**Fix**: Add `docker system prune -f` to workflow

### ❌ Mistake 5: Treating Containers as Pets, Not Cattle

```bash
# Keeping stopped containers "just in case"
docker ps -a  # Shows 50 stopped containers
```

**Fix**: Delete stopped containers. Recreate from images.

## FAQ

**Q: Will cleaning Docker caches break my running containers?**
A: No. `docker system prune` only removes stopped containers and unused resources.

**Q: How often should I clean Docker?**
A: Monthly for regular users, weekly for heavy Docker users, or use MacCleans with threshold.

**Q: Can I recover deleted volumes?**
A: No! Volumes are **permanent data**. Back them up before deleting.

**Q: What's the difference between `docker system prune` and `docker system prune -a`?**
A: `-a` removes all unused images, not just "dangling" ones (untagged). More aggressive.

**Q: Why is my Docker.raw file so large?**
A: Docker Desktop on Mac uses a VM. The disk image grows but doesn't auto-shrink. Run cleanup or resize in settings.

**Q: Should I exclude volumes from MacCleans cleanup?**
A: MacCleans includes `--volumes` but only deletes **unused** volumes. Still, review with `docker volume ls` first.

**Q: How do I shrink Docker.raw after cleanup?**
A: Docker Desktop → Preferences → Resources → Disk image size → Click "Optimize disk image"

## Summary

**Key Takeaways**:
1. 🐳 Docker can use 20-50GB+ on development machines
2. 🧹 Regular cleanup (monthly) prevents accumulation
3. ⚠️ Volumes contain data - don't delete carelessly
4. ✅ Images and build cache are safe to delete (just re-download/rebuild)
5. 🤖 Automate cleanup with MacCleans or cron
6. 📊 Monitor usage with `docker system df`

**Quick Cleanup**:
```bash
# Safe, automated
sudo ./clean-mac-space.sh

# Or manual
docker system prune -a
```

**Best Practice**: Clean during project transitions, not during active development.

---

**Related Reading**:
- [Understanding macOS Caches](understanding-macos-caches.md)
- [XCode Derived Data Guide](xcode-derived-data-guide.md)
- [Automating macOS Maintenance](automating-macos-maintenance.md)
- [Back to Main README](../README.md)

<!-- 🐳 Easter egg: Docker isn't actually a whale. It's a really fat container ship. Mind = blown. -->
