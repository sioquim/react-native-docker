# Node alpine
ARG VERSION=current

FROM node:$VERSION-alpine as production
ARG PROJECT_ID=default
ARG USERNAME=${PROJECT_ID}

# add git and open ssh
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories \
    && echo @edgecommunity http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && apk update && apk add --upgrade apk-tools@edge && apk upgrade \
    && apk add --no-cache bash openssh gnupg \
    # installing build dependencies
    git python make g++ xz shadow \
    && apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing vips-tools

# Create user for our app
RUN useradd --user-group --create-home --shell /bin/false ${USERNAME}

# set our home
ENV HOME=/home/${USERNAME}

# switch to this user
USER ${USERNAME}

# set the working directory to be
WORKDIR ${HOME}

## HAVE GLOBAL PACKAGE NOT STORED IN ROOT ACCESS LOCATION
RUN mkdir "${HOME}/.node"
# Tell npm where to store the globally installed packages
RUN echo 'prefix=~/.node' >> "${HOME}/.npmrc"
# Add the new bin and node_modules folders to your $PATH and $NODE_PATH variables
RUN echo 'PATH="$HOME/.node/bin:$PATH"' >> "${HOME}/.profile" \
    && echo 'NODE_PATH="$HOME/.node/lib/node_modules:$NODE_PATH"' >> "${HOME}/.profile" \
    && echo 'MANPATH="$HOME/.node/share/man:$MANPATH"' >> "${HOME}/.profile" \
    && source "${HOME}/.profile"


## DEV TOOLS
FROM production as development
ARG PROJECT_ID=default
ARG USERNAME=${PROJECT_ID}
USER root
RUN apk update \
    && apk add \
        sudo \
        docker \
        'py-pip' \
        zsh \
        vim \
        curl

RUN echo "${USERNAME}"
# setting proper permission and UID/GID, could use groupmod -g 999 docker maybe
RUN groupdel ping \
    && groupdel docker \
    && groupadd -g 999 docker \
    && usermod -aG docker ${USERNAME} \
    && usermod -aG root ${USERNAME}

# install docker compose
RUN sudo -H pip install --upgrade pip docker-compose

# install circleci cli
RUN curl -o /usr/local/bin/circleci https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci && chmod +x /usr/local/bin/circleci

# switch back to our user
USER $USERNAME

# install the latest yarn version
RUN curl --compressed -o- -L https://yarnpkg.com/install.sh | bash

# commitizen (formated commit so we can create nice release following semantic versioning)
RUN yarn config set workspaces-experimental true

# install react and expo
RUN yarn global add expo-cli commitizen cz-conventional-changelog yarn-run \
    && echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc

# add profile to bash in case dev uses bash
RUN echo "PS1='${PROJECT_ID}:\w$ '" >> ~/.profile \
    && echo ". ~/.profile" > ~/.bashrc

# add zgen
RUN git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"

# edit zshrc
RUN printf "\
export TERM=\"xterm-256color\" \n\
export LC_ALL=en_US.UTF-8 \n\
export LANG=en_US.UTF-8 \n\
export PATH=/usr/local/sbin:\${PATH} \n\
export PATH=~/.local/bin:\${PATH} \n\
export PATH=~/application/node_modules/.bin:\${PATH} \n\
\n\
fpath=(~/.zsh_completion \"\${fpath[@]}\") \n\
\n\
# Source Profile \n\
[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile' \n\
\n\
# finally load zgen \n\
source \"\${HOME}/.zgen/zgen.zsh\" \n\
\n\
# if the init scipt doesn't exist \n\
if ! zgen saved; then \n\
    echo \"Creating a zgen save\" \n\
\n\
    # Load the oh-my-zsh's library. \n\
    zgen oh-my-zsh \n\
\n\
    # plugins \n\
    zgen oh-my-zsh plugins/git \n\
    zgen oh-my-zsh plugins/command-not-found \n\
    zgen load zsh-users/zsh-syntax-highlighting \n\
    \n\
    # completions \n\
    zgen load zsh-users/zsh-completions src \n\
    \n\
    # theme \n\
    \n\
    # save all to init script \n\
    zgen save \n\
fi \n\
\n\
export PROMPT_SUBST=true \n\
export PROMPT_PERCENT=true \n\
export PROMPT='${PROJECT_ID}$ ' \n\
export RPROMPT='' \n" > ~/.zshrc

RUN git config --global credential.helper store

# Create our application workdir
WORKDIR "application"

# be sure all files in the user root folder are accessible by the user
# USER root
# RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
# USER ${USERNAME}