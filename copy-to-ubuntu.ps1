$ip = "bvajjala@192.168.1.167"

Write-Host "=== Copying files to Ubuntu MCP host ===" -ForegroundColor Cyan

Write-Host "`n[1/3] smartspreads-mcp data..."
scp C:\work\SmartSpreads\newsletters.db              "${ip}:/data/smartspreads/"
scp -r C:\work\SmartSpreads\data\*                   "${ip}:/data/smartspreads/"
scp -r C:\work\SmartSpreads\published\*              "${ip}:/data/smartspreads/published/"

Write-Host "`n[2/3] schwab config + OAuth token..."
scp C:\work\schwab-mcp-file\config\smartspreads.db   "${ip}:/data/schwab/config/"
scp C:\work\schwab-mcp-file\config\tos-statement.csv "${ip}:/data/schwab/config/"
scp C:\work\schwab-mcp-file\config\positions.yaml    "${ip}:/data/schwab/config/"
scp C:\work\schwab-mcp-file\config\watchlist.yaml    "${ip}:/data/schwab/config/"
scp C:\Users\vsbra\.schwab\token.json                "${ip}:/data/schwab/config/"

Write-Host "`n[3/3] bullstrangle data..."
scp -r C:\work\bullstrangle\newsletters\*            "${ip}:/data/bullstrangle/data/newsletters/"
scp C:\work\bullstrangle\bullstrangle.db             "${ip}:/data/bullstrangle/data/"

Write-Host "`nDone! All files copied to 192.168.1.167" -ForegroundColor Green
