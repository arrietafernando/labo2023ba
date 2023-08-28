##################################################################################################################################################################
# Adapted from following:
# https://github.com/rpodcast/r_dev_projects/blob/main/.devcontainer/rstudio_docker/Dockerfile
#
##################################################################################################################################################################

##################################################################################################################################################################
# Adapted from following:
# - Rocker RStudio container using new versioned paradigm: https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/Dockerfile_rstudio_4.0.2
# - license: GPLV2
##################################################################################################################################################################

##################################################################################################################################################################
# For building image:
# docker build --pull --rm -f "rstudio-docker-tesis-v1/rocker-4.3.1/Dockerfile" \
#     -t rstudiodocker:latest "rstudio-docker-tesis-v1/rocker-4.3.1" \
#     --build-arg RSTUDIO_VERSION="2023.03.0-386" \
#     --no-cache --progress=plain 2>&1 | tee "rstudio-docker-tesis-v1/rocker-4.3.1/build.log"
##################################################################################################################################################################

FROM rocker/r-ver:4.3.1

ARG S6_VERSION
ARG RSTUDIO_VERSION
ARG QUARTO_VERSION

ENV S6_VERSION=$S6_VERSION
ENV RSTUDIO_VERSION=$RSTUDIO_VERSION
ENV PATH=/usr/lib/rstudio-server/bin:$PATH
ENV QUARTO_VERSION=$QUARTO_VERSION

# key dependencies for certain R packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends software-properties-common curl wget libssl-dev libxml2-dev libsodium-dev imagemagick libmagick++-dev libgit2-dev libssh2-1-dev zlib1g-dev librsvg2-dev libudunits2-dev libcurl4-openssl-dev python3-pip pandoc libzip-dev libfreetype6-dev libfontconfig1-dev tk libpq5 libxt6 openssh-client openssh-server \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh
RUN /rocker_scripts/install_verse.sh
RUN /rocker_scripts/install_tidyverse.sh
RUN /rocker_scripts/install_geospatial.sh

# install key dependencies of certain packages that could be installed later
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends libxml2-dev libsodium-dev libssl-dev imagemagick libmagick++-dev libgit2-dev libssh2-1-dev zlib1g-dev librsvg2-dev libudunits2-dev libfontconfig1-dev libfreetype6-dev curl 

RUN echo "RENV_PATHS_CACHE=/renv/cache" >> /usr/local/lib/R/etc/Renviron

# [Optional] Uncomment this section to add addtional system dependencies needed for project
# RUN apt-get update \
#     && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends ---packages list----

# [Optional] Uncomment this section to install additional R packages.
RUN install2.r --error --skipinstalled --ncpus -1 renv remotes \
    && rm -rf /tmp/downloaded_packages

# Additional r-packages for thesis
RUN install2.r --error --skipmissing --skipinstalled --ncpus -1 \
    openxlsx nasapower zoo tsibble ISOweek janitor ggsn skimr ids data.table osmdata tictoc \
    wesanderson h3jsr erer furrr future slider ggnewscale gridExtra ggpubr classInt calendR echarts4r

# R-INLA
RUN install2.r --error --skipmissing --skipinstalled --ncpus -1 \
    inlabru BiocManager && \
    R -e " BiocManager::install(c('graph', 'Rgraphviz'), dep=TRUE, update=FALSE) " && \
    sudo -u rstudio R -e  " install.packages('INLA', repos=c(getOption('repos'), INLA='https://inla.r-inla-download.org/R/testing'), dep=TRUE) " && \
    rm -rf /tmp/downloaded_packages

# --repos "https://inla.r-inla-download.org/R/testing" --repos getOption --deps TRUE \

#RUN  sudo -u rstudio R -e  " install.packages('INLA', repos=c(getOption('repos'), INLA='https://inla.r-inla-download.org/R/testing'), dep=TRUE) "
#RUN R -e " BiocManager::install(c('graph', 'Rgraphviz'), dep=TRUE, update=FALSE) "

EXPOSE 8787

CMD ["/init"]
