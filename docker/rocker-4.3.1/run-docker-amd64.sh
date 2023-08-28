# run docker image in background
docker container run --rm -d \
    --memory=24g \
    --cpus=5 \
    --platform linux/amd64 \
    --name rstudio_431_amd64 \
    -p 8787:8787 \
    -e DISABLE_AUTH=true \
    --volume "/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/":/home/rstudio \
    rstudio-docker-amd64:4.3.1

# --volume /Users/fernando/Dropbox/MBA/Proyectos_R/Tesis/Delitos_en_Caba_v4_amd64:/home/rstudio/Delitos_en_Caba_v4_amd64 \