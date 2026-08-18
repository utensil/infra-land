
# prep-llms:
#     which aichat || brew install aichat
#     which assembllm || (brew tap bradyjoslin/assembllm && brew install bradyjoslin/assembllm/assembllm)
#     which cortex || echo "Visit https://cortex.so/docs/installation to download and install cortex"

# Install aichat and render its config.
prep-aichat:
    #!/usr/bin/env bash
    which aichat || brew install aichat
    mkdir -p ~/.config/aichat
    tools/config/render_yaml.py dotfiles/.config/aichat/config.in.yaml ~/.config/aichat/config.yaml
    cat ~/.config/aichat/config.yaml|sd 'api_key:(.*)' 'api_key: <hidden>'

# Run aichat after syncing config.
aichat *PARAMS: sync-aichat
    aichat {{PARAMS}}

# Deprecated:
# In Helix, select some code, press `|` then type `aicode`
# Instead:
# In Helix, select some code, press `|` then type `aichat -c` optionally with extra `--prompt` as system prompt
#
# Install the legacy aicode helper script.
prep-aicode:
    sudo cp -f dotfiles/bin/aicode /usr/local/bin/

# Render aichat config
#
# Render and deploy aichat configuration.
sync-aichat:
    #!/usr/bin/env bash
    tools/config/render_yaml.py dotfiles/.config/aichat/config.in.yaml ~/.config/aichat/config.yaml
    cat ~/.config/aichat/config.yaml|sd 'api_key:(.*)' 'api_key: <hidden>'

# Install aider MCP helper and seed Claude config.
prep-aider:
    just sync-aider
    which mcpm-aider || npm install -g @poai/mcpm-aider
    mkdir -p ~/.config/claude
    [[ -f ~/.config/claude/claude_desktop_config.json ]] || echo '{"mcpServers": {} }' > ~/.config/claude/claude_desktop_config.json

# Copy the aider wrapper into /usr/local/bin.
sync-aider:
    cp -f dotfiles/bin/aider /usr/local/bin || sudo cp -f dotfiles/bin/aider /usr/local/bin

# Suggest TODOs from the forest notes.
todo:
    #!/usr/bin/env bash
    cat trees/uts-0018.tree |aichat --prompt "randomly suggest 3 small TODOs that I was interested to read or I intend to try"

# just mcp search
# just mcp install XXX
# just mcp list
# just mcp remove XXX
# just mcp toolprompt
#
# Manage MCP servers for aider.
mcp *PARAMS="":
    #!/usr/bin/env bash
    mcpm-aider {{PARAMS}}

# sync-aider
#
# Open aider in a project.
aider PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}} && aider {{PARAMS}}

# Scrape a URL with aider.
aiderweb URL:
    uvx --python 3.11 --from 'aider-chat[help,playwright,browser]' python -m aider.scrape {{URL}}

# Build the memvid project environment.
prep-mp4:
    #!/usr/bin/env bash
    just clone Olow304 memvid
    cd ~/projects/memvid
    git reset --hard 5524b0a8b268c02df01cca87110cc1b978460c97
    uv venv --python 3.11 --seed
    source .venv/bin/activate
    uv pip install -e .
    uv pip install PyPDF2 openai
    # sd 'extensions = \{' 'extensions = { ".tree", ' examples/file_chat.py
    # sd "with_suffix\('_index.json'\)" "with_suffix('.json')" examples/file_chat.py

# just mp4 forest --input-dir trees --extensions .tree
# just mp4 forest --load-existing output/dir_trees_20250606_200619.mkv
#
# Build a memvid archive for a project.
mp4 PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/memvid
    source .venv/bin/activate
    cd ~/projects/{{PROJ}}
    export OPENAI_BASE_URL=$OPENAI_API_BASE
    python ~/projects/memvid/examples/file_chat.py --provider openai --model $OPENAI_API_MODEL {{PARAMS}}

# prep-ad:
#    #!/usr/bin/env bash
#    rip ../aider-desk
#    if [ ! -d ../aider-desk ]; then
#        # (cd .. && git clone https://github.com/hotovo/aider-desk)
#        # clone a tag v0.4.0
#        (cd .. && git clone --branch v0.4.0 https://github.com/hotovo/aider-desk)
#    else
#        (cd ../aider-desk && git pull)
#    fi
#    cd ../aider-desk
#    npm install
#    npm run build:mac


# Uses aider in watch mode to actively monitor and assist with code changes.
# To work with other projects:
#   1. Use `just proj` to select and open a project in a new kitty terminal
#   2. Or use `just aider ../project_name` to start aider in another directory
# I've tested that it works with `AI!`, `AI?`, and `ai!`
#
# Start aider in watch mode for a project.
aw PROJ="forest" *PARAMS="":
    just aider {{PROJ}} --watch-files {{PARAMS}} --read AGENT.md --edit-format diff # -v

# Start the LLM proxy.
llm-proxy *PARAMS:
    #!/usr/bin/env bash
    # uvx --python 3.11 --from 'litellm[proxy]' litellm {{PARAMS}}
    aichat --serve 0.0.0.0:4000

# Launch LiteLLM proxy with OpenAI-compatible settings.
llp *PARAMS:
    #!/usr/bin/env bash
    uvx --python 3.11 --from 'litellm[proxy]' --with opentelemetry-api --with opentelemetry-sdk --with opentelemetry-exporter-otlp --with langchain --with langchain-openai --with lunary --with openinference-instrumentation-litellm litellm {{PARAMS}} --api_base {{env('OPENAI_API_BASE')}} -m 'openai/{{env('OPENAI_API_MODEL')}}' -c dotfiles/.config/litellm/litellm.yaml

# Run copilot-more API server.
cpm:
    #!/usr/bin/env bash
    set -e
    # if env var REFRESH_TOKEN is not set, prompt for it
    if [ -z "$REFRESH_TOKEN" ]; then
        # curl https://github.com/login/device/code -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email'
        # curl https://github.com/login/oauth/access_token -X POST -d 'client_id=01ab8ac9400c4e429b23&scope=user:email&device_code=YOUR_DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code'
        echo "Please follow https://github.com/jjleng/copilot-more to set up REFRESH_TOKEN"
    fi
    just clone jjleng copilot-more
    cd ~/projects/copilot-more
    git reset --hard 21d9ee3dce5c7852d431d2c13cca72c426c8a302
    uvx poetry install
    LOGURU_LEVEL=DEBUG uvx poetry run uvicorn copilot_more.server:app --port 15432 --host {{env('COPILOT_HOST', '127.0.0.1')}}

# -c : Generate a command to launch Claude Code with Copilot API config
#
# Start Copilot API for Claude Code integration.
cpa *PARAMS: prep-node
    #!/usr/bin/env bash
    npx -y copilot-api@latest start --port 15432 {{PARAMS}} # --verbose

# Show Claude project automation usage.
cpa-usage:
    open "https://ericc-ch.github.io/copilot-api/?endpoint=http://localhost:15432/usage"
    # see also
    # - Metered usage: https://github.com/settings/billing
    # - Model multipliers: https://docs.github.com/en/copilot/concepts/copilot-billing/understanding-and-managing-requests-in-copilot#model-multipliers

# works only for Ubuntu
#
# Install Cortex desktop package on Linux.
[linux]
prep-cortex:
    #!/usr/bin/env bash
    curl -L https://app.cortexcpp.com/download/latest/linux-amd64-local -o cortex.deb
    sudo dpkg -i cortex.deb
    # fix broken dependencies
    sudo apt-get install -f -y

# Run the qwen coder model in Cortex.
prep-coder:
    # cortex pull bartowski/DeepSeek-V2.5-GGUF
    cortex run qwen2.5-coder

# Render a Markdown file.
md FILE:
    uvx markitdown "{{FILE}}"

# Convert a PDF to text.
p2t FILE:
    uvx --python 3.12 --from 'pix2text[multilingual]' p2t predict --device mps --file-type pdf -i "{{FILE}}"

# Install Pix2Text OCR dependencies.
prep-p2t:
    #!/usr/bin/env bash
    set -e
    # if the directory not exits
    if [ ! -d ~/.pix2text-mac ]; then
        git clone https://github.com/breezedeus/Pix2Text-Mac ~/.pix2text-mac
    fi
    cd ~/.pix2text-mac
    uv venv --python 3.12 --seed
    source ~/.pix2text/.venv/bin/activate
    pip install -r requirements.txt
    pip install pix2text[multilingual]>=1.1.0.1
    python setup.py py2app -A

# https://github.com/Byaidu/PDFMathTranslate
#
# Start pdf2zh interactive translation.
pzh:
    uvx pdf2zh -i

# Install Ollama.
prep-om:
    which ollama || brew install ollama

# Start the Ollama server.
om:
    ollama serve

DS_MODEL := "deepseek-r1:7b"
# DS_MODEL := "deepseek-r1:14b"
# DS_MODEL := "deepseek-r1:32b"
#
# Run the configured DeepSeek Ollama model.
ds:
    ollama run {{DS_MODEL}}

# Install gollama.
prep-gom:
    which gollama || go install github.com/sammcj/gollama@HEAD

# Link gollama configuration.
gom-link: prep-gom
    #!/usr/bin/env bash
    gollama -link-lmstudio --dry-run
    read -n 1 -p "Confirm linking LMStudio models to ollama (y/n)? " REPLY && echo && [[ $REPLY =~ ^[Yy]$ ]] && gollama -link-lmstudio
    gollama -L --dry-run
    read -n 1 -p "Confirm linking ollma models to LMStudio (y/n)? " REPLY && echo && [[ $REPLY =~ ^[Yy]$ ]] && gollama -L

# Clean up gollama model links.
gom-reset:
    gollama -cleanup


# https://github.com/jundot/omlx
#
# Clone and sync the omlx Open WebUI launcher.
prep-ox:
    #!/usr/bin/env bash
    if [ ! -d ~/projects/omlx ]; then
        git clone https://github.com/jundot/omlx.git ~/projects/omlx
    else
        (cd ~/projects/omlx && git pull)
    fi
    cd ~/projects/omlx && uv sync

# Serve omlx for a named Lume VM.
ox-vm VM:
    #!/usr/bin/env bash
    VM_IP=$(lume ls | grep {{VM}} | grep -oE '192\.[0-9]+\.[0-9]+\.[0-9]+')
    HOST_IP=$(echo $VM_IP | sed 's/\.[0-9]*$/.1/')
    echo "Admin UI: http://$HOST_IP:8000/admin"
    cd ~/projects/omlx && source .venv/bin/activate && omlx serve --host $HOST_IP

# Launch Open WebUI through omlx.
ox4 *ARGS:
    env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy omlx launch {{ARGS}}

# Install rapid-mlx.
prep-rx:
    brew install raullenchai/rapid-mlx/rapid-mlx

# Install dflash-mlx.
prep-dx:
    uv tool install dflash-mlx

# VISUAL_MODEL := "llama3.2-vision"
# VISUAL_MODEL := "minicpm-v"
#
VISUAL_MODEL := "erwan2/DeepSeek-Janus-Pro-7B"

# Run the configured vision model in Ollama.
lv:
    ollama run {{VISUAL_MODEL}}

# Point to exo source installation instructions.
prep-exo:
    # 1. we need uv venv --python 3.12 --seed
    # 2. we need to install exo from source
    echo "visit https://github.com/exo-explore/exo?tab=readme-ov-file#from-source"
    # 3. we need to manually install pytorch in the venv
    # 4. when in doubt, run: DEBUG=9 exo --disable-tui

# Install Buzz transcription app.
prep-tr:
    brew install --cask buzz

# just gs start -s SERVER_IP --token TOKEN
# TOKEN is retrieved on server via:
# cat /var/lib/gpustack/token
#
# Run the GPUStack CLI.
gs *PARAMS:
    #!/usr/bin/env bash
    uvx --python 3.12 --from 'gpustack[all]' gpustack {{PARAMS}}

# Install Plandex and patch its local startup script.
prep-pl:
    #!/usr/bin/env bash
    which plandex || (curl -sL https://plandex.ai/install.sh | bash)
    just clone plandex-ai plandex
    cd ~/projects/plandex/app
    sd 'docker compose' 'docker-compose' start_local.sh
    ./start_local.sh

# Open Plandex in semi-autonomous mode for a project.
pl PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    plandex --semi

# Install SGLang and CUDA kernel packages.
prep-sg:
    #!/usr/bin/env bash
    # https://docs.sglang.ai/start/install.html
    uv pip install sgl-kernel --force-reinstall --no-deps
    uv pip install "sglang[all]>=0.4.3.post2" --find-links https://flashinfer.ai/whl/cu124/torch2.5/flashinfer-python

# Install the llm-mlx plugin.
prep-mlx:
    #!/usr/bin/env bash
    # https://kconner.com/2025/02/17/running-local-llms-with-mlx.html
    # https://simonwillison.net/2025/Feb/15/llm-mlx/
    uvx llm install llm-mlx

# Models are downloaded to ~/.cache/huggingface/hub/
# See https://github.com/simonw/llm-mlx?tab=readme-ov-file#models-to-try for models to try

# just mlx download-model MODEL
# just mlx models
# just mlx import-models
#
# Run the llm-mlx plugin command.
mlx *PARAMS:
    #!/usr/bin/env bash
    uvx llm mlx {{PARAMS}}

# Note: just llm doesn't work for passing quoted strings
# Use the shell alias instead
# llm models default mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# llm chat -m MODEL
# llm plugins
# llm -f github:simonw/s3-credentials 'Suggest new features for this tool'
# llm -f docs: "How do I embed a binary file?"
# llm *PARAMS:
#     uvx llm {{PARAMS}}
#
# Install llm plugins for docs, GitHub fragments, and MLX.
prep-llm:
    uvx llm install llm-docs
    uvx llm install llm-fragments-github
    uvx llm install llm-mlx

# Render llm model config and set its API key.
sync-llm:
    #!/usr/bin/env bash
    dir_llm=`dirname "$(uvx llm logs path)"`
    tools/config/render_yaml.py dotfiles/.config/llm/extra-openai-models.yaml.in $dir_llm/extra-openai-models.yaml
    cat $dir_llm/extra-openai-models.yaml
    uvx llm keys set env_key --value ${OPENAI_API_KEY}
    uvx llm models default env

# dir-llm:
#     uv run --with 'llm' python -c 'import llm; print(llm.user_dir())'

# lms comes with LMStudio: https://github.com/lmstudio-ai/lms
# I want it for https://github.com/lmstudio-ai/mlx-engine
#
# Install LM Studio CLI.
prep-lms:
    #!/usr/bin/env bash
    npx lmstudio install-cli

# lms get mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# open ~/.cache/lm-studio
# lms load mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
# lms server start
#
# Run the LM Studio CLI.
lms *PARAMS:
    #!/usr/bin/env bash
    lms {{PARAMS}}

# Start the MLX OmniParser server.
omni *PARAMS:
    #!/usr/bin/env bash
    uvx mlx-omni-server {{PARAMS}}

# Run the local LLM performance script.
perf *PARAMS:
    # run llm_perf.py using uv with package requests installed
    uv run --with requests llm_perf.py {{PARAMS}}

# ~/.cache/lm-studio/models/
VLM_MODEL := env("VLM_MODEL", "mlx-community/Qwen2.5-VL-3B-Instruct-4bit")
VLM_PROMPT := env("VLM_PROMPT", "describe the image as detailed as possible")

# Describe an image with mlx-vlm.
vlm IMAGE *PARAMS=" --max-tokens 100 ":
    #!/usr/bin/env bash
    uv run --python 3.12 --with 'mlx-vlm' --with torch python -m mlx_vlm.generate --model '{{VLM_MODEL}}' --prompt '{{VLM_PROMPT}}' --image {{IMAGE}} {{PARAMS}}

# Start Lobe Chat with Docker and OpenAI env vars.
lobe *PARAMS:
    #!/usr/bin/env bash
    docker run -it --rm -p 3210:3210 \
      -e OPENAI_API_KEY={{env('OPENAI_API_KEY')}} \
      -e OPENAI_PROXY_URL={{env('OPENAI_API_BASE')}} \
      -e ACCESS_CODE=lobe66 \
      --name lobe-chat \
      lobehub/lobe-chat

# Not working
#
# Install ScreenPipe CLI.
prep-scr:
    curl -fsSL get.screenpi.pe/cli | sh

# prep-rd:
#     #!/usr/bin/env bash
#     which ra-aid || (brew tap ai-christianson/homebrew-ra-aid && brew install ra-aid)

# -m Hi
# --chat
# --use-aider
#
# Run ra-aid in a project.
rd PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    OPENAI_API_MODEL=${OPENAI_API_MODEL:-"claude-3.5-sonnet"}
    uvx --python 3.12 ra-aid --model $OPENAI_API_MODEL {{PARAMS}}

# Not working yet
#
# Start the DeTikZify web UI.
dt:
    uv run --python 3.11 --with 'detikzify @ git+https://github.com/potamides/DeTikZify' -m detikzify.webui --light

# Show Khoj local startup help with Metal enabled.
kj:
    #!/usr/bin/env bash
    CMAKE_ARGS="-DGGML_METAL=on" USE_EMBEDDED_DB="true" uvx --from 'khoj[local]' khoj --help

# --output .
# --enrich-code
# --enrich-formula
# --enrich-picture-classes
# --enrich-picture-description
# --image-export-mode [placeholder|embedded|referenced]
#
# Download model or LLM assets.
dl *PARAMS:
    uvx --with mlx-vlm docling {{PARAMS}}

# DOC could be a local file or an URL
#
# Download Markdown documentation.
dlmd DOC:
    just dl --pipeline vlm --vlm-model smoldocling {{DOC}}

# Install Probe and probe-chat.
prep-probe:
    which probe || npm install -g @buger/probe@latest
    which probe-chat || npm install -g @buger/probe-chat@latest

# in `just zsh`, --allow-edit
# --web
#
# Run probe-chat with OpenAI-compatible env vars.
probe *PARAMS="":
    #!/usr/bin/env bash
    export OPENAI_API_URL=$OPENAI_API_BASE
    export MODEL_NAME=$OPENAI_API_MODEL
    probe-chat {{PARAMS}}

# Clone DeepWiki Open and write its env file.
prep-dw:
    #!/usr/bin/env bash
    just clone AsyncFuncAI deepwiki-open
    cd ~/projects/deepwiki-open
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" > .env
    echo "OPENAI_API_URL=$OPENAI_API_BASE" >> .env
    mkdir -p ~/.adalflow
    # https://github.com/AsyncFuncAI/deepwiki-open/issues/20#issuecomment-2857485755

# Start DeepWiki Open with Docker Compose.
dw: prep-dw
    #!/usr/bin/env bash
    cd ~/projects/deepwiki-open
    docker-compose up

# Not working yet
#
# Clone and build OpenDeepWiki.
prep-odw:
    #!/usr/bin/env bash
    just clone AIDotNet OpenDeepWiki
    cd ~/projects/OpenDeepWiki
    make build

# Install Goose CLI.
prep-goose:
    #!/usr/bin/env bash
    # mkdir -p ~/.config/goose
    # cp -f dotfiles/.config/goose/config.yaml ~/.config/goose/config.yaml
    which goose || (curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash)

# goose info
# goose configure
# MEMORY_BANK_ROOT="$HOME/.membank" goose session
#
# Run Goose with the requested subcommand.
goose *PARAMS="session":
    #!/usr/bin/env bash
    goose {{PARAMS}}

# Install the MCP toolkit.
kit-mcp:
    uv run --python 3.11 --with cased-kit python -m kit.mcp

# Not working
# https://github.com/conikeec/mcp-probe/tree/master
# prep-mcp-probe:
#     which mcp-probe || cargo install mcp-cli # brew install conikeec/tap/mcp-probe

# Choose other model
# Put the following in the box below
# base_url=https://some_api_base/v1
# api_key=YOUR_API_KEY
# see https://github.com/frdel/agent-zero/issues/326#issuecomment-2679344132
#
# Start Agent Zero in Docker.
zero:
    docker pull frdel/agent-zero-run
    docker run --rm -p 50001:80 frdel/agent-zero-run

# Install Claude Code and write permissive settings.
prep-cc:
    #!/usr/bin/env bash
    which claude || npm install -g @anthropic-ai/claude-code
    mkdir -p ~/.claude
    # https://docs.anthropic.com/en/docs/claude-code/settings
    cat > ~/.claude/settings.json << EOF
    {
      "permissions": {
        "allow": [
          "Bash(sg:*)",
          "Bash(rg:*)",
          "Bash(jj:*)",
          "Bash(backlog:*)",
          "WebFetch",
          "WebSearch",
          "Edit",
          "MultiEdit",
          "mcp__container-use__environment_checkpoint",
          "mcp__container-use__environment_file_delete",
          "mcp__container-use__environment_file_list",
          "mcp__container-use__environment_file_read",
          "mcp__container-use__environment_file_write",
          "mcp__container-use__environment_open",
          "mcp__container-use__environment_run_cmd",
          "mcp__container-use__environment_update"
        ],
        "deny": [
            "Read(.env)"
        ]
      }
    }
    EOF

# Install Claude Code Router and write provider config.
prep-ccr:
    #!/usr/bin/env bash
    which ccr || npm install -g @musistudio/claude-code-router
    mkdir -p ~/.claude-code-router
    cat > ~/.claude-code-router/config.json << EOF
    {
        "LOG": true,
        "Providers": [
            {
                "name": "local",
                "api_base_url": "${OPENAI_API_BASE}/chat/completions",
                "api_key": "$OPENAI_API_KEY",
                "models": [
                    "$OPENAI_API_MODEL"
                ]
            }
        ],
        "Router": {
            "default": "local"
        }
    }
    EOF

# Remove all Claude Code MCP servers.
cc-mcp-reset:
    claude mcp list|grep -v -F 'No MCP servers'|awk -F":" '{print $1}'|xargs -n 1 claude mcp remove

# Prepare Claude Code MCP servers for a project.
prep-cc-mcp PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    just cc-mcp-reset
    # Add MCP servers from goose config
    claude mcp add --transport stdio playwright-mcp -- npx -y @executeautomation/playwright-mcp-server
    # claude mcp add --transport stdio memory-mcp -- npx -y @modelcontextprotocol/server-memory
    # claude mcp add --transport stdio sequential-thinking-mcp -- npx -y @modelcontextprotocol/server-sequential-thinking
    claude mcp add --transport stdio ddg-mcp -- uvx ddg-mcp
    claude mcp add --transport stdio probe-mcp -- npx -y @buger/probe-mcp
    # it works but I need to figure out how to actually use it
    # claude mcp add --transport stdio zls-mcp -- npx tritlo/lsp-mcp zig `which zls`
    # claude mcp add --transport stdio speech-mcp -- uvx speech-mcp
    # claude mcp add --transport stdio kit-mcp -- uv run --python 3.11 --with cased-kit python -m kit.mcp
    # claude mcp add --transport stdio deepwiki-mcp -e DEEPWIKI_REQUEST_TIMEOUT=60000 -- npx -y mcp-deepwiki@latest
    # claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant # --project $(pwd)

# Install container-use CLI.
prep-cu:
    which container-use || brew install dagger/tap/container-use || ( curl -fsSL https://raw.githubusercontent.com/dagger/container-use/main/install.sh | bash )

# Register container-use as a Claude Code MCP server.
prep-cc-cu:
    #!/usr/bin/env bash
    claude mcp add --scope user container-use -- `which cu` stdio
    # curl https://raw.githubusercontent.com/dagger/container-use/main/rules/agent.md >> CLAUDE.md
    # claude --allowedTools mcp__container-use__environment_checkpoint,mcp__container-use__environment_file_delete,mcp__container-use__environment_file_list,mcp__container-use__environment_file_read,mcp__container-use__environment_file_write,mcp__container-use__environment_open,mcp__container-use__environment_run_cmd,mcp__container-use__environment_update

# just cc forest --debug
#
# Open Claude Code Router in a project.
ccr PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    ccr code {{PARAMS}}

# When running out of premium quota
# export ANTHROPIC_BASE_URL=http://localhost:15432 ANTHROPIC_AUTH_TOKEN=dummy ANTHROPIC_MODEL=gpt-4.1 ANTHROPIC_SMALL_FAST_MODEL=gpt-4.1 && claude
#
# Open Claude Code with OpenAI-compatible Anthropic env vars.
cc PROJ="forest" *PARAMS="":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    export ANTHROPIC_BASE_URL=$OPENAI_API_BASE ANTHROPIC_AUTH_TOKEN=$OPENAI_API_KEY ANTHROPIC_MODEL=$OPENAI_API_MODEL ANTHROPIC_SMALL_FAST_MODEL=$OPENAI_API_MODEL_FAST && claude

# Install the OpenAI Codex CLI.
prep-codex:
    bun add -g @openai/codex

# Run Codex CLI against the configured local provider.
codex *PARAMS:
    #!/usr/bin/env bash
    export LOCAL_API_KEY=$OPENAI_API_KEY
    export LOCAL_BASE_URL=$OPENAI_API_BASE
    codex -a auto-edit --provider LOCAL --model $OPENAI_API_MODEL {{PARAMS}}

# build failed: FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
#
# Build the Easy Dataset Docker image.
prep-easyds:
    #!/usr/bin/env bash
    just clone ConardLi easy-dataset
    cd ~/projects/easy-dataset
    docker build -t easy-dataset .

# Start Easy Dataset with a persisted local database.
easyds:
    #!/usr/bin/env bash
    mkdir -p ~/.easy-dataset
    docker run --rm -p 1717:1717 -v ~/.easy-dataset:/app/local-db --name easy-dataset easy-dataset

# tutorial intro
# https://docs.marimo.io/guides/package_management/inlining_dependencies/
#
# Open Marimo with the requested arguments.
mm *PARAMS="edit --sandbox":
    uvx marimo {{PARAMS}}

# dspy
# funnydspy
# math-equivalence==0.0.0 (from git+https://github.com/hendrycks/math.git@357963a7f5501a6c1708cf3f3fb0cdf525642761)

# Install Sourcegraph Amp and start login.
prep-amp:
    which amp || npm install -g @sourcegraph/amp
    # login, say no to re-login if already logged in
    yes n|amp login

# Install bubblewrap sandboxing tool.
prep-bwrap:
    which bwrap || brew install bubblewrap

# Install Claude Code CLI with bun.
prep-claude:
    bun add -g @anthropic-ai/claude-code

# Install Gemini CLI with bun.
prep-gemini:
    bun add -g @google/gemini-cli

# Install OpenCode CLI.
prep-oc:
    bun add -g opencode-ai
    # mkdir -p ~/.config/opencode
    # tools/config/render_yaml.py --json dotfiles/.config/opencode/opencode.in.yaml ~/.config/opencode/opencode.json
    # just check-oc

# Install pi coding agent.
prep-pi:
    bun add -g @earendil-works/pi-coding-agent

# AGENT-NOTE: Delegates to improved link-conf which handles re-entry safely
# (rips symlinks, backs up real files with timestamp suffix).
#
# Configure OpenCode for DeepSeek V4 Pro high reasoning.
prep-oc-ds4: prep-oc
    just link-conf opencode/opencode-ds4.json opencode/opencode.json
    echo "Configured opencode to use DeepSeek V4 Pro (reasoningEffort: high)"
    echo "!!! Run 'opencode auth login' to authenticate !!!"

# AGENT-NOTE: Live pi settings are per-device and gitignored
# (dotfiles/.config/pi/settings*.json); only the settings-ds4.in.json template
# is tracked. This task bootstraps the per-device file from the template on a
# new machine, then symlinks it into ~/.pi/agent/ (rips symlinks, backs up real
# files) so pi's runtime updates (model, changelog, packages) stay local and
# never get committed. Secrets live in auth.json/models.json, never here.
#
# Configure pi for DeepSeek V4 Pro high thinking.
prep-pi-ds4: prep-pi
    #!/usr/bin/env bash
    set -e
    SRC="{{justfile_directory()}}/dotfiles/.config/pi/settings-ds4.json"
    TEMPLATE="{{justfile_directory()}}/dotfiles/.config/pi/settings-ds4.in.json"
    TARGET="$HOME/.pi/agent/settings.json"
    mkdir -p "$(dirname "$TARGET")"
    # Deploy the railscasts theme (referenced by settings-ds4.in.json) so a
    # fresh machine never points at a missing theme.
    THEME_SRC="{{justfile_directory()}}/dotfiles/.config/pi/themes/railscasts.json"
    THEME_TARGET="$HOME/.pi/agent/themes/railscasts.json"
    mkdir -p "$(dirname "$THEME_TARGET")"
    cp -f "$THEME_SRC" "$THEME_TARGET"
    echo "Deployed pi theme: railscasts"
    # Bootstrap the per-device settings file from the tracked template if absent.
    if [ ! -f "$SRC" ]; then
        cp "$TEMPLATE" "$SRC"
        echo "Bootstrapped $SRC from template."
    fi
    if [ -L "$TARGET" ]; then
        rip "$TARGET"
    elif [ -e "$TARGET" ]; then
        TS=$(date +%Y%m%d-%H%M%S)
        cp "$TARGET" "$TARGET.$TS.bak"
        rip "$TARGET"
        echo "Backed up existing settings to settings.json.$TS.bak"
    fi
    ln -s "$SRC" "$TARGET"
    echo "Configured pi to use DeepSeek V4 Pro (thinking: high)"
    # Install the Lean grammar from npm (NOT vendored) and deploy the node
    # preload hook that registers it into pi's highlight.js. highlightjs-lean
    # 1.0.0 is the factory form, compatible with hljs 10.x/11.x — survives pi
    # updates (pi pins highlight.js 10.7.3) with no compat breaks.
    bun add -g highlightjs-lean@1.0.0
    mkdir -p "$HOME/.pi/agent"
    cp -f "{{justfile_directory()}}/dotfiles/.config/pi/lean-highlight-preload.cjs" \
        "$HOME/.pi/agent/lean-highlight-preload.cjs"
    echo "Deployed lean-highlight preload: $HOME/.pi/agent/lean-highlight-preload.cjs"
    # Deploy the show_image extension (display an image file inline in the
    # TUI for the human; returns a { type: "image" } content block).
    EXT_SRC="{{justfile_directory()}}/dotfiles/.config/pi/extensions/show-image"
    EXT_TARGET="$HOME/.pi/agent/extensions/show-image"
    mkdir -p "$(dirname "$EXT_TARGET")"
    cp -rf "$EXT_SRC" "$EXT_TARGET"
    echo "Deployed pi extension: show-image"
    echo "!!! NODE_OPTIONS=--require=\$HOME/.pi/agent/lean-highlight-preload.cjs must be in the shell env (~/.envrc) and cc-connect env for spawned pi !!!"
    echo "!!! Run 'pi' then type '/login' and select DeepSeek to authenticate !!!"

# Check OpenCode setup.
check-oc:
    #!/usr/bin/env bash
    set -e
    cat ~/.config/opencode/opencode.json
    opencode auth list
    # opencode auth list|grep ${OPENAI_API_PROVIDER:-GitHub Copilot}
    opencode run -m "${OPENAI_API_PROVIDER:-github-copilot}/${OPENAI_API_MODEL:-claude-sonnet-4}" --log-level DEBUG --print-logs Hi

# use `opencode auth login` to log into Github Copilot
# use `opencode run -m github-copilot/claude-3.5-sonnet --print-logs Hi` for a first run, which runs bun install that might take a while

# Clone OpenCode sources.
clone-oc:
    just clone sst opencode

# Install agenttrace.
prep-at:
    which agenttrace || go install github.com/luoyuctl/agenttrace/cmd/agenttrace@latest

# Install DeepSeek TUI.
prep-ds:
    bun add -g deepseek-tui

# Install uzi coding agent.
prep-uz:
    which uzi || go install github.com/devflowinc/uzi@latest

# Install Amazon Q CLI and command symlinks.
@prep-q:
    which q || brew install amazon-q
    which q || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/q" /usr/local/bin/q
    which qchat || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/qchat" /usr/local/bin/qchat
    which qterm || sudo ln -s "/Applications/Amazon Q.app/Contents/MacOS/qterm" /usr/local/bin/qterm
    echo "MCP config command: q mcp"
    echo "MCP config file: $HOME/.aws/amazonq/mcp.json"
    echo "Login first: q login"
    echo "Then chat: q chat"

# Seed Amazon Q project context from AGENTS.md.
init-q PROJ="forest":
    #!/usr/bin/env bash
    cd ~/projects/{{PROJ}}
    q chat --no-interactive "/context add AGENTS.md"
    # q chat --no-interactive '/hooks add --trigger per_prompt --command "cat AGENTS.md" AGENTS.md'

# Start Amazon Q chat with trusted file tools.
q:
    q chat --trust-tools=fs_read,fs_write "ALWAYS follow AGENTS.md"

# Install Kiro CLI.
prep-kiro:
    which kiro-cli || brew install kiro-cli

# Install Tencent CodeBuddy CLI with bun.
prep-cbc:
    bun add -g @tencent-ai/codebuddy-code

# requires too many permissions to my GitHub account, rejected
#
# Launch vibe-kanban through npx.
prep-kb:
    npx -y vibe-kanban

# backlog init <project name>
# backlog browser
#
# Install backlog.md CLI.
prep-backlog:
    bun i -g backlog.md

# List backlog TODOs.
todos:
    backlog browser # --no-open
