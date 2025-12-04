{
  ...
}:

{
  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.file.".local/share/navi/cheats/container/k3d.cheats".text = ''
    % k3d

    # Check if docker is running
    k3d check-tools

    # Start a subshell for a cluster
    k3d shell

    # Create a single k3s cluster in docker containers
    k3d create --name <cluster_name>

    # Create a multi-node k3s cluster in docker containers
    k3d create --name <name> --workers <worker_count>

    # Delete cluster
    k3d delete --name <cluster_name>

    # Stop cluster
    k3d stop --name <cluster_name>

    # Start a stopped cluster
    k3d start --name <cluster_name>

    # List all clusters
    k3d list

    # Get kubeconfig location for cluster
    k3d get-kubeconfig --name <cluster_name>

    # Import a comma- or space-separated list of container images from your local docker daemon into the cluster
    k3d import-images

    # Show a list of commands or help for one command
    k3d help

    $ cluster_name: k3d list |awk '{print $2}' | awk 'NF {print $0}' | tail -n +2
  '';
  home.file.".local/share/navi/cheats/container/docker.cheats".text = ''
    % docker

    # Remove an image
    docker image rm <image_id>

    # Delete an image from the local image store
    docker rmi <image_id>

    # Clean none/dangling images
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

    # Force clean none/dangling images
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc) -f

    # List all images that are locally stored with the Docker engine
    docker images

    # Build an image from the Dockerfile in the current directory and tag the image
    docker build -t <image>:<version> .

    # Pull an image from a registry
    docker pull <image>:<version>

    # Stop a running container through SIGTERM
    docker stop <container_id>

    # Stop a running container through SIGKILL
    docker kill <container_id>

    # List the networks
    docker network ls

    # List the running containers
    docker ps

    # Delete all running and stopped containers
    docker rm -f $(docker ps -aq)

    # Create a new bash process inside the container and connect it to the terminal
    docker exec -it <container_id> bash

    # Print the last lines of a container's logs
    docker logs --tail 100 <container_id> | less

    # Print the last lines of a container's logs and following its logs
    docker logs --tail 100 <container_id> -f

    # Create new network
    docker network create <network_name>

    $ image_id: docker images --- --headers 1 --column 3
    $ container_id: docker ps --- --headers 1 --column 1

    % docker compose

    # Builds, (re)creates, starts, and attaches to containers for all services
    docker compose up

    # Builds, (re)creates, starts, and dettaches to containers for all services
    docker compose up -d

    # Builds, (re)creates, starts, and attaches to containers for a service
    docker compose up -d <service_name>

    # Builds, (re)creates, starts, and dettaches to containers for a service
    docker compose up -d <service_name>

    # Print the last lines of a service’s logs
    docker compose logs --tail 100 <service_name> | less

    # Print the last lines of a service's logs and following its logs
    docker compose logs -f --tail 100 <service_name>

    # Stops containers and removes containers, networks created by up
    docker compose down
  '';
  home.file.".local/share/navi/cheats/container/kuberenetes.cheats".text = ''
    % kubernetes, k8s

    # Print all contexts
    kubectl config get-contexts

    # Print current context of kubeconfig
    kubectl config current-context

    # Set context of kubeconfig
    kubectl config use-context <context>

    # Print resource documentation
    kubectl explain <resource>

    # Get nodes (add option '-o wide' for details)
    kubectl get nodes

    # Get namespaces
    kubectl get namespaces

    # Get pods from namespace (add option '-o wide' for details)
    kubectl get pods -n <namespace>

    # Get pods from all namespace (add option '-o wide' for details)
    kubectl get pods --all-namespaces

    # Get services from namespace
    kubectl get services -n <namespace>

    # Get details from resource on namespace
    kubectl describe <resource>/<name> -n <namespace>

    # Print logs from namespace
    kubectl logs -f pods/<name> -n <namespace>

    # Get deployments
    kubectl get deployments -n <namespace>

    # Edit deployments
    kubectl edit deployment/<name> -n <namespace>

    # Drain node in preparation for maintenance
    kubectl drain <name>

    # Mark node as schedulable
    kubectl uncordon <name>

    # Mark node as unschedulable
    kubectl cordon <name>

    # Display resource (cpu/memory/storage) usage
    kubectl top <type>

    # List the namespaces in the current context
    kubens

    # Change the active namespace of current context
    kubens <namespaces>

    # Switch to the previous namespace in this context
    kubens -

    # Show the current namespace
    kubens -c

    $ namespaces: kubens --- --headers 1 --column 3
  '';
  home.file.".local/share/navi/cheats/local/local.cheats".text = ''
    % runbooks

    # Open a runbook (fzf + glow preview; picks any *.md in ~/.runbooks)
    glow "<file>"

    # New runbook
    ~/.runbooks/new.sh

    $file: bash -lc 'fd -e md . "$HOME/.runbooks" | sort' --- \
      --preview 'sed "/^-->/q" {} | glow -p -' \
      --query "" \
      --header "Select a runbook"

    % migrations

    # add migration
    # Description: Create a new migration file with timestamp
    touch "$(date +%Y%m%d%H%M%S)_<name>.sql"
  '';
}
