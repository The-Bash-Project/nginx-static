# Nginx Auto
### Nginx Auto is a bash script that automates your NGINX Static Webserver Deployment

# Guide

https://medium.com/@ChinyaSuhail/install-nginx-on-ubuntu-the-easy-way-b92704bb3f3d


## Note
#### ⚠️ Remember to point your domain to the server before starting the script
#### ⚠️ Remember to add www CNAME record to the domain 


## 🙌 SSH into your instance and run the Installer and That’s It.

```
wget -N https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/install.sh; sudo chmod +x install.sh; sudo ./install.sh
```

### 🧙 Now FTP/ SFTP or Use a magic wand to move your assets into

```
/var/www/<your-domain-name-used-for-installation>
```

## 🆘 Ran into trouble? Need a fresh restart? Use the Uninstall Command.

```
wget -N https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/uninstall.sh; sudo chmod +x uninstall.sh; sudo ./uninstall.sh
```