FROM alpine:3.12 as ctags-builder

WORKDIR /mnt/build/ctags

RUN apk --update --no-cache add \
	git \
	xfce4-dev-tools \
	build-base

RUN \
	git clone https://github.com/universal-ctags/ctags \
	&& cd ctags \
	&& ./autogen.sh \
	&& ./configure --prefix=/usr/local \
	&& make \
	&& make install


FROM alpine:3.12 as nvim-builder

WORKDIR /mnt/build/nvim

RUN apk --update --no-cache add \
	git \
  build-base cmake automake autoconf libtool pkgconf coreutils curl unzip gettext-tiny-dev

RUN git clone https://github.com/neovim/neovim \
  && cd neovim \
  && make CMAKE_BUILD_TYPE=Release \
  && mkdir -p /mnt/install/nvim \
  && make CMAKE_INSTALL_PREFIX=/mnt/install/nvim install


FROM alpine:3.12

LABEL \
        maintainer="neovim@daniel-pieper.com" \
        url.github="https://github.com/danielpieper/neovim-docker" \
        url.dockerhub="https://hub.docker.com/r/danielpieper/neovim-docker/"

ENV \
        UID="1000" \
        GID="1000" \
        UNAME="neovim" \
        GNAME="neovim" \
        SHELL="/bin/bash" \
        WORKSPACE="/mnt/workspace" \
	NVIM_CONFIG="/home/neovim/.config/nvim" \
	NVIM_PCK="/home/neovim/.local/share/nvim/site/pack" \
	ENV_DIR="/home/neovim/.local/share/vendorvenv" \
	NVIM_PROVIDER_PYLIB="python3_neovim_provider" \
	PATH="/home/neovim/.local/bin:${PATH}"

RUN \
	# install packages
	apk --update --no-cache add \
		# needed by neovim :CheckHealth to fetch info
	curl \
		# needed to change uid and gid on running container
	shadow \
		# needed to install apk packages as neovim user on the container
	sudo \
		# needed to switch user
  su-exec \
		# needed for neovim python3 support
	python3 \
		# needed for pipsi
	py3-virtualenv \
		# text editor
	fzf \
	bash \
    # needed by fzf because the default shell does not support fzf
  libgcc \
    # needed by neovim
	# install build packages
	&& apk --update --no-cache add --virtual build-dependencies \
	python3-dev \
	gcc \
	musl-dev \
	git \
	# create user
	&& addgroup "${GNAME}" \
	&& adduser -D -G "${GNAME}" -g "" -s "${SHELL}" "${UNAME}" \
        && echo "${UNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	# install neovim python3 provider
	&& sudo -u neovim python3 -m venv "${ENV_DIR}/${NVIM_PROVIDER_PYLIB}" \
	&& "${ENV_DIR}/${NVIM_PROVIDER_PYLIB}/bin/pip" install pynvim \
	# install plugins
	# && mkdir -p "${NVIM_PCK}/common/start" "${NVIM_PCK}/filetype/start" "${NVIM_PCK}/colors/opt" \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/tpope/vim-commentary \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/junegunn/fzf.vim \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/tpope/vim-surround \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/tpope/vim-obsession \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/yuttie/comfortable-motion.vim \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/wellle/targets.vim \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/SirVer/ultisnips \
	# && git -C "${NVIM_PCK}/filetype/start" clone --depth 1 https://github.com/mattn/emmet-vim \
	# && git -C "${NVIM_PCK}/filetype/start" clone --depth 1 https://github.com/lervag/vimtex \
	# && git -C "${NVIM_PCK}/filetype/start" clone --depth 1 https://github.com/captbaritone/better-indent-support-for-php-with-html \
	# && git -C "${NVIM_PCK}/colors/opt" clone --depth 1 https://github.com/fxn/vim-monochrome \
	# && git -C "${NVIM_PCK}/common/start" clone --depth 1 https://github.com/autozimu/LanguageClient-neovim \
	# && cd "${NVIM_PCK}/common/start/LanguageClient-neovim/" && sh install.sh \
	# remove build packages
	&& apk del build-dependencies

COPY --from=ctags-builder /usr/local/bin/ctags /usr/local/bin
COPY --from=nvim-builder /mnt/install/nvim /home/neovim/.local/

RUN chown -R neovim:neovim /home/neovim/.local

COPY entrypoint.sh /usr/local/bin/

VOLUME "${WORKSPACE}"
# VOLUME "${NVIM_CONFIG}"

ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]
