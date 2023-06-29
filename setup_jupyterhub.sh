#!/bin/bash

sudo apt-get -y install nodejs npm

python3 -m pip install jupyterhub
npm install -g configurable-http-proxy
#python3 -m pip install jupyterlab notebook  # needed if running the notebook servers in the same environment

# Alternative
curl -L https://tljh.jupyter.org/bootstrap.py \
| sudo python3 - \
--admin <admin-user-name> \
--show-progress-page