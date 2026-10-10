FROM cgr.dev/chainguard/python:latest-dev@sha256:47b1a23ae387fc1d5264abd79c395827fcca7ef92afe086908b51ce0747e8e77 AS builder

WORKDIR /app

RUN python -m venv /app/venv

ENV PATH="/app/venv/bin:$PATH"

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM cgr.dev/chainguard/python:latest@sha256:c26e4957fef58d936401b8e2bb9ccb6db0f404f51597a0d2c7586e1d0112df0a AS final

WORKDIR /app

ENV PATH="/app/venv/bin:$PATH"

COPY --from=builder /app/venv /app/venv

COPY app/ .

ARG PORT=8080
EXPOSE ${PORT}

ENTRYPOINT [ "/app/venv/bin/gunicorn" ]
CMD ["--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
