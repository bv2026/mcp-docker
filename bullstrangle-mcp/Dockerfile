FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/bv2026/bullstrangle-mcp.git .

RUN pip install --no-cache-dir -e ".[excel]" mcp-proxy

EXPOSE 3003

CMD ["mcp-proxy", "--host", "0.0.0.0", "--port", "3003", "--allow-origin", "*", \
     "--pass-environment", "--", \
     "bullstrangle-mcp-server"]
