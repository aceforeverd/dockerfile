ARG _USER=ace
ARG _PASSWD=helloworld

FROM debian:13
ARG _USER
ARG _PASSWD

LABEL org.opencontainers.image.source https://github.com/aceforeverd/dockerfile

WORKDIR /
COPY bootstrap-debian.sh .

RUN bash ./bootstrap-debian.sh --os --new-user "$_USER" "$_PASSWD" \
    && rm -rf /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

USER $_USER
WORKDIR /home/$_USER

RUN bash /bootstrap-debian.sh --home

USER root
RUN rm -f /bootstrap-debian.sh
USER $_USER

ENTRYPOINT ["/usr/bin/fish"]
