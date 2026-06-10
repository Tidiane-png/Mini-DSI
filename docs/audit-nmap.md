# Audit sécurité — Scan Nmap — Mini-DSI PME

## Objectif

Vérifier les ports ouverts sur chaque VM et s'assurer que seuls les services nécessaires sont exposés.

---

## Commandes utilisées

### Scan rapide de tout le réseau LAN :
```bash
nmap -sV 192.168.10.0/24
```

### Scan détaillé d'une machine :
```bash
nmap -sV -sC -p- 192.168.10.1
```

### Scan réseau backup :
```bash
nmap -sV 192.168.20.0/24
```

---

## Résultats attendus par machine

### DC-Server — 192.168.10.1

| Port | Protocole | Service   | État    |
|------|-----------|-----------|---------|
| 53   | TCP/UDP   | DNS       | Ouvert  |
| 88   | TCP/UDP   | Kerberos  | Ouvert  |
| 135  | TCP       | RPC       | Ouvert  |
| 389  | TCP       | LDAP      | Ouvert  |
| 445  | TCP       | SMB       | Ouvert  |
| 3389 | TCP       | RDP       | Ouvert* |

*RDP doit être limité aux IPs internes uniquement.

### Linux-Samba — 192.168.10.2

| Port | Protocole | Service | État   |
|------|-----------|---------|--------|
| 22   | TCP       | SSH     | Ouvert |
| 139  | TCP       | NetBIOS | Ouvert |
| 445  | TCP       | SMB     | Ouvert |

### VM-Backup — 192.168.20.1

| Port | Protocole | Service | État   |
|------|-----------|---------|--------|
| 22   | TCP       | SSH     | Ouvert |

Tous les autres ports doivent être **fermés**.

### pfSense — 192.168.10.254

| Port | Protocole | Service    | État   |
|------|-----------|------------|--------|
| 80   | TCP       | HTTP (web) | Ouvert (LAN uniquement) |
| 443  | TCP       | HTTPS      | Ouvert (LAN uniquement) |

---

## Points de contrôle sécurité

- [ ] Aucun port inutile ouvert sur la VM-Backup
- [ ] SSH configuré avec authentification par clé uniquement (pas de mot de passe)
- [ ] RDP du DC accessible uniquement depuis le LAN interne
- [ ] Interface WAN de pfSense ne répond pas aux scans externes
- [ ] Pare-feu pfSense bloque les connexions VMnet2 → VMnet1 (sauf rsync/SSH)

---

## Mesures correctives appliquées

- Désactivation de l'authentification SSH par mot de passe : `PasswordAuthentication no` dans `/etc/ssh/sshd_config`
- Règle pfSense : LAN → WAN autorisé, WAN → LAN refusé par défaut
- Règle pfSense : VMnet2 → VMnet1 bloqué sauf port 22 (rsync/SSH)
