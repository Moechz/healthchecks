# healthchecks-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Healthchecks](https://github.com/healthchecks/healthchecks).

## What this is

A four-file TOS Docker application archive (`healthchecksdocker.tar.gz`) that installs
Healthchecks on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `healthchecksdocker`)
- `healthchecksdocker.lang` — 23-language superset (TOS requires 14)
- `healthchecksdocker.svg` — application icon (2717 bytes, 3 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/healthchecks:5.0.3`

## How it works

| | |
|---|---|
| Container image | `linuxserver/healthchecks:5.0.3` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8053/` (container port 8000) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/healthchecksdocker/config` |
| Logs | `docker logs healthchecksdocker` (stdout/stderr) |

`/config` (mounted from `DockerAppData/healthchecksdocker/config`) holds `hc.sqlite`, `local_settings.py` (SECRET_KEY, ALLOWED_HOSTS, SITE_ROOT) and the uploads folder.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: the upstream s6 init cannot run as uid 1000; the wrapper copies the app to a writable directory, wires `local_settings.py`/`hc.sqlite` to the data folder and starts uWSGI directly.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8000.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **s6 bypassed.** The LSIO init and its uWSGI service need root; the wrapper copies the app to `/tmp/hc` (writable) and runs uWSGI as uid 1000.
- **Host header acceptance.** `ALLOWED_HOSTS = ["*"]` is seeded so the UI works from any NAS IP; the user-editable `SITE_ROOT` controls absolute links in notifications.
- **SQLite only.** The database is a single file in the data folder.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/healthchecksdocker/config` | Healthchecks application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/healthchecksdocker.tar.gz + .sha256
scripts/build.sh 5.0.3-2   # packaging iteration bump
scripts/build.sh 5.0.3-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/healthchecksdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v5.0.3-1`**, assets `healthchecksdocker.tar.gz` +
   `healthchecksdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `healthchecksdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `5.0.3-1` → automated validation → review.

## License / branding

Healthchecks is distributed by its upstream authors under **BSD-3-Clause**. The container image is the official image from Docker Hub (`linuxserver/healthchecks:5.0.3`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- Notification links use SITE_ROOT (seeded as localhost) until you edit it in `local_settings.py`.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.
- The image is copied to /tmp on every start; the persistent state is only in the data folder.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
