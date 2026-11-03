# Object Storage Spike (Desk Research)

**Status:** Research only. No server, bucket or contract was created. MinIO stays local-development only.

**Full write-up:** `docs/phase-1/12-spike-results.md` §4 and `docs/phase-1/13-adrs/0006-production-object-storage.md`.

## Question

After the Phase 0 finding that MinIO OSS is archived/no longer maintained, which production object storage should TrueReport use for private evidence, guide images and PDFs?

## Shortlist

| Option | UAE location | S3 API | Licence/terms | Notes |
|---|---|---|---|---|
| AWS S3 `me-central-1` | Yes | Native S3 | AWS terms | Managed; strongest S3 feature set; cost to verify |
| OCI Object Storage `me-dubai-1` / `me-abudhabi-1` | Yes | S3 Compatibility API subset | Oracle terms | Managed; verify multipart/presign/object lock/lifecycle |
| Cloudflare R2 | No UAE jurisdiction (EU/US/FedRAMP) | S3 API | Cloudflare terms | Attractive egress; requires legal approval for EU/US storage |
| SeaweedFS | Self-hosted | S3 gateway | Apache-2.0 | Lighter self-hosted; ops burden |
| Garage | Self-hosted | S3 subset | AGPL-3.0 | Small-team friendly; AGPL/encryption review |
| Ceph RGW | Self-hosted | S3 subset | LGPL-2.1/3.0 | Mature at scale; heavy ops |
| MinIO OSS | Self-hosted | S3 | AGPL-3.0, archived | **Local dev only** |
| Backblaze B2 | No UAE region verified | S3-compatible | B2 terms | Cost reference ($6.95/TB/mo) |

## Recommendation

Pending D6: shortlist **AWS S3 UAE** and **OCI Object Storage UAE**. Keep **MinIO local-only**. Do not select until the Phase 2 proof and legal review of residency/contract terms.

## Not verified

Pricing/quotes, contracts, KMS/encryption configuration, residency guarantees, latency, feature parity, migration effort, self-hosted operational cost.

## Sources (accessed 3 Nov 2026)

- AWS S3 endpoints: https://docs.aws.amazon.com/general/latest/gr/s3.html
- AWS Regions: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions.html
- OCI regions: https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm
- OCI S3 Compatibility API: https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm
- Cloudflare R2 data location: https://developers.cloudflare.com/r2/reference/data-location/
- Cloudflare R2 data security: https://developers.cloudflare.com/r2/reference/data-security/
- Cloudflare R2 S3 API: https://developers.cloudflare.com/r2/api/s3/api/
- SeaweedFS: https://github.com/seaweedfs/seaweedfs
- Garage: https://garagehq.deuxfleurs.fr/intro.html
- Ceph license: https://github.com/ceph/ceph
- Ceph encryption: https://docs.ceph.com/en/latest/radosgw/encryption/
- Backblaze B2 pricing: https://www.backblaze.com/cloud-storage/pricing
