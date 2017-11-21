# Hot-starting software container for STAR Alignment

This project presents a hot-starting method for STAR Alignment. This approach is to use CRUI (Checkpoint Restore in Userspace) tool to freeze the running container which has the genome indics in the share memory as a collection of files on disk. These checkpoint files are used to restore the hot-start container for STAR mapping step.

### Prerequisites

- 64-bit Ubuntu 16.04 Server (Linux kernel v3.11 or newer is required)
- Docker (Docker API version 1.25 or newer required for running CRIU in experimental mode)
- CRIU
- Physical machine or virtual machine with at least 32 GB memery available

### Installing

- Installing Docker on Ubuntu 16.04
  1. First, add the GPG key for the official Docker repository to the system:
  ```
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  ```

  2. Add the Docker repository to APT sources:
  ```
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  ```

  3. update the package database with the Docker packages from the newly added repo:
  ```
  sudo apt-get update
  ```
  4. install Docker CE:
  ```
  sudo apt-get install -y docker-ce
  ```
  5. check whether Docker is running
  ```
  sudo systemctl status docker
  ```
    If the status of Docker deamon shows "**active (running)**", it means Docker is installed correctly. 

- Install CRIU
  1. Get the CRIU repository from Github:
  ```
  git clone https://github.com/xemul/criu
  ```
  2. Install packages for compiler and C library:
  ```
  sudo apt-get install build-essential libc6-dev-i386 gcc-multilib
  ```
  3. Install packages for protocol buffers: (CRIU use Google Protocol Buffers to read and write image)
  ```
  sudo apt-get install libprotobuf-dev, libprotobuf-c0-dev, protobuf-c-compiler,protobuf-compiler,python-protobuf,libnet1-dev,pkg-config,libnl-3-dev,python-ipaddr,libbsd,libcap-dev,libaio-dev,python-yaml
  ```
  4. Install other packages that are needed for CRIU:
  ```
  sudo apt-get install --no-install-recommends git build-essential libprotobuf-dev libprotobuf-c0-dev protobuf-c-compiler protobuf-compiler python-protobuf libnl-3-dev libpth-dev pkg-config libcap-dev asciidoc xmlto libnet-dev
  ```
  5. Install two packages to make install-man work
  ```
  sudo apt-get install asciidoc xmlto
  ```
  6. Building CRIU tool, Enter criu directory and run: 
  ```
  sudo make
  ```
  7. Install CRIU, run:
  ```
  sudo make install
  ```
  8. Check whether it works well, it should say "Looks OK" if it is installed correctly. 
  ```
  criu check
  ```
  9. Enable docker experimental mode so that we can use **"docker checkpoint"** subcommand:
  ```
  sudo echo "{\"experimental\": true}" >> /etc/docker/daemon.json
  sudo systemctl restart docker
  ```

## Approach 

There are three main steps for this hot-starting methond: generating genome indices, checkpointing container, restoring container and STAR Alignment using restored container. 
- Generating genome indices
  1. Put genome files and RNA-Seq files (FASTQ files) in the same directory, such as: /data. <br/>
  2. Run the docker image _**"biodepot/star-for-criu:latest"**_ from DockerHub and execute the run_STAR.sh script inside the container: 
  ```
  docker run -d --name star -v /data:/data biodepot/star-for-criu:latest /bin/bash /home/run_STAR.sh
  ```
  3. Check the status of STAR alignment:
  ```
  docker logs star
  ```
  If it says **"Finish loading"**, the genome indices is already in the shared memory. 
- Checkpoint container<br/>
  There are two ways to checkpoint the container: 
  - Save checkpoint files in default path
  ```
  docker checkpoint create star checkpoint-star
  ```
  - Save checkpoint files in specific path, such as _**"/home/checkpoint"**_
  ```
  docker checkpoint create --checkpoint-dir=/home/checkpoint star checkpoint-star
  ```
- Restore container from checkpoint files<br/>
  - Restore container from checkpoint files in default path:
  ```
  docker start --checkpoint checkpoint-star star-restore
  ```
  - Restore container from checkpoint files in specific path: <br/>
  Create new container but not run it. 
  ```
  docker create --name star-restore -v /data:/data biodepot/star-for-criu:latest /bin/bash /home/run_STAR.sh
  ```
  Restore the checkpoint into new container
  ```
  docker start --checkpoint-dir=/home/checkpoint/CHECKPOINT_ID/checkpoints --checkpoint=checkpoint-star star-restore
  ```
  _CHECKPOINT_ID_ is the name of the checkpoint folder. 
- STAR Alignment using restored container
  1. Access into the container:
  ```
  docker exec -it CONTAINER_ID /bin/bash
  ```
  2. STAR Alignment
  ```
  /bin/STAR --runThreadN 8 --genomeDir /data/genome --genomeLoad LoadAndKeep --readFilesIn /data/fastqfiles/SRR1039508_1.fastq /data/fastqfiles/SRR1039508_2.fastq
  ```
  We can see the time needed for loading genome in this step is zero because the genome indices is already in the shared memory after we restore the container from checkpoint files.

## Deployment and Testing

This method has been tested using a standard DS13 v2 instance with 8 virtual CPUs and 56 Gb memory on Azure and a m4.4xlarge instance with 16 virtual CPUs and 64 Gb memory on AWS. Checkpoint files can be generated on one instance and restored on another instance. 

## Publication
A pre-print of our manuscript for this project has been submitted to BioRxiv. <br/>
The link of the paper: <br/>
https://www.biorxiv.org/content/early/2017/10/17/204495

## License <br/>
This project is licensed under the terms of the MIT license.





