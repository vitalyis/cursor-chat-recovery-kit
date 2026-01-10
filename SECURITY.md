# Security Policy

This document outlines the security policy for Cursor Chat Recovery Kit, including how to report vulnerabilities and security considerations.

## Supported Versions

This tool is designed to work with Cursor editor on macOS. We support the current stable version of Cursor.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it via:

- **GitHub Security Advisory:** Use the "Report a vulnerability" button on the repository
- **Email:** [Your email or security contact]
- **Private Issue:** Create a private security issue (if enabled)

> **⚠️ Important:** Do not open a public issue for security vulnerabilities.

## Security Considerations

- **Local Processing Only** — All operations are performed locally on your machine. No data is transmitted to external servers.
- **No Network Access** — The scripts do not make any network requests.
- **File System Access** — The tools require access to Cursor's workspace storage directory (`~/Library/Application Support/Cursor/User/`).
- **Backup Safety** — Always ensure Cursor is closed before running migration or restore operations to prevent data corruption.
- **Read-Only by Default** — Most operations create backups before modifying data.

## Best Practices

1. **Close Cursor** — Always close Cursor before running migration or restore operations
2. **Review Backups** — Review backup contents before restoring
3. **Multiple Snapshots** — Keep multiple backup snapshots
4. **Test First** — Test on non-critical projects first
5. **Verify Paths** — Verify workspace paths before migration

---

> **⚠️ Important:** Always close Cursor before running migration or restore operations!

**Made with ❤️ for the Cursor community**
