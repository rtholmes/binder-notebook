# Dockerfile to build a prebuilt image to run this example on mybinder.org.
# FROM node:lts-buster
FROM alpine:latest

# cache-busting to force rebuild the image in mybinder.org.
RUN echo cache-busting-6

# update things
RUN apk update 


# from: https://github.com/drillan/docker-alpine-jupyterlab/blob/master/Dockerfile
RUN apk add \
    ca-certificates \ 
    libstdc++ \
    python3

RUN apk add --virtual=build_dependencies \
    cmake \
    gcc \
    g++ \
    make \
    musl-dev \
    python3-dev \
&& ln -s /usr/include/locale.h /usr/include/xlocale.h

RUN python3 -m pip --no-cache-dir install pip -U \
&& python3 -m pip --no-cache-dir install \
    jupyter \
    jupyterlab
	
RUN jupyter serverextension enable --py jupyterlab --sys-prefix \
&& apk del --purge -r build_dependencies \
&& rm -rf /var/cache/apk/*
# && mkdir /notebooks

#VOLUME /notebooks
#ENTRYPOINT /usr/bin/jupyter lab --no-browser --ip=0.0.0.0 --notebook-dir=/notebooks
#EXPOSE 8888


# Install python/pip
#ENV PYTHONUNBUFFERED=1
#RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
#RUN python3 -m ensurepip
#RUN pip3 install --no-cache --upgrade pip setuptools

# Install node / npm / yarn
# RUN apk add nodejs npm yarn

#RUN apt-get update &&\
#  apt-get install -y python3-pip &&\
#  rm -rf /var/lib/apt/lists/* &&\
#  pip3 install --no-cache-dir -U jupyterlab

# install jupyter
#RUN pip3 install --no-cache-dir -U jupyterlab

# Support UTF-8 filename in Python (https://stackoverflow.com/a/31754469)
ENV LC_CTYPE=C.UTF-8

# Check the uid of node is 1000 to follow the convention of mybinder to use this image from mybinder.org.
# https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html#preparing-your-dockerfile
# Notes:
# Don't use ARG NB_USER here. It's overwritten with jovyan.
ENV HOME /home/node
RUN id -u node | grep -c "^1000$"
USER node
WORKDIR ${HOME}

# Install tslab
ENV PATH $PATH:${HOME}/.npm-global/bin
RUN mkdir ~/.npm-global &&\
  npm config set prefix '~/.npm-global' &&\
  npm install -g tslab &&\
  tslab install
  
# clone repo
RUN git clone --depth 1 https://github.com/rtholmes/binder-notebook.git
WORKDIR ${HOME}/binder-notebook

# RUN yarn
RUN yarn install

# Notes:
# 1. Do not use ENTRYPOINT because mybinder need to run a custom command.
# 2. To use JupyterNotebook, replace "lab" with notebook".
# 3. Set --allow-root in case you want to run jupyter as root.
CMD ["jupyter", "lab", "--ip=0.0.0.0"]
