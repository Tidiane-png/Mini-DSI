# ============================================================
#  Create-AD.ps1
#  Création des OU, groupes et utilisateurs pour entreprise.local
#  À exécuter sur DC01 en tant qu'Administrateur
# ============================================================

# --- Configuration ---
$Domaine     = "entreprise.local"
$DC          = "DC=entreprise,DC=local"
$OURacine    = "OU=Entreprise,$DC"
$RapportPath = "C:\Rapports\rapport_creation_ad.txt"
$MotDePasseDefaut = ConvertTo-SecureString "Bienvenue@2024!" -AsPlainText -Force

# Créer le dossier rapport
New-Item -ItemType Directory -Path "C:\Rapports" -Force | Out-Null

$Rapport = @()
$Rapport += "============================================================"
$Rapport += " RAPPORT DE CRÉATION ACTIVE DIRECTORY"
$Rapport += " Date : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Rapport += " Domaine : $Domaine"
$Rapport += "============================================================"
$Rapport += ""

# ============================================================
# 1. CRÉATION DES UNITÉS D'ORGANISATION (OU)
# ============================================================
$Rapport += "--- UNITÉS D'ORGANISATION ---"

$OUs = @(
    @{ Nom = "Entreprise";  Parent = $DC },
    @{ Nom = "Direction";   Parent = $OURacine },
    @{ Nom = "Technique";   Parent = $OURacine },
    @{ Nom = "Commercial";  Parent = $OURacine }
)

foreach ($OU in $OUs) {
    $chemin = "OU=$($OU.Nom),$($OU.Parent)"
    try {
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$chemin'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $OU.Nom -Path $OU.Parent -ProtectedFromAccidentalDeletion $false
            $Rapport += "[OK] OU créée : $chemin"
        } else {
            $Rapport += "[EXISTE] OU déjà présente : $chemin"
        }
    } catch {
        $Rapport += "[ERREUR] OU $($OU.Nom) : $_"
    }
}

$Rapport += ""

# ============================================================
# 2. CRÉATION DES GROUPES DE SÉCURITÉ
# ============================================================
$Rapport += "--- GROUPES DE SÉCURITÉ ---"

$Groupes = @(
    @{ Nom = "GRP_Direction";  OU = "OU=Direction,$OURacine";  Description = "Groupe sécurité Direction" },
    @{ Nom = "GRP_Technique";  OU = "OU=Technique,$OURacine";  Description = "Groupe sécurité Technique" },
    @{ Nom = "GRP_Commercial"; OU = "OU=Commercial,$OURacine"; Description = "Groupe sécurité Commercial" }
)

foreach ($Groupe in $Groupes) {
    try {
        if (-not (Get-ADGroup -Filter "Name -eq '$($Groupe.Nom)'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $Groupe.Nom `
                        -GroupScope Global `
                        -GroupCategory Security `
                        -Path $Groupe.OU `
                        -Description $Groupe.Description
            $Rapport += "[OK] Groupe créé : $($Groupe.Nom)"
        } else {
            $Rapport += "[EXISTE] Groupe déjà présent : $($Groupe.Nom)"
        }
    } catch {
        $Rapport += "[ERREUR] Groupe $($Groupe.Nom) : $_"
    }
}

$Rapport += ""

# ============================================================
# 3. CRÉATION DES UTILISATEURS
# ============================================================
$Rapport += "--- UTILISATEURS ---"

# 5 Direction / 5 Technique / 5 Commercial = 15 utilisateurs
$Utilisateurs = @(
    # Direction
    @{ Prenom="Alice";   Nom="Martin";   Service="Direction";  Groupe="GRP_Direction"  },
    @{ Prenom="Bernard"; Nom="Dupont";   Service="Direction";  Groupe="GRP_Direction"  },
    @{ Prenom="Claire";  Nom="Leroy";    Service="Direction";  Groupe="GRP_Direction"  },
    @{ Prenom="David";   Nom="Moreau";   Service="Direction";  Groupe="GRP_Direction"  },
    @{ Prenom="Emma";    Nom="Simon";    Service="Direction";  Groupe="GRP_Direction"  },
    # Technique
    @{ Prenom="Fabien";  Nom="Laurent";  Service="Technique";  Groupe="GRP_Technique"  },
    @{ Prenom="Grace";   Nom="Michel";   Service="Technique";  Groupe="GRP_Technique"  },
    @{ Prenom="Hugo";    Nom="Garcia";   Service="Technique";  Groupe="GRP_Technique"  },
    @{ Prenom="Inès";    Nom="Bernard";  Service="Technique";  Groupe="GRP_Technique"  },
    @{ Prenom="Julien";  Nom="Thomas";   Service="Technique";  Groupe="GRP_Technique"  },
    # Commercial
    @{ Prenom="Karine";  Nom="Robert";   Service="Commercial"; Groupe="GRP_Commercial" },
    @{ Prenom="Lucas";   Nom="Petit";    Service="Commercial"; Groupe="GRP_Commercial" },
    @{ Prenom="Marie";   Nom="Durand";   Service="Commercial"; Groupe="GRP_Commercial" },
    @{ Prenom="Nicolas"; Nom="Roux";     Service="Commercial"; Groupe="GRP_Commercial" },
    @{ Prenom="Océane";  Nom="Vincent";  Service="Commercial"; Groupe="GRP_Commercial" }
)

foreach ($U in $Utilisateurs) {
    $Login    = ($U.Prenom.Substring(0,1) + $U.Nom).ToLower() -replace "[^a-z0-9]",""
    $UPN      = "$Login@$Domaine"
    $OUPath   = "OU=$($U.Service),$OURacine"
    $NomComplet = "$($U.Prenom) $($U.Nom)"

    try {
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$Login'" -ErrorAction SilentlyContinue)) {
            New-ADUser -SamAccountName $Login `
                       -UserPrincipalName $UPN `
                       -Name $NomComplet `
                       -GivenName $U.Prenom `
                       -Surname $U.Nom `
                       -DisplayName $NomComplet `
                       -Department $U.Service `
                       -Path $OUPath `
                       -AccountPassword $MotDePasseDefaut `
                       -PasswordNeverExpires $false `
                       -ChangePasswordAtLogon $true `
                       -Enabled $true

            Add-ADGroupMember -Identity $U.Groupe -Members $Login
            $Rapport += "[OK] Utilisateur : $NomComplet | Login : $Login | Service : $($U.Service)"
        } else {
            $Rapport += "[EXISTE] Utilisateur déjà présent : $Login"
        }
    } catch {
        $Rapport += "[ERREUR] Utilisateur $Login : $_"
    }
}

$Rapport += ""

# ============================================================
# 4. RÉSUMÉ
# ============================================================
$Rapport += "--- RÉSUMÉ ---"
$Rapport += "OUs créées     : $(($OUs).Count)"
$Rapport += "Groupes créés  : $(($Groupes).Count)"
$Rapport += "Utilisateurs   : $(($Utilisateurs).Count)"
$Rapport += ""
$Rapport += "Mot de passe par défaut : Bienvenue@2024!"
$Rapport += "Les utilisateurs devront changer leur mot de passe à la première connexion."
$Rapport += ""
$Rapport += "Fin du rapport : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Rapport += "============================================================"

# Écriture du rapport
$Rapport | Out-File -FilePath $RapportPath -Encoding UTF8
$Rapport | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "Rapport sauvegardé : $RapportPath" -ForegroundColor Green
