# SummitEthic Infrastructure Documentation

## Gambaran Umum

Infrastruktur SummitEthic dirancang dengan prinsip-prinsip etika sebagai fondasi utama. Setiap komponen dibangun dengan mempertimbangkan transparansi, keamanan, privasi, dan keberlanjutan.

## Prinsip Etika yang Diterapkan

### 1. **Transparansi (Transparency)**
- Semua konfigurasi menggunakan Infrastructure as Code (IaC)
- Audit logging pada setiap perubahan sistem
- Dokumentasi yang komprehensif dan jelas
- Monitoring yang transparan dengan dashboard publik (dengan batasan keamanan)

### 2. **Keamanan (Security)**
- Zero-trust security model
- Enkripsi end-to-end untuk semua komunikasi
- Regular security scanning dan vulnerability assessment
- Principle of least privilege untuk semua akses

### 3. **Privasi (Privacy)**
- Data minimization - hanya mengumpulkan data yang diperlukan
- Retention policy yang ketat (30 hari untuk logs)
- Anonymization untuk data sensitif
- GDPR compliance built-in

### 4. **Keberlanjutan (Sustainability)**
- Resource-efficient container configurations
- Automatic scaling untuk menghindari over-provisioning
- Green coding practices
- Regular cleanup untuk unused resources

## Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare (DNS & CDN)                   │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Traefik (Reverse Proxy)                 │
│                    • Auto SSL (Let's Encrypt)               │
│                    • Rate Limiting                          │
│                    • Security Headers                       │
└─────────────────────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   GitLab CE   │    │    Mailcow    │    │    Mautic     │
│  (Source Code)│    │    (Email)    │    │  (Marketing)  │
└───────────────┘    └───────────────┘    └───────────────┘
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                          │
│                  • Frontend (Public)                        │
│                  • Backend (Internal)                       │
│                  • Monitoring (Isolated)                    │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Monitoring Stack                          │
│         • Prometheus (Metrics)                              │
│         • Grafana (Visualization)                           │
│         • Loki (Logs)                                       │
│         • Alertmanager (Notifications)                      │
└─────────────────────────────────────────────────────────────┘
```

## Implementasi Step-by-Step

### 1. Persiapan Awal

```bash
# Clone repository
git clone https://github.com/summitethic/infrastructure.git
cd infrastructure

# Install Ansible dependencies
ansible-galaxy install -r requirements.yml

# Prepare vault password
echo "your-secure-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Edit inventory
vim inventories/production/hosts.yml
```

### 2. Initial Server Setup

```bash
# Run initial setup playbook
ansible-playbook playbooks/initial-setup.yml -i inventories/production/hosts.yml

# Verify SSH hardening
ansible all -m command -a "sshd -T | grep -E 'permitrootlogin|passwordauthentication'" -i inventories/production/hosts.yml
```

### 3. Deploy Core Infrastructure

```bash
# Deploy complete infrastructure
ansible-playbook playbooks/site.yml -i inventories/production/hosts.yml

# Deploy specific components
ansible-playbook playbooks/site.yml -i inventories/production/hosts.yml --tags docker
ansible-playbook playbooks/site.yml -i inventories/production/hosts.yml --tags traefik
ansible-playbook playbooks/site.yml -i inventories/production/hosts.yml --tags monitoring
```

### 4. Verify Deployment

```bash
# Check service status
ansible all -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}'" -i inventories/production/hosts.yml

# Test SSL certificates
curl -I https://your-domain.com
curl -I https://traefik.your-domain.com
curl -I https://git.your-domain.com

# Check monitoring
curl -s https://metrics.your-domain.com/api/v1/query?query=up | jq .
```

## Security Best Practices

### 1. **Secrets Management**

```yaml
# Encrypt sensitive data with Ansible Vault
ansible-vault create vault/secrets.yml

# Structure for secrets.yml
vault_admin_email: admin@summitethic.com
vault_traefik_acme_email: ssl@summitethic.com
vault_traefik_dashboard_users:
  - username: admin
    password: "bcrypt-hashed-password"
vault_cloudflare_api_token: "your-cloudflare-api-token"
vault_backup_remote_location: "s3://backup-bucket/summitethic"
```

### 2. **Network Security**

```yaml
# UFW rules applied automatically
- SSH: Only from admin IP range
- HTTP/HTTPS: Public access
- Monitoring ports: Internal only
- Docker ports: Not exposed externally
```

### 3. **Container Security**

- All containers run with `no-new-privileges`
- Minimal capabilities assigned
- Read-only root filesystems where possible
- Regular vulnerability scanning with Trivy

## CI/CD Pipeline

### Pipeline Stages:

1. **Validate**: Code quality and dependency checks
2. **Security**: Vulnerability scanning and compliance checks
3. **Build**: Docker image creation with multi-stage builds
4. **Test**: Unit and integration testing
5. **Quality**: SonarQube analysis and license compliance
6. **Deploy**: Automated deployment with rollback capability
7. **Monitor**: Post-deployment health checks

### Ethical Considerations in CI/CD:

- **Signed Commits**: Required for protected branches
- **Audit Trail**: Every deployment logged with user and reason
- **Manual Approval**: Required for production deployments
- **Rollback Capability**: Instant rollback for failed deployments

## Monitoring dan Observability

### Metrics Collection:

```yaml
# Key metrics monitored
- System: CPU, Memory, Disk, Network
- Application: Response time, Error rate, Throughput
- Security: Failed auth attempts, Unauthorized access
- Compliance: Data retention, Personal data detection
```

### Alert Categories:

1. **Security Alerts**: Immediate notification to security team
2. **Performance Alerts**: Ops team notification
3. **Compliance Alerts**: Compliance team notification
4. **Availability Alerts**: On-call engineer notification

### Dashboard Access:

- Grafana: https://dashboard.your-domain.com
- Prometheus: https://metrics.your-domain.com
- Alertmanager: https://alerts.your-domain.com

## Backup dan Disaster Recovery

### Backup Strategy:

```bash
# Automated daily backups
0 2 * * * /opt/scripts/backup.sh

# Backup includes:
- GitLab repositories and database
- Mailcow emails and configuration
- Mautic database and files
- Monitoring data (30-day retention)
- System configuration
```

### Recovery Procedures:

1. **Service Failure**: Automatic restart with Docker
2. **Data Corruption**: Restore from latest backup
3. **Complete System Failure**: Rebuild from Ansible playbooks
4. **Security Breach**: Isolated recovery with fresh credentials

## Maintenance dan Updates

### Regular Maintenance:

```bash
# Weekly security updates
ansible-playbook playbooks/security-updates.yml

# Monthly certificate renewal check
ansible-playbook playbooks/cert-renewal.yml

# Quarterly security audit
ansible-playbook playbooks/security-audit.yml
```

### Update Procedures:

1. Test updates in staging environment
2. Create backup before production update
3. Apply updates during maintenance window
4. Verify all services after update
5. Document any issues or changes

## Troubleshooting

### Common Issues:

1. **SSL Certificate Issues**
   ```bash
   docker exec traefik cat /certs/acme.json | jq .
   docker logs traefik | grep -i "certificate"
   ```

2. **Service Down**
   ```bash
   docker ps -a | grep <service-name>
   docker logs <container-name>
   ansible-playbook playbooks/restart-service.yml -e "service=<service-name>"
   ```

3. **High Resource Usage**
   ```bash
   docker stats --no-stream
   docker system prune -a --volumes
   ```

## Compliance dan Audit

### GDPR Compliance:

- Data minimization implemented
- Right to erasure supported
- Data portability available
- Privacy by design principles

### Audit Logs:

All audit logs stored in:
- System: `/var/log/audit/audit.log`
- Docker: `/var/log/docker-audit.log`
- Application: `/var/log/summitethic/`

### Compliance Reports:

Generated monthly:
- Security compliance report
- Data retention compliance
- Access control audit
- Vulnerability assessment

## Contact dan Support

- **Technical Issues**: tech@summitethic.com
- **Security Concerns**: security@summitethic.com
- **Compliance Questions**: compliance@summitethic.com
- **Emergency**: +62-xxx-xxxx-xxxx (24/7 on-call)

## Appendix

### A. Environment Variables

```bash
# Required environment variables
DOMAIN_NAME=summitethic.com
CLOUDFLARE_EMAIL=admin@summitethic.com
CLOUDFLARE_API_TOKEN=<your-token>
GITLAB_ADMIN_PASSWORD=<secure-password>
GRAFANA_ADMIN_PASSWORD=<secure-password>
SMTP_PASSWORD=<secure-password>
```

### B. Network Diagram

```
Internet → Cloudflare → VPS (Traefik) → Docker Services
                              ↓
                        Internal Network
                              ↓
                    [Frontend] [Backend] [Monitoring]
```

### C. Useful Commands

```bash
# View all container logs
docker-compose logs -f

# Restart specific service
docker-compose restart <service-name>

# Check disk usage
df -h
docker system df

# Monitor real-time metrics
docker stats

# View Traefik routes
curl -s http://localhost:8080/api/http/routers | jq .
```

---

**Last Updated**: {{ ansible_date_time.date }}
**Version**: 1.0.0
**Maintained by**: SummitEthic DevOps Team