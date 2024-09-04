#!/bin/bash

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <number_of_containers> <new_cpu_limit>"
    echo "Example: $0 5 0.5"
    exit 1
fi

# Number of containers (from the first argument)
N=$1

# New CPU limit (from the second argument)
NEW_CPU=$2

for i in $(seq 1 $N); do
    container_name="satorineuron$i"
    
    # Stop the container
    # echo "Stopping container $container_name..."
    # docker stop $container_name

    # Update the container with new CPU limit
    echo "Updating CPU limit for container $container_name to $NEW_CPU..."
    docker update --cpus=$NEW_CPU $container_name

    # # Start the container
    # echo "Starting container $container_name..."
    # docker start $container_name
    
    # echo "Updated and restarted container $container_name."
done

echo "All containers updated."
