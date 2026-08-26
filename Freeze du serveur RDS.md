## Informations Générales
- **Infrastructure Hôte :** Serveur Tour (16 cœurs / 16 vCPUs, 32 Go RAM)
- **Composants impactés :** Serveur RDS (Base de données + Serveur de données), Contrôleur de Domaine (DC), Hyperviseur Proxmox VE.
- **Symptôme :** Freeze constant et blocage du serveur RDS lors de l'utilisation intensive du logiciel métier.
- **Gravité :** Critique (Impact direct sur l'activité des utilisateurs).

---

## Diagnostic & Analyse de la Cause Racine (RCA)

Lors des pics d'activité et de connexions simultanées, le serveur RDS rencontrait des blocages sévères avec une saturation de ses ressources CPU à 100 %.

L'analyse de l'hyperviseur Proxmox VE a révélé une **allocation inadaptée des vCPUs** par rapport à la capacité du serveur physique (16 cœurs) :
- **Problème d'allocation initiale :** Le DC et le RDS disposaient chacun de 6 vCPUs.
- **Contrainte :** Le DC était surdimensionné (6 vCPUs pour des besoins d'authentification minimes), ce qui privait le serveur RDS (qui cumule les rôles de base de données métier, serveur de fichiers et serveur de sessions utilisateurs) de la puissance de calcul requise lors des pics de charge.

---

## Action Corrective & Réallocation des Ressources

Afin d'optimiser l'exploitation des 16 cœurs physiques de la machine tour et d'éliminer la saturation sur le RDS, une nouvelle répartition globale des cœurs vCPU a été appliquée :

| Composant / VM | vCPU Initiaux | Nouveau vCPU | Justification / Rôle |
| :--- | :--- | :--- | :--- |
| **DC (Domain Controller)** | 6 vCPUs | **2 vCPUs** | Ajustement aux besoins réels d'un DC (dimensionnement optimal). |
| **RDS (Remote Desktop)** | 6 vCPUs | **12 vCPUs** | Prise en charge des sessions utilisateurs, de la BDD métier et des données. |
| **Proxmox VE (Hôte)** | N/A | **2 vCPUs** | Marge de sécurité réservée pour le fonctionnement stable de l'hyperviseur. |
| **TOTAL HÔTE** | **12 vCPUs** | **16 vCPUs** | Utilization à 100 % des 16 cœurs disponibles sur le serveur tour. |

---

## Résultats & Validation

- **Résolution :** Suppression complète des freezes et blocages du RDS lors des pics d'utilisation du logiciel métier.
- **Stabilité :** Utilisation optimale de la capacité matérielle de l'hôte (16 cœurs) sans risque d'overcommit processeur excessif.
