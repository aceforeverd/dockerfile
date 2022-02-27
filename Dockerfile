ARG _USER=ace
ARG _PASSWD=helloworld

FROM debian:bullseye
ARG _USER
ARG _PASSWD

LABEL org.opencontainers.image.source https://github.com/aceforeverd/dockerfile

WORKDIR /
COPY new_user.sh .
# deps, llvm, locale, neovim
# hadolint ignore=DL3008
RUN apt-get update && apt-get full-upgrade -y \
    && apt-get install --no-install-recommends -y build-essential git bash-completion fish tmux vim sudo \
        curl wget lsb-release software-properties-common procps \
        apt-transport-https ca-certificates universal-ctags global locales gnupg \
        sqlite3 libsqlite3-dev cmake ninja-build gettext libtool-bin unzip m4 doxygen pkg-config autoconf automake\
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ./new_user.sh "$_USER" "$_PASSWD" && rm new_user.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY --chown=root:root etc/apt/sources.list /etc/apt/sources.list

# this add repository
# hadolint ignore=DL3047
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" && apt-get clean && rm -rf /var/lib/apt/lists/*

# install neovim nightly
RUN git clone https://github.com/neovim/neovim neovim \
    && make -C neovim install CMAKE_BUILD_TYPE=RelWithDebInfo

USER $_USER
WORKDIR /home/$_USER

# dotfiles, nvm, rust, vimrc
# hadolint ignore=DL4001,DL4006
RUN git clone https://github.com/aceforeverd/dotfiles.git .dotfiles \
    && .dotfiles/setup.sh \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && mkdir -p "$HOME/.ssh" \
    && curl -sL https://git.io/fisher --create-dir -o ~/.config/fish/functions/fisher.fish \
    && /usr/bin/fish -c 'fisher update' \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable -c rust-src \
    && /usr/bin/fish -c "fish_user_paths_add ~/.cargo/bin" \
    && /usr/bin/fish -c 'cargo install git-delta ripgrep code-minimap bat cargo-cache fd-find du-dust zoxide' \
    && /usr/bin/fish -c 'cargo cache -a' \
    && mkdir -p ~/.config/fish/completions \
    && /usr/bin/fish -c 'rustup completions fish > ~/.config/fish/completions/rustup.fish' \
    && git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim" \
    && /usr/bin/fish -c "nvm install lts/gallium;and npm install -g yarn" \
    && rm -rf "$HOME/.cache" "$HOME/.npm"

ENTRYPOINT ["/usr/bin/fish"]
