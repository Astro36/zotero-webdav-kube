FROM alpine:3.21

RUN apk add --no-cache rclone

EXPOSE 8080

ENTRYPOINT ["sh", "-c", \
    "rclone serve webdav /data/zotero \
    --addr 0.0.0.0:8080 \
    --baseurl \"zotero-webdav/${WEBDAV_USER:-zotero}/zotero\" \
    --user \"${WEBDAV_USER:-zotero}\" \
    --pass \"${WEBDAV_PASSWORD:-zotero}\" \
    --vfs-cache-mode \"${WEBDAV_VFS_CACHE_MODE:-full}\""]
