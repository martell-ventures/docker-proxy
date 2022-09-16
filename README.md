This is a proxy for all the other dockerized projects.

docker-compose up

Your other webserver containers need to have:

    environment:
      VIRTUAL_HOST: earthhero.local 
    networks:
      - proxy-network

Also they need to EXPOSE the ports in their Dockerfile.

Don't forget to update /etc/hosts as well.

To generate a Certificate for SSH connections:
```
openssl req -x509 -out lyrics2learn.local.crt -keyout lyrics2learn.local.key   -newkey rsa:2048 -nodes -sha256   -subj '/CN=lyrics2learn.local' -extensions EXT -config <( \
  printf "[dn]\nCN=lyrics2learn.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:lyrics2learn.local\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```
Or:
```
openssl req -x509 -out launchgood.local.crt -keyout launchgood.local.key   -newkey rsa:2048 -nodes -sha256   -subj '/CN=launchgood.local' -extensions EXT -config <( \
  printf "[dn]\nCN=launchgood.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:launchgood.local\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```