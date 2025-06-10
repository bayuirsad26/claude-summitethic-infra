---
# scripts/secrets-rotation.sh
#!/bin/bash
# Automated secrets rotation for SummitEthic
# Ethical principle: Regular rotation prevents long-term exposure

set -euo pipefail

VAULT_ADDR="http://127.0.0.1:8200"
ROTATION_LOG="/var/log/summitethic/secrets-rotation.log"

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$ROTATION_LOG"
}

rotate_database_passwords() {
    log "Starting database password rotation..."
    
    # Generate new password
    NEW_PASSWORD=$(openssl rand -base64 32)
    
    # Update in Vault
    vault kv put secret/database/postgres \
        username=summitethic \
        password="$NEW_PASSWORD" \
        rotated_at="$(date -Iseconds)"
    
    # Update PostgreSQL
    docker exec postgres psql -U postgres -c \
        "ALTER USER summitethic WITH PASSWORD '$NEW_PASSWORD';"
    
    log "Database password rotation completed"
}

rotate_api_keys() {
    log "Starting API key rotation..."
    
    # Rotate each service API key
    for service in gitlab mautic traefik monitoring; do
        NEW_KEY=$(openssl rand -hex 32)
        
        vault kv put secret/api/$service \
            key="$NEW_KEY" \
            rotated_at="$(date -Iseconds)"
        
        # Trigger service update via Ansible
        ansible-playbook /opt/ansible/playbooks/update-api-key.yml \
            -e "service=$service" \
            -e "new_key=$NEW_KEY"
    done
    
    log "API key rotation completed"
}

rotate_certificates() {
    log "Starting certificate rotation check..."
    
    # Check certificate expiry
    for domain in $(traefik show certificates | jq -r '.[].domain'); do
        EXPIRY=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
                 openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
        EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
        NOW_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
        
        if [ $DAYS_LEFT -lt 30 ]; then
            log "Certificate for $domain expires in $DAYS_LEFT days, triggering renewal..."
            docker exec traefik traefik renew --domain "$domain"
        fi
    done
    
    log "Certificate rotation check completed"
}

# Main execution
main() {
    log "Starting SummitEthic secrets rotation..."
    
    # Ensure Vault is unsealed
    if ! vault status >/dev/null 2>&1; then
        log "ERROR: Vault is sealed or unreachable"
        exit 1
    fi
    
    rotate_database_passwords
    rotate_api_keys
    rotate_certificates
    
    # Send notification
    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-type: application/json' \
        -d '{
            "text": "Secrets rotation completed successfully",
            "attachments": [{
                "color": "good",
                "fields": [
                    {"title": "Type", "value": "Scheduled Rotation", "short": true},
                    {"title": "Time", "value": "'$(date -Iseconds)'", "short": true}
                ]
            }]
        }'
    
    log "Secrets rotation completed successfully"
}

# Run with lock to prevent concurrent executions
(
    flock -n 200 || { log "Another rotation is already running"; exit 1; }
    main
) 200>/var/lock/secrets-rotation.lock