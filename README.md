[ ![Codeship Status for Scille/vigiechiro-front](https://codeship.com/projects/2f279570-74c9-0132-ff21-2aca0eeadc1e/status?branch=master)](https://codeship.com/projects/55074)

vigiechiro-front
================

Partie frontend du projet vigie chiro du Muséum national d'histoire naturelle

Netcat (nc) pour debian
```
sudo apt-get install netcat-openbsd
```

Start webserver
```
Launch vigiechiro-ap
```
grunt serve
```
or
grunt serve:dist
```


Tests end-to-end
```
sudo npm install -g protractor
sudo webdriver-manager update
./test/e2e/bootstrap_e2e.sh
```
