#
docker build --pull --rm -f "rstudio-docker-tesis-v1/rocker-4.3.1/Dockerfile" \
    -t rstudio-docker:4.3.1 "rstudio-docker-tesis-v1/rocker-4.3.1" \
    --build-arg RSTUDIO_VERSION="2023.03.0-386" \
    --no-cache \
    --progress=plain 2>&1 | tee "rstudio-docker-tesis-v1/rocker-4.3.1/build.log"
