date: 2026-08-26
statut: En cours (Finalisation TeamViewer)
source: HP EliteBook 650
cibles:
  - Lenovo ThinkPad
  - Lenovo ThinkCentre M50q
---

# Documentation Technique : Migration & Masterisation Multi-Postes

> [!INFO] Synthèse du projet
> Duplication de la session utilisateur complète (applications, fichiers, configurations) depuis un **HP EliteBook 650 (Win 11)** vers un **Lenovo ThinkPad** et un Mini PC **Lenovo ThinkCentre M50q**.

---

## 1. Procédure de Déploiement Exécutée

### A. Création & Restauration du Master (Acronis True Image)
1. Boot de la machine source (**HP EliteBook 650**) sur l'environnement **WinPE Sergei Strelec**.
2. Réalisation d'une image disque complète (`.tib` / `.tibx`) via **Acronis True Image** vers un HDD externe de 2 To.
3. Restauration sélective et réinjection de l'image sur :
   - Le SSD du **Lenovo ThinkPad**.
   - Le SSD du **Lenovo ThinkCentre M50q**.
4. Prise en charge automatique des pilotes de base (HAL / PnP) au premier démarrage sous Windows 11.

---

### B. Résolution des Conflits de Tokens Microsoft (Office / OneDrive)

> [!WARNING] Origine du problème
> Le changement de puce matérielle **TPM** entre la carte mère HP et les cartes mères Lenovo invalide les clés d'ancrage `WAM / OneAuth` de Microsoft.

**Résolution via script PowerShell de purge ciblée :**

```powershell
# Déblocage de la politique d'exécution pour la session
Set-ExecutionPolicy Bypass -Scope Process

# Fermeture des applications Microsoft actives
$apps = @("OneDrive", "outlook", "ms-teams", "Teams", "winword", "excel")
foreach ($app in$apps) { 
    Get-Process -Name $app -ErrorAction SilentlyContinue | Stop-Process -Force 
}

# Purge des dossiers de tokens d'identité Microsoft
$targetPaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneAuth",
    "$env:LOCALAPPDATA\Microsoft\IdentityCache",
    "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"
)

foreach ($path in$targetPaths) {
    if (Test-Path $path) { 
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue 
    }
}
