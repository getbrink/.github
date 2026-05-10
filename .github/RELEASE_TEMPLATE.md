# Release {{ version }}

This release ships a cosign-signed, SBOM-attested, SLSA Build Level 2 provenance-attested image.

## Image digest

| Image | Digest |
|---|---|
{{ image_digests }}

The signature is bound to the **digest**, not the tag. `:{{ version }}` and `:latest` resolve to the digest above today; if either is repointed in the future, the digest is the canonical reference.

## Verify the signature

Requires `cosign` **v2.6.0 or later** (`brew install cosign` / `apt install cosign` / [release page](https://github.com/sigstore/cosign/releases)).

```bash
{{ cosign_verify_command }}
```

Expected output:

```
Verification for ghcr.io/getbrink/{{ image_name }}@<digest> --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
```

## Verify the SBOM attestation (SPDX 2.3)

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp='^https://github.com/getbrink/[^/]+/\.github/workflows/release\.yml@refs/tags/v[0-9].*$' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/getbrink/{{ image_name }}:{{ version }}
```

## Verify the SLSA Build Level 2 provenance

```bash
cosign verify-attestation \
  --type slsaprovenance1 \
  --certificate-identity-regexp='^https://github.com/getbrink/[^/]+/\.github/workflows/release\.yml@refs/tags/v[0-9].*$' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/getbrink/{{ image_name }}:{{ version }}
```

## Third-party audit via Rekor

The signing event landed in the Sigstore Rekor public transparency log. Query it without any Brink-side infrastructure:

```bash
rekor-cli search --artifact ghcr.io/getbrink/{{ image_name }}@<digest>
```

## What the signature proves

The signature attests that this image was built by the `getbrink/.github` reusable release workflow, invoked from a `v*.*.*` tag push on a `getbrink/*` repository, by a GitHub Actions OIDC identity that GitHub issued at build time.

## What the signature does NOT prove

The signature does NOT prove the code is bug-free, secure, or fit for any particular purpose. It proves the image came from this release workflow — nothing more, nothing less. Reproducible-build verification (SLSA Build Level 3) is scheduled for v0.3.

## Supply-chain runbook

The full verification runbook with copy-paste commands and Kyverno admission policy examples lives in [`brink-docs/operations/supply-chain.md`](https://github.com/getbrink/brink-docs/blob/main/operations/supply-chain.md).
