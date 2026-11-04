# Admin web payload

Copy the `client/apps/admin_app/build/web/` output into this directory for the
production Nginx container. The directory is mounted read-only at
`/usr/share/nginx/html`; it is not the storage root and must never contain
evidence, guide images or report PDFs.
