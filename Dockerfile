FROM mcr.microsoft.com/devcontainers/universal:2

# Install upterm
COPY scripts/install_upterm.sh /tmp/install_upterm.sh
RUN chmod +x /tmp/install_upterm.sh && /tmp/install_upterm.sh

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -sf /root/.local/bin/claude /usr/local/bin/claude

# Install npm-based AI tools
RUN npm i -g opencode-ai@latest \
    && npm i -g @openai/codex \
    && npm i -g @google/gemini-cli

# Verify all tools are installed
RUN echo "=== Verifying installed tools ===" \
    && upterm version \
    && claude --version \
    && opencode --version \
    && codex --version \
    && gemini --version \
    && echo "=== All tools verified ==="
