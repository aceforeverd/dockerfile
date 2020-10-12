ARG _USER=ace
ARG _PASSWD=helloworld

FROM debian:buster
ARG _USER
ARG _PASSWD

RUN apt update && apt install -y apt-transport-https ca-certificates
COPY --chown=root:root etc/apt/sources.list /etc/apt/sources.list
RUN apt update && apt full-upgrade -y
RUN apt install -y build-essential git bash-completion fish zsh tmux vim neovim sudo \
    curl wget
RUN apt clean

COPY new_user.sh .
RUN /bin/bash new_user.sh "$_USER" "$_PASSWD"

USER $_USER
WORKDIR /home/$_USER

RUN git clone https://github.com/aceforeverd/dotfiles.git .dotfiles
RUN /bin/bash .dotfiles/setup.sh

RUN cat .dotfiles/.bashrc

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
RUN /bin/bash -c 'source $HOME/.nvm/nvm.sh && nvm install lts/erbium && npm install -g neovim typescript'

# rust

# go

# vimrc
RUN mkdir -p "$HOME/.config/nvim"
RUN git clone https://github.com/aceforeverd/vimrc.git "$HOME/.config/nvim"
RUN /bin/bash "$HOME/.config/nvim/scripts/setup.sh"

ENTRYPOINT ["/usr/bin/fish"]
