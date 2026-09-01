**Date :** 1er septembre 2026  
**Environnement :** Groupe de travail (Workgroup) / Réseau local avec équipements Omada  
**Statut :** Résolu  
**Tags :** `#networking` `#smb` `#windows` `#troubleshooting` `#gpo` `#dhcp`

---

## 📌 Description du Problème
Suite à une **coupure de courant générale**, les lecteurs réseau partagés de la cliente ne répondaient plus. (partages connectés via ip)
- Tentative d'accès via `gpupdate /force` inefficace (environnement Workgroup sans domaine).
- Code d'erreur Windows initial : `0x80004005` (Accès refusé / Erreur réseau non spécifiée).
- Erreur lors de la suppression/reconnexion dans la CMD : `Nom de périphérique local déjà utilisé` lors des tentatives sur la lettre `W:`.
- `net use` affichait des connexions réseau fantômes/déconnectées.

---

## 🔍 Diagnostic & Cause Racine

1. **Conflit d'Adresse IP (Bail DHCP non fixe) :**
   - Le PC hébergeant le partage (`SHARE`) utilisait une adresse IP fixée  `.102`
   - Lors de la remise sous tension, le routeur a réattribué l'adresse `.102` à une **antenne Wi-Fi TP-Link Omada**.
   - Rendant les raccourcis configurés en statique (`\\192.168.x.102\...`) inopérants.

2. **Avertissement de Passerelles Multiples (PC Hôte) :**
   - Tentative de reconfiguration de l'IP fixe bloquée par un avertissement de passerelles par défaut multiples (conflit de routage dû à des paramètres TCP/IPv4 avancés ou des cartes secondaires).

3. **Verrouillage de Session SMB Côté Client :**
   - L'Explorateur Windows et le service Workstation conservaient en cache l'attribution des lettres de lecteurs, provoquant l'erreur de périphérique déjà utilisé.

---

## 🛠️ Actions Réalisées

### 1. Sur le PC Hébergeur (Serveur de Partage / Hôte)
- **Nettoyage de la configuration réseau (TCP/IP) :**
  - Accès aux propriétés `ncpa.cpl` > IPv4 > *Paramètres avancés*.
  - Suppression des passerelles par défaut secondaires pour corriger l'avertissement de routage.
- **Réinitialisation du cache ARP et DNS :**
  cmd
  ipconfig /flushdns
  netsh interface ip delete arpcache
### 2. Sur le PC client
-  Reconnexion des lecteurs smb via le nom de la machine.
