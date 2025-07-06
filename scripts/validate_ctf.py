#!/usr/bin/env python3
"""
Redis RDI CTF Validation Script
Validates the complete CTF environment and lab completion
"""

import redis
import json
import sys
import os
from datetime import datetime

# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

def print_header():
    print(f"{Colors.CYAN}{'='*60}{Colors.NC}")
    print(f"{Colors.WHITE}🏆 Redis RDI CTF Validation Report{Colors.NC}")
    print(f"{Colors.CYAN}{'='*60}{Colors.NC}")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

def print_status(message, status="INFO"):
    color_map = {
        "INFO": Colors.BLUE,
        "SUCCESS": Colors.GREEN,
        "WARNING": Colors.YELLOW,
        "ERROR": Colors.RED
    }
    color = color_map.get(status, Colors.WHITE)
    print(f"{color}[{status}]{Colors.NC} {message}")

def check_redis_connection():
    """Test Redis connectivity"""
    try:
        r = redis.Redis(host='localhost', port=6379, decode_responses=True)
        r.ping()
        print_status("✓ Redis connection successful", "SUCCESS")
        return r
    except Exception as e:
        print_status(f"✗ Redis connection failed: {e}", "ERROR")
        return None

def validate_flags(r):
    """Validate all CTF flags"""
    print_status("Validating CTF flags...", "INFO")
    
    expected_flags = {
        "flag:01": "RDI{pg_to_redis_success}",
        "flag:02": "RDI{snapshot_vs_cdc_detected}",
        "flag:03": "RDI{advanced_features_mastered}"
    }
    
    results = {}
    for flag_key, expected_value in expected_flags.items():
        try:
            actual_value = r.get(flag_key)
            if actual_value == expected_value:
                print_status(f"✓ {flag_key}: {actual_value}", "SUCCESS")
                results[flag_key] = True
            else:
                print_status(f"✗ {flag_key}: Expected '{expected_value}', got '{actual_value}'", "ERROR")
                results[flag_key] = False
        except Exception as e:
            print_status(f"✗ {flag_key}: Error retrieving flag - {e}", "ERROR")
            results[flag_key] = False
    
    return results

def check_lab_artifacts(r):
    """Check for lab-specific artifacts in Redis"""
    print_status("Checking lab artifacts...", "INFO")
    
    artifacts = {
        "Lab 1 - Snapshot data": "user:*",
        "Lab 2 - CDC data": "cdc_user:*",
        "Lab 2 - Change stream": "user_changes",
        "Lab 3 - Order data": "order:*",
        "Lab 3 - Profile data": "profile:*"
    }
    
    results = {}
    for description, pattern in artifacts.items():
        try:
            if "*" in pattern:
                keys = r.keys(pattern)
                if keys:
                    print_status(f"✓ {description}: Found {len(keys)} keys", "SUCCESS")
                    results[description] = True
                else:
                    print_status(f"⚠ {description}: No keys found", "WARNING")
                    results[description] = False
            else:
                exists = r.exists(pattern)
                if exists:
                    print_status(f"✓ {description}: Exists", "SUCCESS")
                    results[description] = True
                else:
                    print_status(f"⚠ {description}: Not found", "WARNING")
                    results[description] = False
        except Exception as e:
            print_status(f"✗ {description}: Error - {e}", "ERROR")
            results[description] = False
    
    return results

def check_connectors(r):
    """Check RDI connector configurations"""
    print_status("Checking RDI connector configurations...", "INFO")
    
    connectors = [
        "streams:pg_snapshot",
        "streams:pg_cdc",
        "rdi:pipeline:orders",
        "rdi:pipeline:profiles"
    ]
    
    results = {}
    for connector in connectors:
        try:
            config = r.json().get(connector)
            if config:
                print_status(f"✓ {connector}: Configured", "SUCCESS")
                results[connector] = True
            else:
                print_status(f"⚠ {connector}: Not configured", "WARNING")
                results[connector] = False
        except Exception as e:
            print_status(f"✗ {connector}: Error - {e}", "ERROR")
            results[connector] = False
    
    return results

def generate_summary(flag_results, artifact_results, connector_results):
    """Generate final summary"""
    print()
    print_status("CTF Completion Summary", "INFO")
    print(f"{Colors.CYAN}{'-'*40}{Colors.NC}")
    
    # Flag completion
    completed_flags = sum(flag_results.values())
    total_flags = len(flag_results)
    flag_percentage = (completed_flags / total_flags) * 100
    
    print(f"🏴 Flags Captured: {completed_flags}/{total_flags} ({flag_percentage:.0f}%)")
    
    # Lab completion estimation
    lab_scores = {
        "Lab 1": flag_results.get("flag:01", False),
        "Lab 2": flag_results.get("flag:02", False),
        "Lab 3": flag_results.get("flag:03", False)
    }
    
    for lab, completed in lab_scores.items():
        status = "✅ COMPLETE" if completed else "❌ INCOMPLETE"
        print(f"{lab}: {status}")
    
    # Overall assessment
    print()
    if completed_flags == total_flags:
        print_status("🎉 CONGRATULATIONS! All labs completed successfully!", "SUCCESS")
        print_status("You've mastered Redis Data Integration patterns!", "SUCCESS")
    elif completed_flags >= 2:
        print_status("🎯 Great progress! Almost there!", "SUCCESS")
        print_status("Complete the remaining labs to finish the CTF", "INFO")
    elif completed_flags >= 1:
        print_status("🚀 Good start! Keep going!", "WARNING")
        print_status("Continue with the next labs", "INFO")
    else:
        print_status("📚 Ready to begin your RDI journey!", "INFO")
        print_status("Start with Lab 1: labs/01_postgres_to_redis/", "INFO")

def main():
    print_header()
    
    # Connect to Redis
    r = check_redis_connection()
    if not r:
        sys.exit(1)
    
    print()
    
    # Run validations
    flag_results = validate_flags(r)
    print()
    
    artifact_results = check_lab_artifacts(r)
    print()
    
    connector_results = check_connectors(r)
    print()
    
    # Generate summary
    generate_summary(flag_results, artifact_results, connector_results)
    
    print()
    print_status("Next steps:", "INFO")
    print("  • Review incomplete labs")
    print("  • Check lab README files for detailed instructions")
    print("  • Use RedisInsight (http://localhost:8001) to explore data")
    print("  • Run './test_all_labs.sh' for environment diagnostics")
    print()

if __name__ == "__main__":
    main()
