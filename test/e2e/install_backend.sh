#! /bin/sh

# Backend is mandatory for e2e tests, install it from github then start it
git clone https://$GITHUB_VIGIECHIRO_API_TOKEN:x-oauth-basic@github.com:Scille/vigiechiro-api.git
cd vigiechiro-api
virtualenv -p /usr/bin/python3 venv
. ./venv/bin/activate
pip install -r requirements.txt
pip install -e .
pip install -r dev-requirements.txt
./runserver.py&
cd ..
