#!/bin/bash

# The path where the genome files and 
data_path='myvol'

# Run the docker image "biodepot/star-for-criu:latest" from DockerHub and execute the run_STAR.sh script inside the container
sudo docker run -d --name star -v $data_path:/data biodepot/star-for-criu:latest /bin/bash /home/run_STAR.sh

# Check the status of STAR alignment
sudo docker logs star


