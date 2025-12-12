# Security Policy

## Supported Versions

The following versions of verify-github-workflow-action are currently supported with
security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of verify-github-workflow-action seriously. If you discover a
security vulnerability, please follow these steps:

### Where to Report

Please report security vulnerabilities by emailing
[durand.tibo+gh@gmail.com](mailto:durand.tibo+gh@gmail.com).

**Do NOT report security vulnerabilities through public GitHub issues.**

### What to Include

When reporting a vulnerability, please include:

- A description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Any suggested fixes or mitigations (if available)
- Your contact information for follow-up

### What to Expect

After submitting a vulnerability report:

1. **Acknowledgment**: You will receive an acknowledgment within 48 hours confirming we
   received your report.

2. **Assessment**: We will assess the vulnerability and determine its severity and impact.
   This typically takes 3-5 business days.

3. **Updates**: We will keep you informed of our progress as we work on a fix. You can
   expect updates at least every 7 days.

4. **Resolution**: Once a fix is ready, we will:
   - Notify you before the fix is publicly released
   - Credit you for the discovery (unless you prefer to remain anonymous)
   - Release the fix and a security advisory

### Security Best Practices

When using this action, we recommend:

1. **Pin to Specific Versions**: Use a specific version tag (e.g., `@v0.0.1`) instead of
   `@main` to avoid unexpected changes.

2. **Review Changes**: When updating to a new version, review the changes in the release
   notes.

3. **Minimal Permissions**: Grant only the necessary permissions to the action in your
   workflows.

4. **Regular Updates**: Keep the action updated to the latest version to benefit from
   security patches.

5. **Audit Workflows**: Regularly review your workflows to ensure they follow security
   best practices.

## Security Features

This action includes the following security measures:

- **No External Network Calls**: Apart from downloading actionlint from the official
  repository, the action makes no external network calls.

- **Read-Only by Default**: The action only reads workflow files and does not modify
  any files in your repository.

- **Minimal Dependencies**: The action has minimal dependencies, reducing the attack
  surface.

- **Transparent Operations**: All operations performed by the action are visible in
  the workflow logs.

## Dependency Security

We regularly update dependencies to address known vulnerabilities:

- Dependencies are reviewed and updated as part of our regular maintenance cycle
- Automated security updates are enabled via Dependabot
- Critical security updates are prioritized and released promptly

## Disclosure Policy

When we receive a security vulnerability report:

1. We will work to verify and address the issue promptly
2. We will not disclose the vulnerability publicly until a fix is available
3. We will coordinate the disclosure timeline with the reporter
4. We will publicly acknowledge reporters who wish to be credited

Thank you for helping to keep verify-github-workflow-action and its users safe!
