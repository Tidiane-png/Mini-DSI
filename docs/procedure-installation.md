# Procédure d'installation — Mini-DSI PME

## Prérequis

- VMware Workstation Pro installé
- ISOs téléchargés :
  - Windows Server 2022 (évaluation 180j) : https://www.microsoft.com/fr-fr/evalcenter/
  - Ubuntu Server 22.04 LTS : https://ubuntu.com/download/server
  - pfSense CE 2.7 : https://www.pfsense.org/download/
  - Windows 10/11 : https://www.microsoft.com/fr-fr/software-download/

---

## Étape 1 — Configurer les réseaux VMware

1. Ouvrir **Virtual Network Editor** (en tant qu'administrateur)
2. Créer **VMnet1** : Host-only, subnet 192.168.10.0/24, désactiver DHCP VMware
3. Créer **VMnet2** : Host-only, subnet 192.168.20.0/24, désactiver DHCP VMware
4. Garder **VMnet8** : NAT (déjà présent)

---

## Étape 2 — Créer les VMs vides

### pfSense
- CPU : 1 vCPU, RAM : 512 Mo, Disque : 8 Go
- Réseau : 3 interfaces (VMnet8, VMnet1, VMnet2)

### DC-Server (Windows Server 2022)
- CPU : 2 vCPU, RAM : 2 Go, Disque : 40 Go
- Réseau : VMnet1

### Linux-Samba (Ubuntu Server 22.04)
- CPU : 1 vCPU, RAM : 1 Go, Disque : 20 Go
- Réseau : VMnet1

### Client-Windows
- CPU : 2 vCPU, RAM : 2 Go, Disque : 40 Go
- Réseau : VMnet1

### VM-Backup (Ubuntu Server 22.04)
- CPU : 1 vCPU, RAM : 1 Go, Disque : 50 Go
- Réseau : VMnet2

---

## Étape 3 — Installer pfSense

1. Démarrer la VM pfSense avec l'ISO
2. Suivre l'assistant d'installation (accepter les défauts)
3. Après reboot, assigner les interfaces :
   - WAN → em0 (VMnet8)
   - LAN → em1 (VMnet1)
   - OPT1 → em2 (VMnet2)
4. Configurer l'IP LAN : 192.168.10.254/24
5. Configurer l'IP OPT1 : 192.168.20.254/24

---

## Étape 4 — Installer Windows Server 2022 (DC)

1. Installer Windows Server 2022 (Desktop Experience)
2. Définir IP statique : 192.168.10.1, masque /24, passerelle 192.168.10.254, DNS 127.0.0.1
3. Renommer le serveur : `DC-MINI-DSI`
4. Installer le rôle AD DS via le Gestionnaire de serveur
5. Promouvoir en contrôleur de domaine : domaine `mini-dsi.local`
6. Installer et configurer le rôle DHCP (plage 192.168.10.100–200)
7. Vérifier DNS : les zones `mini-dsi.local` sont créées automatiquement

---

## Étape 5 — Installer Ubuntu Server (Linux-Samba)

1. Installer Ubuntu Server 22.04 LTS
2. Configurer IP statique dans `/etc/netplan/` : 192.168.10.2
3. Mettre à jour : `sudo apt update && sudo apt upgrade -y`
4. Installer Samba : `sudo apt install samba -y`
5. Créer le dossier partagé : `sudo mkdir -p /srv/partage`
6. Configurer `/etc/samba/smb.conf` (voir `configs/samba/`)
7. Configurer SSH par clé (désactiver auth par mot de passe)

---

## Étape 6 — Installer VM-Backup (Ubuntu Server)

1. Installer Ubuntu Server 22.04 LTS
2. Configurer IP statique : 192.168.20.1
3. Installer rsync : `sudo apt install rsync -y`
4. Créer le dossier de stockage : `sudo mkdir -p /mnt/backup`
5. Configurer SSH par clé depuis Linux-Samba
6. Planifier les sauvegardes via cron (voir `scripts/bash/backup.sh`)

---

## Étape 7 — Installer le Client Windows

1. Installer Windows 10/11
2. Laisser l'IP en DHCP (sera attribuée par le DC)
3. Joindre le domaine `mini-dsi.local` :
   - Paramètres → Système → Informations système → Modifier les paramètres
   - Domaine : `mini-dsi.local`
   - Identifiants administrateur du DC
4. Redémarrer
5. Se connecter avec un compte du domaine

---

## Vérifications finales

- [ ] `ping 192.168.10.1` depuis le client → OK
- [ ] Connexion avec compte AD depuis le client → OK
- [ ] Accès au partage Samba depuis le client → OK
- [ ] Sauvegarde rsync manuelle → OK
- [ ] Logs de sauvegarde automatique → OK
