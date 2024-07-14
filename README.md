# vim-be-good

Vim be good is a plugin designed to make you better at vim by creating a game
to practice basic movements in.

## WARNING

-   The code is a heaping pile of awfulness. It was developed live on Twitch,
    which means I did not carefully think through anything other than memes.
-   If you wish to create your own game, look at how relative is done.
    Everything else should be straight forward, except for the parts that are
    not.


## Installation

### Docker

If you would like, you can use docker to run the game. Doing this will
automatically use the correct version of neovim for you, as well as run the
game immediately when neovim starts.

#### Stable image

[This image](https://github.com/brandoncc/docker-vim-be-good/blob/master/stable/Dockerfile) always runs the version of the game that was bundled when the image
was built. Images are generally built within one day of the main branch
receiving new commits, but you won't get the new images unless you manually run
`docker pull brandoncc/vim-be-good:stable` periodically.

```bash
docker run -it --rm brandoncc/vim-be-good:stable
```

#### "Latest" image

[This image](https://github.com/brandoncc/docker-vim-be-good/blob/master/latest/Dockerfile) runs `:PlugUpdate` before running neovim. This adds about one second
to the startup time of the game. The trade-off is that you are always playing
the latest version of the game, as long as your machine is able to access
Github.com to pull it.

```bash
docker run -it --rm brandoncc/vim-be-good:latest
```

## Logging

Please file an issue. But if you do, please run the logger first and paste in
the input.

To initialize the logger, add this to your vimrc

```
let g:vim_be_good_log_file = 1
```

to get the log file executed `:echo stdpath("data")` to find the path and then
copy paste it into the issues.
