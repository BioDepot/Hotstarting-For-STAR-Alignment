# Checkpoint container

# The path of genome files and RNA-Seq files
data_path='/data'

# Original container name
original_container_name='star'

# New container name:
new_container_name='star-restore'

# Checkpoint name
checkpoint_name='checkpoint-star'

# Checkpoint path
checkpoint_path='/home/checkpoint'

# The name of the checkpoint folder
checkpoint_id='c6a99be090739b14413d1b3e4f2ef56dc1b0f92ae821a9737d0780babe42ef20'

# Save checkpoint files in default path
sudo docker checkpoint create $original_container_name $checkpoint_name

# Save checkpoint files in specific path, such as "/home/checkpoint"
docker checkpoint create --checkpoint-dir=$checkpoint_path star checkpoint-star

# ---------------------------------------------------
# Restore container from checkpoint files
# Restore container from checkpoint files in default path
sudo docker start --checkpoint $checkpoint_name $new_container_name

# Restore container from checkpoint files in specific path:
# Create new container but not run it.
sudo docker create --name $new_container_name -v $data_path:/data biodepot/star-for-criu:latest /bin/bash /home/run_STAR.sh 
# Restore the checkpoint into new container
sudo docker start --checkpoint-dir=/home/checkpoint/$checkpoint_id/checkpoints --checkpoint=$checkpoint_name $new_container_name
