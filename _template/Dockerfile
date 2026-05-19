FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/bv2026/YOUR-REPO-HERE.git .

RUN pip install --no-cache-dir -e . mcp-proxy

EXPOSE 3000

# Traefik strips the path prefix before forwarding, so mcp-proxy sees /sse
CMD ["mcp-proxy", "--host", "0.0.0.0", "--port", "3000", "--allow-origin", "*", \
     "--pass-environment", "--", \
     "python", "-m", "your_module.server"]
