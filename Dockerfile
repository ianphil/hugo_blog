FROM fedora:29 as updated
LABEL co.ianp.se.author="Ian Philpot <ian.philpot@microsoft.com>"
LABEL co.ianp.se.name="updated"
RUN dnf update -y

FROM hugo:updated as setup
LABEL co.ianp.se.name="setup"
ENV HUGO_VERSION 0.52
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.tar.gz
RUN tar -zxvf /tmp/hugo.tar.gz -C /tmp

FROM hugo:updated as base
LABEL co.ianp.se.name="base"
COPY --from=setup /tmp/hugo /usr/bin
RUN chmod +x /usr/bin/hugo
WORKDIR /hugo/blog

FROM hugo:base as server
LABEL co.ianp.se.name="server"
EXPOSE 1313
ENTRYPOINT [ "hugo", "server", "-D", "-b", "http://localhost:1313", "--bind=0.0.0.0" ]

FROM hugo:base as builder
LABEL co.ianp.se.name="builder"
ENTRYPOINT [ "hugo" ]