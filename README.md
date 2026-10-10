# DevOps Interview Task (Part 1): Containerize

**This is a take-home task.** Please submit by the date given when the task was
issued.

## Overview

You are given a small web application (`app/`). A working `Dockerfile` is
provided, but it was written quickly and does **not** follow container best
practices. Your job is to refactor it into a production-quality image and push
it to a container registry.

You do **not** need to modify the application code.

## What we provide

Clone this repository into your local account.

> **Do Not** fork this repository. Clone it and re-push it into your local account.

The following is provided as part of this repository:

```text
Dockerfile            # a working but non-production Dockerfile — improve it
app/
  app.py              # a minimal Python Flask web app (do not modify)
  requirements.txt    # the app's dependencies (do not modify)
```

The application:

-   Listens on the port given by the `PORT` environment variable (default `8080`).
-   Reads a `GREETING` environment variable used in its response.
-   Exposes `GET /`, `GET /healthz`, and `GET /info`.


## Improvements made

### Multi-stage Build
- I have used a multi-stage build Dockerfile as it allows me to separate out the build time dependencies from the runtime essentials.
- This allows the final image to stay minimal in size and have a lower attack surface.
- The base dev image for example is ~250mb in size whereas the base final image is ~25mb in size with the built final image being ~130mb in size.

### Chainguard base image
- I chosen to use the [Chainguard Python base image](https://images.chainguard.dev/directory/image/python/versions) as it is distroless, lightweight and has very few vulnerabilities (at time of committing it has 2 medium vulnerabilities).
- In an ideal world I would've chosen a specific image tag for a Chainguard Python base image, however they are not offered for free. As such I have used the latest tag but added the digest allowing me to pin a specific version.
- When newer digests become available, I would test these to ensure compatiability, before updating on the main branch.
- The [Python base image](https://hub.docker.com/layers/library/python/3.12/images/sha256-80dc3cfc45ae547207a41dad6f0e8bf86fbf11fe53e1b3e3a075893ba132c01d) is large in size (~400mb) and therefore has a larger attack surface. The latest version of the Python 3.12 base image on Docker Hub had 2 critical and 30 high vulnerabilities. As this is a small web app I did consider other possible options such a slim Debian Python base image like slim-trixie (~40mb) or an Alpine base image (~20mb) which would reduce the size of the image, improving performance whilst keeping the required functionality, however the Chainguard image was my preferred choice.

### Python version 3.14
- The original Python base image was using version 3.12 released back in 2023 and no longer has full support, only security fixes. The latest Chainguard images use version 3.14 which has with [full support until October 2027 and security support until 2030](https://endoflife.date/python).

### Non root user
- In the original Python base image, as no user was specified in the original Dockerfile, by default the commands in the Dockerfile will be ran as root user. However for Chainguard images the user is non-root (UID 65532) by [default](https://github.com/chainguard-images/images/blob/main/BEST_PRACTICES.md#users) so I have not added a user to the Dockerfile.

### Python Virtual Environment
- I have created a python virtual environment to make it easier to copy dependencies from the `builder` image stage to the `final` image stage. This is because by default when Python packages are installed, the packages and related files are installed in various places. By created a virtual environment you can ensure you know where the dependencies are being installed, making the copying of them over to the final image stage simpler.

### APT Update and Install Removed
- The packages were not required to run the Python application so I have removed the code block.
- If they were necessary I would've included specific versions of the packages required within the code block.
- Additionally Chainguard Dev Python Images use [APK](https://edu.chainguard.dev/open-source/wolfi/apk-package-manager/) rather than APT, so if additional packages were needed they'd need to be installed using APK.

### Copying only files required
- In the original dockerfile all files from the repository were copied into the container. This is not needed and could potentially result in sensitive data being accidentially copied into the container at a later date by mistake as the application repository changes over time.

### PIP cache not required
- There is no requirement for the PIP cache as the packages will not need to be reinstalled in a container and the cache will only make the final image larger. As such I have added `--no-cache-dir` to the pip install command.

### Build time argument for PORT
- I've made the port a build time argument, allowing for different ports to be used if different configurations were needed in the future.

### Only storing arguments in CMD
- I have added an `ENTRYPOINT` to define the main command that is executed when the container starts.
- `CMD` now only stores arguments allowing users to override arguments at runtime.

### .dockerignore
- I've added a `.dockerignore` as best practice, whilst only the app folder and its contents are copied following my updates to the Dockerfile, I have included it in case the Dockerfile changes in the future and tries to copy more than the `/app` folder and its contents.

### GitHub Actions
- I have added a GitHub Actions workflow for container scanning. The workflow checks out the code, builds the image, then scans the image using [Trivy](https://github.com/marketplace/actions/aqua-security-trivy) and [Hadolint](https://github.com/marketplace/actions/hadolint-action).

## Other considerations
- `HEALTHCHECK` within dockerfile - I did not add one as the container is planned to be deployed using Kubernetes and I would use the `/healthz` endpoint for the readiness and liveness probes.