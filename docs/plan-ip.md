# Plan d'adressage IP — Mini-DSI PME

## Réseau LAN Principal — VMnet1

| Machine       | Rôle                        | Adresse IP      | Masque          | Passerelle    | DNS           |
|---------------|-----------------------------|-----------------|-----------------|---------------|---------------|
| pfSense       | Routeur / Pare-feu          | 192.168.10.254  | 255.255.255.0   | —             | 127.0.0.1     |
| DC-Server     | AD DS / DHCP / DNS          | 192.168.10.1    | 255.255.255.0   | 192.168.10.254| 127.0.0.1     |
| Linux-Samba   | Partage fichiers / SSH      | 192.168.10.2    | 255.255.255.0   | 192.168.10.254| 192.168.10.1  |
| Client-Win    | Poste client (domaine)      | DHCP            | 255.255.255.0   | 192.168.10.254| 192.168.10.1  |

## Réseau Backup Isolé — VMnet2

| Machine       | Rôle                        | Adresse IP      | Masque          | Passerelle    | DNS           |
|---------------|-----------------------------|-----------------|-----------------|---------------|---------------|
| pfSense       | Interface backup            | 192.168.20.254  | 255.255.255.0   | —             | —             |
| VM-Backup     | Stockage rsync              | 192.168.20.1    | 255.255.255.0   | 192.168.20.254| 192.168.10.1  |

## Pool DHCP (configuré sur DC-Server)

- **Plage** : 192.168.10.100 — 192.168.10.200
- **Masque** : 255.255.255.0
- **Passerelle** : 192.168.10.254
- **DNS** : 192.168.10.1
- **Exclusions** : 192.168.10.1 à 192.168.10.99 (IPs statiques des serveurs)

## Résumé des sous-réseaux

| Réseau         | CIDR                  | Usage                  |
|----------------|-----------------------|------------------------|
| LAN principal  | 192.168.10.0/24       | Serveurs + clients     |
| Backup isolé   | 192.168.20.0/24       | VM de sauvegarde seule |
