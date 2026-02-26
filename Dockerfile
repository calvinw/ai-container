FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl git vim \
    python3 python3-pip python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install upterm
COPY scripts/install_upterm.sh /tmp/install_upterm.sh
RUN chmod +x /tmp/install_upterm.sh && /tmp/install_upterm.sh

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp -L /root/.local/bin/claude /usr/local/bin/claude \
    && chmod 755 /usr/local/bin/claude

# Install npm-based AI tools
RUN npm i -g opencode-ai@latest \
    && npm i -g opencode-gemini-auth \
    && npm i -g @openai/codex \
    && npm i -g @google/gemini-cli \
    && npm i -g @qwen-code/qwen-code \
    && npm i -g @charmland/crush \
    && npm i -g @github/copilot

# Configure opencode with gemini-auth plugin for all users
COPY config/opencode.json /etc/skel/.config/opencode/opencode.json
RUN mkdir -p /home/node/.config/opencode \
    && cp /etc/skel/.config/opencode/opencode.json /home/node/.config/opencode/opencode.json \
    && chown -R node:node /home/node/.config

# Verify all tools are installed
RUN echo "=== Verifying installed tools ===" \
    && upterm version \
    && claude --version \
    && opencode --version \
    && codex --version \
    && gemini --version \
    && qwen --version \
    && crush --version \
    && copilot --version \
    && echo "=== All tools verified ==="
