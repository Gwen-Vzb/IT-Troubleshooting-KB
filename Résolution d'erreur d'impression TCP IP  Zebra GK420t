**Date :** 20 août 2026

**Équipement concerné :** Zebra GK420t (Imprimante d'étiquettes)

**Environnement :** Windows 11 25H2 (Migration récente depuis Windows 10)

### **Problématique**

L'imprimante Zebra GK420t est fonctionnelle sur le PC A, mais remonte un statut **"En erreur"** sur le PC B et rejette tous les travaux d'impression.

- Aucun évènement pertinent dans l'**Observateur d'évènements** Windows.
    
- Impossible de détecter l'imprimante via un scan réseau (_Advanced IP Scanner_).
    

### **Actions initiales & Diagnostics (Échecs)**

- **Vérification OS :** Les deux postes sont en version Windows 11 25H2 (hypothèse de bug de build écartée).
    
- **Service d'impression :** Purge du spouleur d'impression et redémarrage des services.
    
- **Nettoyage profond :** Exécution d'un script de désinstallation complète (purgé du registre, nettoyage des pilotes, suppression des ports fantômes USB/IP).
    
- **Réinstallation :** Réinstallation propre via l'utilitaire _Zebra Setup Utilities_.
    
- **Résultat :** L'imprimante reste systématiquement bloquée en statut "Erreur".
    

### **Analyse de la cause racine**

**1. Inspection de la configuration du port (PowerShell)**

PowerShell

```
Get-PrinterPort -Name "LPR_Zebra-Technologies-ZTC-GK420t-P05d099e04.dcp.515.5f0a810001" | Format-List
```

- Constat : L'imprimante utilisait un port TCP/IP basé sur la résolution de nom mDNS/DNS (`Zebra-Technologies-ZTC-GK420t-P05d099e04.dcp`).
    

**2. Test de résolution de nom (DNS)**

DOS

```
ping Zebra-Technologies-ZTC-GK420t-P05d099e04.dcp
```

- **Résultat :** Échec de la résolution de nom sur le PC B. Le spouleur pointe vers un hôte inaccessible.
    

**3. Vérification de l'adresse IP et connectivité réseau**

- Récupération de l'adresse IP réelle via le PC A fonctionnel : `192.168.40.131`.
    
- Test de connectivité réseau (Ping) depuis le PC B :
    
    DOS
    
    ```
    ping 192.168.40.131
    ```
    
    - **Résultat :** Réponses ICMP OK. L'équipement est bien joignable en IP brute.
        

**4. Validation des ports d'écoute d'impression**

PowerShell

```
# Test du port standard RAW 9100
Test-NetConnection 192.168.40.131 -Port 9100
# PingSucceeded : True | TcpTestSucceeded : False (Port 9100 fermé/refusé)

# Test du port d'impression LPR 515
Test-NetConnection 192.168.40.131 -Port 515
# PingSucceeded : True | TcpTestSucceeded : True (Port 515 ouvert)
```

### **Solution appliquée**

1. Ouvrir les **Propriétés de l'imprimante** > Onglet **Ports** > **Configurer le port...**
    
2. Remplacer le nom d'hôte DNS par l'adresse IP fixe : `192.168.40.131`.
    
3. Basculer le protocole du port en **LPR** _(au lieu de RAW 9100)_.
    
4. Renseigner le nom de la file d'attente (Queue Name) : `PASSTHROUGH`.
    
5. Valider et appliquer les modifications.
    

### **Résultat**

- **Page de test Windows :** Impression réussie immédiatement.
    
- **Application Métier Client :** Impression d'étiquettes 100 % fonctionnelle.
