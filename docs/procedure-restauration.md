# Procédure de restauration — Mini-DSI PME

## Objectif

Restaurer les données sauvegardées depuis la VM-Backup vers le serveur Linux-Samba en cas de perte ou corruption.

---

## Prérequis

- Accès SSH à la VM-Backup (192.168.20.1)
- Accès SSH au serveur Linux-Samba (192.168.10.2)
- Clés SSH configurées entre les deux machines

---

## Restauration manuelle complète

### Depuis Linux-Samba, lancer la restauration :

```bash
sudo rsync -avz --progress \
  -e "ssh -i /home/samba/.ssh/id_rsa" \
  backup@192.168.20.1:/mnt/backup/partage/ \
  /srv/partage/
```

### Vérifier l'intégrité après restauration :

```bash
ls -lh /srv/partage/
du -sh /srv/partage/
```

---

## Restauration d'un fichier spécifique

```bash
sudo rsync -avz \
  -e "ssh -i /home/samba/.ssh/id_rsa" \
  backup@192.168.20.1:/mnt/backup/partage/NOM_DU_FICHIER \
  /srv/partage/
```

---

## Restauration automatique (script)

Utiliser le script `scripts/bash/restauration.sh` :

```bash
sudo bash /opt/scripts/restauration.sh
```

Le script vérifie la connectivité, lance rsync et journalise le résultat dans `/var/log/restauration.log`.

---

## Vérification post-restauration

1. Contrôler le log : `cat /var/log/restauration.log`
2. Tester l'accès Samba depuis le client Windows : `\\192.168.10.2\partage`
3. Vérifier les permissions : `ls -la /srv/partage/`

---

## En cas d'échec

- Vérifier la connectivité réseau entre VMnet1 et VMnet2 (pfSense)
- Vérifier que SSH fonctionne : `ssh backup@192.168.20.1`
- Vérifier les logs SSH : `sudo journalctl -u ssh`
