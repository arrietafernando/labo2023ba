#
docker run --rm \
    -p 127.0.0.1:8787:8787 \
    -e DISABLE_AUTH=true \
    rstudio-docker:4.3.1

