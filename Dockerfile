FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.5.0 AS xx

FROM --platform=$BUILDPLATFORM golang:1.24-alpine3.21 AS builder

COPY --from=xx / /

ARG TARGETPLATFORM

RUN xx-info env

ENV CGO_ENABLED=0

ENV XX_VERIFY_STATIC=1

WORKDIR /app

COPY . .

RUN xx-go build && \
    xx-verify filebrowser


FROM alpine:3.21


COPY --from=builder --chown=onesim:netadmin /app/healthcheck.sh /healthcheck.sh

# Install docker CLI dependencies
RUN chmod +x /healthcheck.sh && \
    apk --no-cache add \
        docker-cli \
        ca-certificates \
        mailcap \
        curl \
        jq \
        shadow && \
    addgroup -S netadmin && \
    adduser -S -G netadmin -G wheel onesim && \
    chown -R onesim:netadmin /srv && \
    echo "✅ User 'onesim' added to groups: netadmin, wheel, and /app chowned"



HEALTHCHECK --start-period=2s --interval=5s --timeout=3s \
    CMD /healthcheck.sh || exit 1

VOLUME /srv
EXPOSE 80

COPY --from=builder --chown=onesim:netadmin /app/docker_config.json /.filebrowser.json
COPY --from=builder --chown=onesim:netadmin /app/filebrowser /filebrowser

USER onesim

ENTRYPOINT [ "/filebrowser" ]
