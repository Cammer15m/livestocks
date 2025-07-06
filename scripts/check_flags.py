#!/usr/bin/env python3
import os
try:
    import redis
except ImportError:
    print("❌ Redis package not found. Install with: pip install redis")
    exit(1)

def get_redis_connection():
    """Get Redis connection from environment variables"""
    redis_url = os.getenv('REDIS_URL')
    if redis_url:
        # Parse Redis Cloud URL
        return redis.from_url(redis_url, decode_responses=True)
    else:
        # Fallback to localhost (for backward compatibility)
        return redis.Redis(host='localhost', port=6379, decode_responses=True)

def main():
    print("🏴 Redis RDI CTF - Flag Checker")
    print("=" * 40)

    try:
        r = get_redis_connection()

        # Test connection
        r.ping()
        print("✅ Connected to Redis successfully")
        print()

        # Check flags
        flags = ['flag:01', 'flag:02', 'flag:03']
        completed = 0

        for flag in flags:
            val = r.get(flag)
            if val:
                print(f"✅ {flag} => {val}")
                completed += 1
            else:
                print(f"❌ {flag} => NOT FOUND")

        print()
        print(f"Progress: {completed}/{len(flags)} flags captured ({completed/len(flags)*100:.0f}%)")

        if completed == len(flags):
            print("🎉 Congratulations! All flags captured!")
        elif completed > 0:
            print("🚀 Great progress! Keep going!")
        else:
            print("📚 Ready to start? Begin with Lab 1!")

    except redis.ConnectionError:
        print("❌ Could not connect to Redis")
        print("💡 Make sure your .env file is configured with REDIS_URL")
        print("💡 Run: source .env && python3 check_flags.py")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
