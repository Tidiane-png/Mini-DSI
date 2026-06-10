# Architecture réseau — Mini-DSI PME

## Vue d'ensemble

```
Internet (NAT VMnet8)
        |
     pfSense
     (Router0)
        |
     Switch0 (VMnet1 — 192.168.10.0/24)
    /   |   \
   DC  Samba  Client-Win
(AD/DHCP/DNS) (Partages) (Domaine)

pfSense
   |
Switch-Backup (VMnet2 — 192.168.20.0/24)
   |
VM-Backup (rsync)
```

## Détail des VMs

### 1. pfSense (Routeur / Pare-feu)
- **OS** : pfSense CE 2.7
- **Rôle** : routage inter-VLAN, pare-feu, NAT vers internet
- **Interfaces** :
  - WAN : VMnet8 (NAT) — IP automatique
  - LAN : VMnet1 — 192.168.10.254
  - BACKUP : VMnet2 — 192.168.20.254 
ee
### 2. DC-Server (Contrôleur de domaine)
- **OS** : Windows Server 2022
- **Rôles** : AD DS, DHCP, DNS
- **IP** : 192.168.10.1 (statique)
- **Domaine** : mini-dsi.local

### 3. Linux-Samba (Serveur de fichiers)
- **OS** : Ubuntu Server 22.04 LTS
- **Rôles** : Samba (partages réseau), SSH par clé
- **IP** : 192.168.10.2 (statique)
- **Partages** : /srv/partage (accessible depuis le domaine)

### 4. Client-Windows (Poste client)
- **OS** : Windows 10/11
- **Rôle** : poste joint au domaine, IP via DHCP
- **IP** : 192.168.10.100–200 (dynamique)

### 5. VM-Backup (Sauvegarde)
- **OS** : Ubuntu Server 22.04 LTS
- **Rôle** : réception des sauvegardes rsync
- **IP** : 192.168.20.1 (statique)
- **Réseau** : isolé sur VMnet2

## Réseaux VMware (Virtual Network Editor)

| VMnet  | Type    | Subnet              | Usage              |
|--------|---------|---------------------|--------------------|
| VMnet1 | Host-only | 192.168.10.0/24   | LAN principal      |
| VMnet2 | Host-only | 192.168.20.0/24   | Réseau backup isolé|
| VMnet8 | NAT     | automatique          | Accès internet     |
