**Date:** 2 Septembre 2026  (suite d'intervention freeze RDS)

**Infrastructure:** Server Windows RDS (12 vCPU, 16 Go RAM, Disque SSD C:)  

**Application Métier:** DBFact (Legacy / Ex-Sage)  

**Auteur:** Support / Infrastructure IT  

  

---

  

## 1. Contexte & Problématique Initiales

  

### Symptômes observés

- L'application métier **DBFact** se bloquait régulièrement (entre 1 et 10 fois par jour), provoquant des gélonnements complets pour l'ensemble des utilisateurs métier.

- Suspicion initiale d'une saturation du processeur (**CPU à 100 %**) sur l'hôte RDS de 12 vCPU.

- Tentatives d'actions préalables sans effet : Réinstallation des bibliothèques `.NET Framework` et des redistribuables `Visual C++` (ces composants gèrent les dépendances au lancement mais n'influent pas sur la gestion multi-thread ou l'utilisation CPU/disque à chaud).

  

---

  

## 2. Analyse Technique & Diagnostic

  

L'analyse de la télémétrie système (capture du Gestionnaire des tâches et du Moniteur de ressources `resmon`) a révélé **trois causes racines combinées** :

  

```

[ Session Unique / DBFact SMB ] ────┐

                                   ├──> [ Saturation SSD C: (97-100%) ] ──> [ Gel DBFact (E/S Disque) ]

[ Chrome / IA Locale + RAM Swap ] ─┘

```

  

### A. Nature de l'Application DBFact (Architecture xBase / FoxPro)

- **Monothread par session :** DBFact repose sur un moteur applicatif monothread (`dbfactw.exe`). Chaque traitement lourd s'exécute sur 1 seul vCPU (env. 8,3 % de la charge totale d'un 12 vCPU).

- **Architecture basée sur des fichiers (`.dbf`) :** DBFact ne fonctionne pas avec un service SQL isolé en mémoire, mais lit/écrit directement dans des fichiers plats sur le disque partagé via le protocole réseau **SMB**.

  

### B. Saturation du SSD C: (Lectures/Écritures E/S à 97 % - 100 %)

La capture d'écran a démontré que le CPU global n'était qu'à **5 %**, mais que le **Disque 0 (C: SSD)** subissait une saturation quasi totale à **97 % - 100 %**.

- **Conflits de verrous (File Locks) :** Plusieurs utilisateurs physiques travaillaient à travers des sessions locales avec un partage de comptes/ressources identiques, générant des boucles d'attente d'accès aux répertoires temporaires et aux bases de données.

- **Accès concourants SMB :** Chaque rapport ou recherche métier forçait le serveur à balayer des millions d'enregistrements directement sur le SSD.

  

### C. Empreinte Mémoire de Google Chrome & IA Locale (`Gemini Nano`)

- **Pression sur la mémoire RAM :** Avec 16 Go de RAM totale sur le serveur et 8,7 Go+ consommés au repos, Chrome monopolisait jusqu'à **3 Go+ de RAM** sur la session RDS admin/utilisateur.

- **Composant IA Intégré (*Optimization Guide On Device Model*) :**

  - Chrome intègre un moteur d'IA locale (*Gemini Nano* / *Built-in AI*).

  - Version détectée sur le serveur : `Optimization Guide On Device Models Manifest - Version : 1.20260810.11`.

  - En l'absence de GPU dédié sur le serveur RDS, l'IA s'exécute via CPU/RAM et télécharge un modèle lourd (~4 Go).

  - **Effet mémoire virtuelle (Paging) :** La saturation de la RAM a forcé Windows à faire du *swap* continu sur le SSD C: (`pagefile.sys`), bloquant les E/S du disque et paralysant les accès aux fichiers DBFact.

  

---

  

## 3. Actions Correctives Appliquées

  

### Step 1: Neutralisation de l'IA Locale de Google Chrome

  

#### A. Paramétrage des Options Chrome

- Désactivation des fonctionnalités d'IA avancées et d'assistance dans **Paramètres > Système / Performance**.

- Désactivation de l'accélération matérielle (pour éviter le passage en émulation CPU/RAM sur serveur sans GPU).

  

#### B. Verrouillage Système par le Registre Windows (HKLM)

Afin d'empêcher tout re-téléchargement ou activation de l'IA par un utilisateur sur le RDS, application de la stratégie de groupe via la clé de registre suivante :

  

```powershell

# Commande d'application (Invite de commande / PowerShell Administrateur)

reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v GenAILocalFoundationalModelSettings /t REG_DWORD /d 1 /f

```

  

*Note : La valeur `1` désactive de manière permanente le modèle d'IA locale (`GenAILocalFoundationalModelSettings`) pour l'ensemble des sessions de la machine.*

  

#### C. Nettoyage & Vérifications

- **Vérification du Composant :** Contrôle via `chrome://components/` (`Optimization Guide On Device Model`).

- **Validation des Stratégies :** Contrôle via `chrome://policy` (recharge des règles pour confirmer l'état *Disabled*).

- **Contrôle AppData :** Confirmation qu'aucun modèle de 4 Go n'était conservé sous `AppData\Local\Google\Chrome\User Data\Default\OptGuideOnDeviceModel`.

  

---

  

## 4. Recommandations & Bonnes Pratiques Complémentaires

  

Pour pérennisations de l'environnement RDS et prévention de futurs gels DBFact :

  

1. **Exclusions Antivirus (Prioritaire) :**

   Exclure impérativement les dossiers de base de données DBFact et les extensions suivantes du scan en temps réel de l'antivirus serveur :

   - `.dbf` (Fichiers de données)

   - `.cdx` / `.idx` (Index)

   - `.fpt` (Champs mémo)

   - `.idc`

  

2. **Isolation des Sessions Utilisateurs :**

   S'assurer que chaque utilisateur physique se connecte avec son **propre compte Windows RDS dédié**. Ne pas partager de session Windows unique pour éviter les conflits dans le dossier `AppData\Local\Temp`.

  

3. **Optimisation des Paramètres Navigateur sur RDS :**

   - Activer l'**Économiseur de mémoire** dans Chrome (*Memory Saver*).

   - Désactiver l'option *"Poursuivre l'exécution des applications en arrière-plan après la fermeture de Google Chrome"*.

  

4. **Supervision des Ressources :**

   Surveiller la file d'attente du disque (*Disk Queue Length*) dans `resmon` (onglet **Disque**) lors des pics d'activité DBFact pour garantir que les temps de réponse SSD restent inférieurs à 10 ms.
