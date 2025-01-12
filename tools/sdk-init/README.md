# SDK Init Utility

This utility is designed to run within Docker containers, specifically in environments like Kubernetes. Its purpose is to copy protocol buffer files from a source directory to a shared directory at runtime and then execute the user's application. The utility ensures proper signal handling, so it integrates seamlessly with Kubernetes termination signals.

---

## Features

* Copies files from a source directory (/protos by default) to a destination directory (/shared/protos by default).

* Configurable directories via environment variables:
  * `SRC_DIR`: Source directory (default: `/protos`).
  * `DEST_DIR`: Destination directory (default: `/shared/protos`).

* Executes the user's application after copying files.
* Handles system signals (e.g., `SIGTERM`, `SIGINT`) and propagates them to the user's application.

---

## Usage

**Environment Variables**

* `SRC_DIR`: The source directory containing the protocol buffer files. Default: `/protos`.

* `DEST_DIR`: The destination directory where files will be copied. Default: `/shared/protos`.

**Docker Example**

Build the Docker image:

```bash
docker build -t sdk-init-test:latest .
```

Run the container with custom directories:

```bash
docker run --rm -p 5000:5000 -v ./shared:/shared sdk-init-test:latest
```

---

## Signal Handling

The utility forwards termination signals (`SIGTERM`, `SIGINT`) to the user's application, ensuring it gracefully shuts down. This is essential for environments like Kubernetes, where proper termination is critical for containerized applications.

---

## Development

**Code Structure**

* `main.go`: Orchestrates the file copying and command execution.

* `pkg/copier/copier.go`: Handles the logic for copying files from the source to the destination directory.

* `pkg/runner/runner.go`: Manages the execution of the user's application and signal forwarding.

**Build a Production-Ready Binary**

```bash
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/sdk-init ./cmd && upx --best --lzma bin/sdk-init
```