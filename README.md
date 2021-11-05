[ ![Codeship Status for Scille/vigiechiro-front](https://codeship.com/projects/2f279570-74c9-0132-ff21-2aca0eeadc1e/status?branch=master)](https://codeship.com/projects/55074)

vigiechiro-front
================

Partie frontend du projet vigie chiro du Muséum national d'histoire naturelle

Netcat (nc) pour debian
```
sudo apt-get install netcat-openbsd
```

Curl pour debian
```
sudo apt-get install curl
```

Pour installer Nodejs et npm : [https://nodejs.org/en/download/package-manager/](https://nodejs.org/en/download/package-manager/)

Installation de bower et grunt
```
npm install -g grunt-cli@1.3.2 bower@^1.8.12 protractor@^7.0.0
```

Tests end-to-end
```
npm install -g protractor
sudo webdriver-manager update
./test/e2e/bootstrap_e2e.sh
```
