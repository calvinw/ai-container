FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl git vim \
    python3 python3-pip python3-venv \
    lsof procps iproute2 jq \
    pspg bat fzf miller \
    bubblewrap ripgrep fd-find tree wget make \
    poppler-utils \
    locales \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install glow (markdown renderer) via Charm apt repo
RUN apt-get update && apt-get install -y gpg \
    && curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /usr/share/keyrings/charm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" > /etc/apt/sources.list.d/charm.list \
    && apt-get update && apt-get install -y glow \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install gh (GitHub CLI) via GitHub apt repo
RUN apt-get update && apt-get install -y gpg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install upterm
COPY scripts/install_upterm.sh /tmp/install_upterm.sh
RUN chmod +x /tmp/install_upterm.sh && /tmp/install_upterm.sh

# Bake all scripts, permissions, and configs into the image on PATH
COPY scripts/     /usr/local/lib/ai-tools/scripts/
COPY permissions/ /usr/local/lib/ai-tools/permissions/
COPY configs/     /usr/local/lib/ai-tools/configs/
RUN chmod +x /usr/local/lib/ai-tools/scripts/*.sh \
             /usr/local/lib/ai-tools/permissions/*.sh
ENV PATH="/usr/local/lib/ai-tools/scripts:/usr/local/lib/ai-tools/permissions:$PATH"

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp -L /root/.local/bin/claude /usr/local/bin/claude \
    && chmod 755 /usr/local/bin/claude

# Install npm-based AI tools
RUN npm i -g opencode-ai@latest \
    && npm i -g @openai/codex \
    && npm i -g @google/gemini-cli \
    && npm i -g @qwen-code/qwen-code \
    && npm i -g @charmland/crush \
    && npm i -g @github/copilot \
    && npm install -g @mariozechner/pi-coding-agent \
    && npm install -g supergateway@3.4.3 \
    && npm cache clean --force \
    && rm -rf /root/.cache

# Set simple prompt for all terminals
RUN echo 'PS1="# "' >> /root/.bashrc

WORKDIR /workspace

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
    && pi --version \
    && echo "=== All tools verified ==="
