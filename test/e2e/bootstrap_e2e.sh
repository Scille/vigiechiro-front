#! /bin/sh

BASEDIR=$(dirname $0)
BACKEND_DIR="vigiechiro-api"

clone_repo() {
    BACKEND_REPO="Scille/vigiechiro-api.git"
    BRANCH="v2"
    if [ ! -z "$GITHUB_VIGIECHIRO_API_TOKEN" ]
    then
        git clone https://$GITHUB_VIGIECHIRO_API_TOKEN@github.com/$BACKEND_REPO -b $BRANCH
    else
        git clone git@github.com:$BACKEND_REPO -b $BRANCH
    fi
}

run_backend() {
    # Backend is mandatory for e2e tests, install it from github then start it
    if [ ! -d "$BACKEND_DIR" ]; then
        clone_repo
        cd $BACKEND_DIR
        # Install virtualenv and dependancies
        virtualenv -p /usr/bin/python3 venv
        . ./venv/bin/activate
        pip install -r requirements.txt
        pip install -e .
        pip install -r dev-requirements.txt
    else
        cd $BACKEND_DIR
        . ./venv/bin/activate
    fi
    # /!\ make sure to set FRONT_DOMAIN according to the e2e connexion
    echo "Starting Backend"
    1>backend.log ./runserver.py 2>&1 &
    sleep 1
    cd ..
}

test_backend() {
    echo 'GET /' | 1>/dev/null 2>&1 nc localhost 8080
}

test_frontend() {
    echo 'GET /' | 1>/dev/null 2>&1 nc localhost 9000
}

# Bootstrap in script's directory
OLD_DIR=`pwd`
cd $BASEDIR

# Make sure the backend is running
test_backend
if [ "$?" -ne 0 ]
then
    run_backend
else
    echo "Backend already running"
fi

# Same thing for the frontend
test_frontend
if [ "$?" -ne 0 ]
then
    echo "Starting frontend"
    1>frontend.log grunt serve:dist 2>&1 &
    sleep 5
else
    echo "Frontend already running"
fi

# Make sure webdriver is up and running
echo 'GET /wd/hub' | nc localhost 4444
if [ "$?" -ne 0 ]
then
    webdriver-manager update --standalone
    echo "Starting webdriver"
    1>webdriver.log webdriver-manager start 2>&1 &
    sleep 1
else
    echo "Webdriver already running"
fi

# Reset the bdd
echo "Setting the bdd..."
mongorestore -d vigiechiro e2e_vigiechiro_db --drop

# If on codeship integration server, wait a bit for startup
test_backend && test_frontend
while [ "$?" -ne 0 ]
do
    echo "Waiting 1s for starup..."
    sleep 1
    test_backend && test_frontend
done
