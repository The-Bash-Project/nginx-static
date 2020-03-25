# Nginx Auto
### Nginx Auto is a bash script that automates your NGINX Static Webserver Deployment

# Guide

https://medium.com/@ChinyaSuhail/install-nginx-on-ubuntu-the-easy-way-b92704bb3f3d


## Note
#### ⚠️ Remember to Point your domain (FQDN) to the server’s IP by adding an A record before proceeding further <br/> (example.com in “A” 192.168.0.1)

#### ⚠️ Add a www CNAME pointing to your root domain (www.example.com → example.com)

&thinsp;

## 🙌 SSH into your instance and run the Installer and That’s It.

```
wget -N https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/install.sh; sudo chmod +x install.sh; sudo ./install.sh
```
&thinsp;

## 🧙 Now FTP/ SFTP or Use a magic wand to move your assets into

```
/var/www/<your-domain-name-used-for-installation>
```

&thinsp;

## 🆘 Ran into trouble? Need a fresh restart? Use the Uninstall Command.

```
wget -N https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/uninstall.sh; sudo chmod +x uninstall.sh; sudo ./uninstall.sh
```

## How to add an A Record and C Name Record

### 1. Go to your DNS hosting provider
### If you have forgotten your DNS hosting provider, NO PROBLEM, go to [mxtoolbox.com](https://mxtoolbox.com))


### 2. Create an A record with your domain that points to your server's IP address.
### Run `$ curl http://checkip.amazonaws.com` to find your server's IP address.

### 3. Create a CNAME record of `www` that points to your domain.