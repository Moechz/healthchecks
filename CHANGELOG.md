# Changelog

All notable user-visible changes to the Healthchecks TOS application package.

## 5.0.3-1 — 2026-11-14

### Added
- First release. Healthchecks (`linuxserver/healthchecks:5.0.3`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8053 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/healthchecksdocker/`.
