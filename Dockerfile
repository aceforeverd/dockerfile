ARG _USER=ace
ARG _PASSWD=helloworld

FROM debian:stable
ARG _USER
ARG _PASSWD

RUN apt update && apt full-upgrade -y \
    && apt install -y build-essential git bash-completion fish zsh tmux vim sudo \
        curl wget lsb-release software-properties-common \
        apt-transport-https ca-certificates universal-ctags global locales \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python-openssl \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# llvm toolchain
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" && apt clean

COPY --chown=root:root etc/apt/sources.list /etc/apt/sources.list

COPY new_user.sh .
RUN ./new_user.sh "$_USER" "$_PASSWD" && rm new_user.sh

RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz \
    && tar xvf nvim-linux64.tar.gz \
    && cd nvim-linux64 \
    && find . -type f -exec install -D -m 755 {} /usr/local/{} \; \
    && rm -rf nvim*

USER $_USER
WORKDIR /home/$_USER

# dotfiles
RUN git clone https://github.com/aceforeverd/dotfiles.git .dotfiles \
        && .dotfiles/setup.sh \
        && /usr/bin/fish -c 'echo setup fisher'

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
RUN /bin/bash -c 'source $HOME/.nvm/nvm.sh && nvm install lts/erbium && npm install -g neovim typescript yarn'

# pyenv and pynvim
RUN  git clone https://github.com/pyenv/pyenv.git ~/.pyenv \
     && fish -c "addpaths ~/.pyenv/bin; set -Ux PYENV_ROOT ~/.pyenv; echo 'pyenv init - | source' > ~/.config/fish/config.fish; pyenv install 3.9.0" \
     && fish -c "python3 -m pip install --upgrade pip; pip3 install --upgrade pynvim msgpack"

# rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly  -c rust-analysis rust-src
RUN /usr/bin/fish -c 'addpaths ~/.cargo/bin && rustup completions fish > ~/.config/fish/completions/rustup.fish'

# go

# vimrc
RUN mkdir -p "$HOME/.config/nvim" \
    && git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim" \
    && /bin/bash "$HOME/.config/nvim/scripts/setup.sh"

ENTRYPOINT ["/usr/bin/fish"]
