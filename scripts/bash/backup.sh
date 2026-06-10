#!/bin/bash
# ============================================================
#  backup.sh
#  Sauvegarde automatique quotidienne — VM4 (backup01)
#  Cron : 0 22 * * * /opt/backup/backup.sh
# ============================================================

# --- Configuration ---
DATE=$(date +%Y-%m-%d)
HEURE=$(date +%H:%M:%S)
SOURCE_HOST="adminfile@192.168.10.2"
SSH_KEY="/root/.ssh/id_backup"
LOG_DIR="/backup/logs"
BACKUP_DIR="/backup/daily/$DATE"
RETENTION_JOURS=30

# Sources à sauvegarder sur file01
SOURCES=(
    "/media/G/Direction"
    "/media/G/Technique"
    "/media/G/Commercial"
    "/media/G/users"
)

# Sources locales (scripts PowerShell récupérés via SCP depuis DC01)
SOURCE_SCRIPTS_LOCAL="/backup/scripts"

# --- Initialisation ---
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"
LOG_FILE="$LOG_DIR/backup_$DATE.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "============================================================"
log " DÉBUT DE LA SAUVEGARDE — $DATE à $HEURE"
log "============================================================"

TOTAL_TAILLE=0
ERREURS=0

# ============================================================
# 1. SAUVEGARDE DES PARTAGES SAMBA (file01 → backup01)
# ============================================================
log ""
log "--- SAUVEGARDE DES PARTAGES SAMBA ---"

for SOURCE in "${SOURCES[@]}"; do
    NOM=$(basename "$SOURCE")
    DEST="$BACKUP_DIR/$NOM"
    mkdir -p "$DEST"

    log "Sauvegarde : $SOURCE_HOST:$SOURCE → $DEST"

    RSYNC_OUTPUT=$(rsync -avz --delete \
        -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
        "$SOURCE_HOST:$SOURCE/" \
        "$DEST/" 2>&1)

    RSYNC_EXIT=$?

    if [ $RSYNC_EXIT -eq 0 ]; then
        TAILLE=$(du -sh "$DEST" 2>/dev/null | cut -f1)
        log "[OK] $NOM — Taille : $TAILLE"
        TOTAL_TAILLE=$((TOTAL_TAILLE + $(du -sb "$DEST" 2>/dev/null | cut -f1)))
    else
        log "[ERREUR] $NOM — Code : $RSYNC_EXIT"
        log "$RSYNC_OUTPUT"
        ERREURS=$((ERREURS + 1))
    fi
done

# ============================================================
# 2. SAUVEGARDE DE LA CONFIGURATION RÉSEAU DE FILE01
# ============================================================
log ""
log "--- SAUVEGARDE CONFIGURATION RÉSEAU ---"

mkdir -p "$BACKUP_DIR/config-reseau"

rsync -avz --delete \
    -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    "$SOURCE_HOST:/etc/samba/smb.conf" \
    "$BACKUP_DIR/config-reseau/" >> "$LOG_FILE" 2>&1

rsync -avz --delete \
    -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    "$SOURCE_HOST:/etc/netplan/" \
    "$BACKUP_DIR/config-reseau/netplan/" >> "$LOG_FILE" 2>&1

rsync -avz --delete \
    -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    "$SOURCE_HOST:/etc/krb5.conf" \
    "$BACKUP_DIR/config-reseau/" >> "$LOG_FILE" 2>&1

log "[OK] Configuration réseau sauvegardée"

# ============================================================
# 3. SAUVEGARDE DES SCRIPTS POWERSHELL (depuis DC01 via SCP)
# ============================================================
log ""
log "--- SAUVEGARDE SCRIPTS POWERSHELL ---"

mkdir -p "$BACKUP_DIR/scripts-powershell"

# Récupération depuis DC01 (SSH doit être configuré sur DC01 aussi)
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
    "admindc@192.168.10.1:C:/Scripts/*.ps1" \
    "$BACKUP_DIR/scripts-powershell/" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log "[OK] Scripts PowerShell sauvegardés"
else
    log "[AVERT] Scripts PowerShell : vérifier SSH sur DC01"
fi

# ============================================================
# 4. NETTOYAGE — Suppression des sauvegardes trop anciennes
# ============================================================
log ""
log "--- NETTOYAGE (rétention : $RETENTION_JOURS jours) ---"

SUPPRIMEES=$(find /backup/daily -maxdepth 1 -type d -mtime +$RETENTION_JOURS)

if [ -n "$SUPPRIMEES" ]; then
    echo "$SUPPRIMEES" | while read -r DIR; do
        rm -rf "$DIR"
        log "[SUPPRIMÉ] $DIR"
    done
else
    log "Aucune ancienne sauvegarde à supprimer"
fi

# ============================================================
# 5. RÉSUMÉ FINAL
# ============================================================
log ""
log "============================================================"
log " RÉSUMÉ DE LA SAUVEGARDE"
log "------------------------------------------------------------"
log " Date         : $DATE"
log " Heure fin    : $(date +%H:%M:%S)"
log " Destination  : $BACKUP_DIR"
log " Taille totale: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
log " Erreurs      : $ERREURS"

if [ $ERREURS -eq 0 ]; then
    log " Résultat     : SUCCÈS"
else
    log " Résultat     : ÉCHEC PARTIEL ($ERREURS erreur(s))"
fi

log "============================================================"

exit $ERREURS
