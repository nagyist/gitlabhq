---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Data management API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/537707) in GitLab 18.3 with a [flag](../../administration/feature_flags/_index.md) named `geo_primary_verification_view`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use the data management API to manage an instance's data.

Prerequisites:

- You must be an administrator.

## Get information about a model

This endpoint is an [experiment](../../policy/development_stages_support.md) and might be changed or removed without notice.

```plaintext
GET /admin/data_management/:model_name
```

The `:model_name` parameter must be one of:

- `ci_job_artifact`
- `ci_pipeline_artifact`
- `ci_secure_file`
- `container_repository`
- `dependency_proxy_blob`
- `dependency_proxy_manifest`
- `design_management_repository`
- `group_wiki_repository`
- `lfs_object`
- `merge_request_diff`
- `packages_package_file`
- `pages_deployment`
- `project`
- `projects_wiki_repository`
- `snippet_repository`
- `terraform_state_version`
- `upload`

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the model. It includes the following
response attributes:

| Attribute              | Type      | Description                                      |
|------------------------|-----------|--------------------------------------------------|
| `checksum_information` | JSON      | Geo-specific checksum information, if available. |
| `created_at`           | timestamp | Creation timestamp, if available.                |
| `id`                   | integer   | Unique ID of the record.                         |
| `model_class`          | string    | Class name of the model.                         |
| `file_size`            | integer   | Size of the object, if available.                |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/project"
```

Example response:

```json
[
  {
    "id": 1,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:10.173Z",
    "size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.643Z",
      "checksum_state": 2,
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  },
  {
    "id": 2,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:14.402Z",
    "size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.214Z",
      "checksum_state": 2,
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  }
]
```
