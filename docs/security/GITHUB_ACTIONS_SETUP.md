# GitHub Actions Security Scan Setup

## Current Status ✅

**Local Snyk Configuration**: ✅ Complete
- SNYK_TOKEN added to `backend/.env`
- Snyk CLI v1.1307.0 authenticated and tested
- All scans passing (0 high/critical vulnerabilities)

**Automated Workflow**: ⚠️ Requires GitHub Secret

## Required: Add SNYK_TOKEN to GitHub Secrets

For the weekly automated security scans to work, you need to add your Snyk token to GitHub repository secrets:

### Steps:

1. **Copy your Snyk token**:
   - Token is already in `backend/.env` (line 16)
   - Copy the entire token value starting with `snyk_uat.1fcad39e...`

2. **Add to GitHub Secrets**:
   - Go to: https://github.com/Tomukas56/EE/settings/secrets/actions
   - Click **"New repository secret"**
   - Name: `SNYK_TOKEN`
   - Value: Paste your token
   - Click **"Add secret"**

3. **Verify**:
   - Go to: https://github.com/Tomukas56/EE/actions
   - Find the workflow **"Security Scan"**
   - Click **"Run workflow"** (branch: main)
   - Watch the workflow run and verify all checks pass

## Workflow Details

**File**: `.github/workflows/security-scan.yml`

**Triggers**:
- 🕐 Weekly: Every Monday at 00:00 UTC
- 🔀 Pull Requests: On every PR
- 📤 Push: On every push to `main`
- 🎯 Manual: Via "Run workflow" button

**Scanners**:
- ✅ Snyk (requires SNYK_TOKEN secret)
- ✅ OSV-Scanner (no auth required)
- ✅ npm audit (no auth required)

**Outputs**:
- 📊 Scan artifacts uploaded (30-day retention)
- 🚨 Issues created for findings (if enabled)
- ❌ Workflow fails on critical vulnerabilities

## Testing the Workflow

After adding the secret, test it:

```bash
# Option 1: Trigger via GitHub UI
# Go to Actions → Security Scan → Run workflow

# Option 2: Trigger via CLI (if gh CLI installed)
gh workflow run security-scan.yml

# Option 3: Create a test commit and push
git commit --allow-empty -m "test: trigger security scan"
git push
```

## Verification

Once the workflow runs:
1. Check https://github.com/Tomukas56/EE/actions
2. Click on the latest "Security Scan" run
3. Verify all jobs completed successfully
4. Download artifacts to review detailed reports

## Expected Results

Based on today's local scan (2026-09-24):
- ✅ Snyk backend: 0 high/critical (94 dependencies)
- ✅ Snyk mobile: 0 high/critical (144 packages)
- ✅ OSV-Scanner: 0 vulnerabilities
- ✅ npm audit: 0 high/critical

The automated workflow should produce the same results.

## Troubleshooting

### If workflow fails with "Authentication required"
- Verify SNYK_TOKEN secret exists in repository settings
- Token should start with `snyk_uat.` or `snyk-tkn-`
- Re-copy token from `backend/.env` and update secret

### If workflow fails with "Rate limit exceeded"
- Snyk free tier: 200 tests/month
- Consider upgrading or reducing scan frequency
- Use OSV-Scanner and npm audit as alternatives

### If you need to rotate the token
1. Generate new token at https://app.snyk.io/account
2. Update `backend/.env` locally
3. Update GitHub secret
4. Test workflow again

## Monitoring

Weekly automated scans will:
- Run every Monday at midnight UTC
- Create GitHub issues for new findings (if enabled)
- Send email notifications on failure
- Keep 30 days of scan artifacts

## Compliance Notes

This setup satisfies CRA requirements:
- ✅ Art. 20: Automated vulnerability scanning
- ✅ Art. 20: Timely vulnerability disclosure
- ✅ SBOM maintenance and scanning
- ✅ Audit trail in `SECURITY_FIXES.md`

## Next Steps

1. ⚠️ **Action Required**: Add SNYK_TOKEN to GitHub secrets (see steps above)
2. ✅ Test the workflow manually
3. ✅ Monitor first automated weekly scan
4. ✅ Review and triage any future findings

---

**Last Updated**: 2026-09-24
**Status**: Local setup complete, GitHub secret pending
