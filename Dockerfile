FROM anatolelucet/neovim:0.10.1-ubuntu

RUN apt-get update && apt-get install -y git socat ttyd

WORKDIR /root/.config

COPY . .

RUN chmod +x ./run_socat.sh

ENTRYPOINT ["./run_socat.sh"]
