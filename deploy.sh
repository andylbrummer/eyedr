#!/bin/bash
# Deploy to Cloudflare Pages.
#
# The token comes from devkey, so there is nothing to set up by hand and nothing
# to remember. If no grant is live, devkey stops here and prints the one command
# to run; it never deploys unauthenticated.
set -euo pipefail
exec devkey run cloudflare -- npx wrangler@latest pages deploy . \
  --project-name=eyedr --branch=main
