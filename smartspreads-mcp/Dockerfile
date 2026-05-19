FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/bv2026/mcp-smartspreads.git .

RUN pip install --no-cache-dir -e . mcp-proxy

EXPOSE 3001

CMD ["mcp-proxy", "--host", "0.0.0.0", "--port", "3001", "--allow-origin", "*", \
     "--pass-environment", "--", \
     "python", "-m", "newsletter_mcp.server"]
