# Development Guidelines

## Core Principles

### No Assumptions Rule
**Never make assumptions about file structures, paths, or system behavior - always verify the actual state first by checking what exists before making changes.**

This rule applies to:
- File paths and directory structures
- Binary locations after installation/extraction
- System behavior and command outputs
- Container states and running processes
- Network connectivity and port availability

### Verification Before Action
Always check the current state before making changes:
1. Use `ls`, `find`, `docker exec` to verify file locations
2. Check actual directory contents after extractions
3. Verify binary existence and executability before using
4. Test commands and paths before committing to code
5. Examine logs and outputs to understand actual behavior

### Documentation
- Document actual findings, not assumptions
- Record verified paths and structures
- Note differences between expected and actual behavior
