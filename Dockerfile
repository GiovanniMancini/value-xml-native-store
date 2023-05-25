# Build BaseX docker image with customisation from folder basex
ARG JDK_IMAGE=eclipse-temurin:17-jre
ARG BASEX_VER=https://files.basex.org/releases/10.4/BaseX104.zip
ARG XSLT_PROC=https://github.com/Saxonica/Saxon-HE/raw/main/11/Java/SaxonHE11-5J.zip

FROM $JDK_IMAGE  AS builder
ARG BASEX_VER
ARG XSLT_PROC
RUN echo 'using Basex: ' "$BASEX_VER"
RUN apt-get update && apt-get install -y unzip wget
WORKDIR /srv
RUN wget "$BASEX_VER" && unzip *.zip && rm *.zip
RUN mkdir saxon && cd saxon
RUN wget "$XSLT_PROC"
RUN unzip *.zip && rm *.zip
RUN pwd
COPY basex/web.xml /srv/basex/webapp/WEB-INF

# Main image
FROM $JDK_IMAGE
ARG JDK_IMAGE
ARG BASEX_VER

RUN pwd

COPY --from=builder /srv/basex/ /srv/basex
COPY --from=builder /srv/saxon/saxon-he-11.5.jar /srv/basex/lib/custom
COPY --from=builder /srv/saxon/lib/* /srv/basex/lib/custom

RUN addgroup --gid 1000 basex 
RUN adduser --home /srv/basex/ --uid 1000 --gid 1000 basex 
RUN chown -R basex:basex /srv/basex

# Switch to 'basex'
USER basex

ENV PATH=$PATH:/srv/basex/bin
# JVM options e.g "-Xmx2048m "
ENV BASEX_JVM="--add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/jdk.internal.loader=ALL-UNNAMED"

# 1984/tcp: API
# 8080/tcp: HTTP
# 8081/tcp: HTTP stop
EXPOSE 1984 8080 8081

# no VOLUMEs defined
WORKDIR /srv

# Run BaseX HTTP server by default
CMD ["/srv/basex/bin/basexhttp"]

# LABEL org.opencontainers.image.source="https://github.com/Quodatum/basex-docker"
LABEL org.opencontainers.image.vendor="Fundify It"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL it.fundify.basex-docker.basex="${BASEX_VER}"
LABEL it.fundify.basex-docker.jdk="${JDK_IMAGE}"