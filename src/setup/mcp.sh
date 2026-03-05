# ── MCP Server Setup ──────────────────────────────────────────────────────────

# Setup MCP servers in .mcp.json
setup_mcp() {
  local add_context7="$1"
  local add_atlassian="$2"
  local mcp_file=".mcp.json"

  if [ -f "$mcp_file" ]; then
    return 0
  fi

  local servers=""
  local comma=""

  if [ "$add_context7" = true ]; then
    servers="${servers}${comma}
    \"context7\": {
      \"command\": \"npx\",
      \"args\": [\"-y\", \"@upstash/context7-mcp\"]
    }"
    comma=","
  fi

  if [ "$add_atlassian" = true ]; then
    servers="${servers}${comma}
    \"atlassian\": {
      \"type\": \"http\",
      \"url\": \"https://mcp.atlassian.com/v1/sse\"
    }"
  fi

  if [ -n "$servers" ]; then
    cat > "$mcp_file" << EOF
{
  "mcpServers": {${servers}
  }
}
EOF
    print_gray "MCP servers configured in .mcp.json"
  fi
}
