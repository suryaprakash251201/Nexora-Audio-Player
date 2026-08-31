# Security Policy

## Supported Versions

We currently support the latest major version of Nexora Audio Player. 
As this project transitions to a pure Flutter architecture, only the `main` branch is actively supported for security updates.

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| 1.0.x   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within Nexora Audio Player, please **do not disclose it publicly**.
Instead, please open an issue labeled as `Security` or contact the repository maintainers directly.

We will investigate all legitimate reports and strive to issue a patch or mitigation as quickly as possible.

## Best Practices
- **Local Network Safety:** Nexora Audio Player allows connecting to unencrypted `http://` local network IPs (e.g., `192.168.x.x`). Do not use `http://` endpoints when connecting over public networks or the open internet.
- **Token Storage:** Authentication tokens are stored using hardware-backed Secure Storage (`flutter_secure_storage`). Ensure your device maintains a strong lock screen passcode.
