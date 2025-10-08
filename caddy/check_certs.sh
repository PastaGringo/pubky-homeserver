#!/bin/bash

# Liste des domaines à vérifier
domains=(
    "roadky.pubky.fractalized.net"
    "code.fractalized.net"
    "picky.pubky.fractalized.net"
    "explorer.pubky.fractalized.net"
    "nexus.pubky.fractalized.net"
)

echo "Vérification des certificats SSL pour tous les domaines..."
echo "----------------------------------------"

for domain in "${domains[@]}"; do
    echo "Vérification de $domain:"
    echo "----------------------------------------"
    
    # Obtenir les informations du certificat
    cert_info=$(openssl s_client -connect "$domain":443 -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject)
    
    if [ $? -eq 0 ]; then
        echo "$cert_info"
        echo ""
        
        # Vérifier la date d'expiration
        expiry_date=$(echo "$cert_info" | grep 'notAfter' | cut -d'=' -f2)
        expiry_epoch=$(date -d "$expiry_date" +%s)
        current_epoch=$(date +%s)
        days_remaining=$(( ($expiry_epoch - $current_epoch) / 86400 ))
        
        echo "Jours restants avant expiration: $days_remaining"
    else
        echo "ERREUR: Impossible d'obtenir le certificat"
    fi
    
    echo "----------------------------------------"
done