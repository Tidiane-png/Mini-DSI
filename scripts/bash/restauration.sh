#!/bin/bash
# ============================================================
#  restauration.sh
#  Procédure de restauration des données sauvegardées
#  Usage : sudo ./restauration.sh [fichier|dossier|partage] [date] [cible]
# ============================================================

BACKUP_BASE="/backup/daily"
LOG_FILE="/backup/logs/restauration_$(date +%Y-%m-%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

afficher_aide() {
    echo ""
    echo "Usage : sudo $0 <mode> <date_backup> <source> [destination]"
    echo ""
    echo "Modes :"
    echo "  fichier   Restaure un fichier unique"
    echo "  dossier   Restaure un dossier complet"
    echo "  partage   Restaure un partage entier vers file01"
    echo ""
    echo "Exemples :"
    echo "  $0 fichier 2024-01-15 Direction/rapport.docx /tmp/restaure/"
    echo "  $0 dossier 2024-01-15 Technique/projets /tmp/restaure/"
    echo "  $0 partage 2024-01-15 Commercial adminfile@192.168.10.2:/media/G/Commercial"
    echo ""
}

MODE=$1
DATE_BACKUP=$2
SOURCE_REL=$3
DESTINATION=$4

if [ -z "$MODE" ] || [ -z "$DATE_BACKUP" ] || [ -z "$SOURCE_REL" ]; then
    afficher_aide
    exit 1
fi

BACKUP_DIR="$BACKUP_BASE/$DATE_BACKUP"

if [ ! -d "$BACKUP_DIR" ]; then
    log "[ERREUR] Sauvegarde introuvable pour la date : $DATE_BACKUP"
    log "Sauvegardes disponibles :"
    ls "$BACKUP_BASE" | tee -a "$LOG_FILE"
    exit 1
fi

DEBUT=$(date +%s)
log "============================================================"
log " DÉBUT RESTAURATION — Mode : $MODE"
log " Date sauvegarde : $DATE_BACKUP"
log " Source : $BACKUP_DIR/$SOURCE_REL"
log "============================================================"

case $MODE in

    fichier)
        SOURCE_COMPLET="$BACKUP_DIR/$SOURCE_REL"
        if [ ! -f "$SOURCE_COMPLET" ]; then
            log "[ERREUR] Fichier introuvable : $SOURCE_COMPLET"
            exit 1
        fi
        mkdir -p "$DESTINATION"
        cp -v "$SOURCE_COMPLET" "$DESTINATION" 2>&1 | tee -a "$LOG_FILE"
        log "[OK] Fichier restauré dans : $DESTINATION"
        ;;

    dossier)
        SOURCE_COMPLET="$BACKUP_DIR/$SOURCE_REL"
        if [ ! -d "$SOURCE_COMPLET" ]; then
            log "[ERREUR] Dossier introuvable : $SOURCE_COMPLET"
            exit 1
        fi
        mkdir -p "$DESTINATION"
        rsync -av "$SOURCE_COMPLET/" "$DESTINATION/" 2>&1 | tee -a "$LOG_FILE"
        log "[OK] Dossier restauré dans : $DESTINATION"
        ;;

    partage)
        SOURCE_COMPLET="$BACKUP_DIR/$SOURCE_REL"
        if [ ! -d "$SOURCE_COMPLET" ]; then
            log "[ERREUR] Partage introuvable : $SOURCE_COMPLET"
            exit 1
        fi
        SSH_KEY="/root/.ssh/id_backup"
        rsync -avz --delete \
            -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
            "$SOURCE_COMPLET/" \
            "$DESTINATION/" 2>&1 | tee -a "$LOG_FILE"
        log "[OK] Partage restauré vers : $DESTINATION"
        ;;

    *)
        log "[ERREUR] Mode inconnu : $MODE"
        afficher_aide
        exit 1
        ;;
esac

FIN=$(date +%s)
DUREE=$((FIN - DEBUT))

log ""
log "============================================================"
log " RESTAURATION TERMINÉE"
log " Durée : ${DUREE} secondes"
log " Log   : $LOG_FILE"
log "============================================================"
