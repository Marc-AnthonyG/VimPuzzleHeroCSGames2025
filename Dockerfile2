FROM anatolelucet/neovim:0.10.0-ubuntu

WORKDIR /usr/src

# Install curl
RUN apt-get update && apt-get install -y curl git

RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

COPY . .

RUN nvim -u init.vim +'PlugInstall --sync' +qa

CMD ["nvim", "-u", "init.vim"]
