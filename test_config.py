#!/usr/bin/env python3
"""
Test configuration files for Redis RDI CTF
"""

import os
import re
import sys

def test_docker_compose():
    """Test docker-compose.yml configuration"""
    print("🐳 Testing docker-compose.yml...")
    
    if not os.path.exists('docker-compose.yml'):
        print("❌ docker-compose.yml not found")
        return False
    
    with open('docker-compose.yml', 'r') as f:
        content = f.read()
    
    # Check single port exposure
    port_matches = re.findall(r'"(\d+):\d+"', content)
    exposed_ports = [p for p in port_matches if p in ['5432', '8080', '3001']]
    
    if '8080' not in exposed_ports:
        print("❌ Port 8080 not exposed")
        return False
    
    if '5432' in exposed_ports:
        print("⚠️  Port 5432 still exposed (should be removed)")
        return False
        
    if '3001' in exposed_ports:
        print("⚠️  Port 3001 still exposed (should be removed)")
        return False
    
    print("✅ Only port 8080 exposed (correct)")
    return True

def test_dockerfile():
    """Test Dockerfile configuration"""
    print("🐳 Testing Dockerfile...")
    
    if not os.path.exists('Dockerfile'):
        print("❌ Dockerfile not found")
        return False
    
    with open('Dockerfile', 'r') as f:
        content = f.read()
    
    # Check EXPOSE directive
    expose_matches = re.findall(r'EXPOSE\s+(.+)', content)
    
    if not expose_matches:
        print("❌ No EXPOSE directive found")
        return False
    
    exposed = expose_matches[0].strip()
    if exposed != '8080':
        print(f"❌ Wrong ports exposed: {exposed} (should be 8080)")
        return False
    
    print("✅ Dockerfile exposes only port 8080")
    return True

def test_env_example():
    """Test .env.example file"""
    print("⚙️  Testing .env.example...")
    
    if not os.path.exists('.env.example'):
        print("❌ .env.example not found")
        return False
    
    with open('.env.example', 'r') as f:
        content = f.read()
    
    # Check for hardcoded credentials
    if 'redis-17173.c14.us-east-1-2.ec2.redns.redis-cloud.com' in content:
        print("❌ Hardcoded Redis credentials found")
        return False
    
    if 'W9EWqRUhjTD2MbIRWHt4G7stdWg0wy2p' in content:
        print("❌ Hardcoded Redis password found")
        return False
    
    print("✅ No hardcoded credentials in .env.example")
    return True

def test_requirements():
    """Test requirements.txt"""
    print("📦 Testing requirements.txt...")
    
    if not os.path.exists('requirements.txt'):
        print("❌ requirements.txt not found")
        return False
    
    with open('requirements.txt', 'r') as f:
        lines = f.readlines()
    
    # Should be streamlined (less than 15 lines)
    if len(lines) > 15:
        print(f"⚠️  Requirements file has {len(lines)} lines (should be streamlined)")
        return False
    
    # Check for key dependencies
    content = ''.join(lines).lower()
    required_deps = ['redis', 'psycopg2', 'flask', 'pandas']
    
    for dep in required_deps:
        if dep not in content:
            print(f"❌ Missing dependency: {dep}")
            return False
    
    print("✅ Requirements file is streamlined and complete")
    return True

def test_scripts():
    """Test key scripts exist"""
    print("🔧 Testing scripts...")
    
    required_scripts = [
        'scripts/rdi_connector.py',
        'scripts/check_flags.py',
        'scripts/rdi_web.py'
    ]
    
    for script in required_scripts:
        if not os.path.exists(script):
            print(f"❌ Missing script: {script}")
            return False
    
    print("✅ All key scripts present")
    return True

def main():
    """Run all configuration tests"""
    print("🧪 Redis RDI CTF Configuration Tests")
    print("=" * 40)
    
    tests = [
        test_docker_compose,
        test_dockerfile,
        test_env_example,
        test_requirements,
        test_scripts
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
            print()
        except Exception as e:
            print(f"❌ Test failed with error: {e}")
            results.append(False)
            print()
    
    # Summary
    passed = sum(results)
    total = len(results)
    
    print("=" * 40)
    if passed == total:
        print(f"🎉 All tests passed! ({passed}/{total})")
        print("✅ Configuration is ready for single port deployment")
        return 0
    else:
        print(f"⚠️  {passed}/{total} tests passed")
        print("❌ Configuration needs fixes before deployment")
        return 1

if __name__ == '__main__':
    sys.exit(main())
