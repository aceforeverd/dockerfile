ARG _USER=ace
ARG _PASSWD=helloworld

FROM debian:stable
ARG _USER
ARG _PASSWD

LABEL org.opencontainers.image.source https://github.com/aceforeverd/dockerfile

COPY new_user.sh .
# deps, llvm, locale, neovim
RUN apt update && apt full-upgrade -y \
    && apt install -y build-essential git bash-completion fish zsh tmux vim sudo \
        curl wget lsb-release software-properties-common python-pip procps \
        apt-transport-https ca-certificates universal-ctags global locales \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python-openssl \
    && bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" && apt clean \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz \
    && tar xf nvim-linux64.tar.gz \
    && cd nvim-linux64 \
    && find . -type f -exec install -D -m 755 {} /usr/local/{} \; > /dev/null \
    && cd .. \
    && rm -rf nvim* \
    && ./new_user.sh "$_USER" "$_PASSWD" && rm new_user.sh \
    && wget https://www.python.org/ftp/python/3.9.1/Python-3.9.1.tgz \
    && tar xvf Python-3.9.1.tgz \
    && cd Python-3.9.1 && ./configure --enable-optimizations && make && make test && make install && cd .. && rm -rf Python-3.9.1*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY --chown=root:root etc/apt/sources.list /etc/apt/sources.list

USER $_USER
WORKDIR /home/$_USER

# dotfiles, nvm, python & pynvim, rust, vimrc
RUN git clone https://github.com/aceforeverd/dotfiles.git .dotfiles \
    && .dotfiles/setup.sh \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash \
    && mkdir -p "$HOME/.ssh" \
    && curl -sL https://git.io/fisher --create-dir -o ~/.config/fish/functions/fisher.fish \
    && /usr/bin/fish -c "fisher update; /usr/local/bin/python3.9 -m pip install -U --user pip pynvim msgpack" \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly -c rust-src \
    && /usr/bin/fish -c "fish_user_paths_add $HOME/.cargo/bin; and mkdir -p $HOME/.config/fish/completions; and rustup completions fish > $HOME/.config/fish/completions/rustup.fish" \
    && git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim" \
    && /usr/bin/fish -c "nvm install lts/fermium;and npm install -g neovim typescript yarn; and $HOME/.config/nvim/scripts/setup.sh"

ENTRYPOINT ["/usr/bin/fish"]
