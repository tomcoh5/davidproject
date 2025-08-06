version: 0.0
os: linux
files:
  - source: /
    destination: /opt/webapp
    overwrite: yes
permissions:
  - object: /opt/webapp
    owner: webapp
    group: webapp
    mode: 755
    type:
      - directory
  - object: /opt/webapp/app.js
    owner: webapp
    group: webapp
    mode: 644
    type:
      - file
  - object: /opt/webapp/package.json
    owner: webapp
    group: webapp
    mode: 644
    type:
      - file
  - object: /opt/webapp/scripts
    owner: webapp
    group: webapp
    mode: 755
    type:
      - directory
  - object: /opt/webapp/scripts/install_dependencies.sh
    owner: webapp
    group: webapp
    mode: 755
    type:
      - file
  - object: /opt/webapp/scripts/start_application.sh
    owner: webapp
    group: webapp
    mode: 755
    type:
      - file
  - object: /opt/webapp/scripts/stop_application.sh
    owner: webapp
    group: webapp
    mode: 755
    type:
      - file
hooks:
  BeforeInstall:
    - location: scripts/stop_application.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: scripts/install_dependencies.sh
      timeout: 600
      runas: root
  ApplicationStart:
    - location: scripts/start_application.sh
      timeout: 300
      runas: root
  ApplicationStop:
    - location: scripts/stop_application.sh
      timeout: 300
      runas: root
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 300
      runas: root 