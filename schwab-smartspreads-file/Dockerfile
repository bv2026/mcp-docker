FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/bv2026/schwab-smartspreads-file-mcp.git .

RUN pip install --no-cache-dir -e . mcp-proxy

# schwab.Client no longer exists as a top-level attribute — patch the type annotation
RUN sed -i '1s/^/from __future__ import annotations\n/' /app/src/schwab_mcp/auth.py

EXPOSE 3002

CMD ["mcp-proxy", "--host", "0.0.0.0", "--port", "3002", "--allow-origin", "*", \
     "--pass-environment", "--", \
     "python", "-m", "schwab_mcp.server"]
