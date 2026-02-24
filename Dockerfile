FROM mcr.microsoft.com/devcontainers/javascript-node:22

# Install Python
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv \
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
    && npm i -g @google/gemini-cli

# Configure opencode with gemini-auth plugin for all users
RUN mkdir -p /etc/skel/.config/opencode /home/node/.config/opencode \
    && echo '{"$schema":"https://opencode.ai/config.json","plugin":["opencode-gemini-auth"],"model":"google/gemini-3.1-pro-preview"}' \
       > /etc/skel/.config/opencode/opencode.json \
    && cp /etc/skel/.config/opencode/opencode.json /home/node/.config/opencode/opencode.json \
    && chown -R node:node /home/node/.config

# Verify all tools are installed
RUN echo "=== Verifying installed tools ===" \
    && upterm version \
    && claude --version \
    && opencode --version \
    && codex --version \
    && gemini --version \
    && echo "=== All tools verified ==="
