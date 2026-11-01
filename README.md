# OpenCode Docker

A community-maintained Docker image for [OpenCode](https://github.com/anomalyco/opencode), built on **Ubuntu 22.04 LTS**.

This fork is intended for running **OpenCode 2** with persistent data and configurable user/group IDs. OpenCode runs as a non-root user, with passwordless `sudo` available when system packages need to be installed inside the container.

Images are built **manually** using GitHub Actions and published to GitHub Container Registry (GHCR):

[GitHub Container Registry](https://github.com/dimpen/opencode-docker/pkgs/container/opencode)

**There are no scheduled or automatic update builds.** The `:latest` image contains the OpenCode version installed when that tag was last built manually; it is not guaranteed to match the newest upstream release.

## Prerequisites

- Docker with the Compose plugin (`docker compose`)
- Access to the GHCR image

## Quick start

1. Use the provided `docker-compose.yml` and create a local `.env` file with your settings:

   ```dotenv
   PUID=1000
   PGID=1000
   OPENCODE_PASSWORD=replace-with-a-strong-password
   ```

2. Pull and start the container:

   ```bash
   docker compose pull
   docker compose up -d
   ```

3. Inspect its startup logs:

   ```bash
   docker compose logs -f opencode
   ```

The image's default command starts the OpenCode server on port **4096**. You can override this with `command:` in Docker Compose.

The OpenCode server listens on port 4096 inside the container and is accessible at http://172.17.0.1:4096 on the Docker host.

## Configuration

### Environment variables

| Variable | Purpose |
| --- | --- |
| `TZ` | Container timezone (set in `.env`). |
| `PUID` | Numeric UID of the `opencode` user at runtime; defaults to `1000`. |
| `PGID` | Numeric GID of the `opencode` group at runtime; defaults to `1000`. |
| `OPENCODE_PASSWORD` | Password for the OpenCode 2 HTTP server; required by the provided Compose configuration. |

The HTTP authentication username is always **`opencode`** in OpenCode 2. See the [official OpenCode server documentation](https://opencode.ai/v2/docs/cli/web/).

### User IDs and permissions

The entrypoint starts as root, adjusts the internal `opencode` UID/GID to match `PUID`/`PGID`, corrects ownership of OpenCode's persistent configuration and data directories when needed, and then starts OpenCode as the non-root user.

Find your host UID and GID with:

```bash
id -u
id -g
```

`PUID` and `PGID` must be nonzero numeric IDs. The entrypoint does **not** recursively change ownership of `/workspace`; ensure your mounted project directory is writable by the selected UID/GID.

**Sudo access:** The `opencode` user has `NOPASSWD:ALL` sudo privileges inside the container. This allows OpenCode to install packages, for example with `sudo apt-get install`, but also gives the agent the ability to run arbitrary commands as root **inside the container**. Root access can affect writable host-mounted directories. Use trusted projects and restrict access to the OpenCode server. Packages installed into a running container are lost if that container is recreated; add packages you need permanently to the Dockerfile.

### Persistent volumes

The provided Compose setup mounts:

| Host path | Container path | Purpose |
| --- | --- | --- |
| `./data/share` | `/home/opencode/.local/share/opencode` | OpenCode shared data, including provider credentials. |
| `./data/state` | `/home/opencode/.local/state/opencode` | OpenCode state. |
| `./data/config` | `/home/opencode/.config/opencode` | Global configuration, including `opencode.json`. |
| `./workspace` | `/workspace` | Working files and projects. |

Keep the data directories and `.env` file private. Do not commit provider credentials, API keys, or other secrets to Git.

### Provider authentication and configuration

You can configure providers interactively using the OpenCode CLI:

```bash
docker compose exec -u opencode opencode opencode auth login
```

Credentials are stored in OpenCode's persistent shared-data directory. Provider and model settings can be placed in `./data/config/opencode.json`; consult the [OpenCode configuration documentation](https://opencode.ai/v2/docs/config/) for the current schema. When migrating existing OpenCode 1 configuration, also review the [V1 to V2 migration guide](https://opencode.ai/v2/docs/migrate-v1).


## License

Released under the [MIT license](LICENSE).

## Disclaimer

This is an independent community Docker image, forked from [pilinux/opencode-docker](https://github.com/pilinux/opencode-docker). It is **not** an official OpenCode image and is not affiliated with the OpenCode project. For issues involving OpenCode itself, see the [upstream OpenCode repository](https://github.com/anomalyco/opencode).
