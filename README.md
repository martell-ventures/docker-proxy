This is a proxy for all the other dockerized projects.

docker-compose up

Your other webserver containers need to have:

    environment:
      VIRTUAL_HOST: earthhero.local 
    networks:
      - proxy-network

Also they need to EXPOSE the ports in their Dockerfile.

Don't forget to update /etc/hosts as well.
