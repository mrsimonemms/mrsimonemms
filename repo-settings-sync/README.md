# repo-settings-sync

<!-- toc -->

* [Getting started](#getting-started)
  * [Personal Access Token](#personal-access-token)
  * [Customisation](#customisation)
    * [Ignoring](#ignoring)
    * [Repo](#repo)
    * [Branch Protection Settings](#branch-protection-settings)
      * [required_status_checks](#required_status_checks)
* [Contributing](#contributing)
  * [Open in a container](#open-in-a-container)

<!-- Regenerate with "pre-commit run -a markdown-toc" -->

<!-- tocstop -->

Sync all settings across repositories

## Getting started

The purpose of this repo is to allow for consistency in how a repository owner
configures their projects. As GitHub does not allow owners to have "default settings"
for their projects, this exists to provide that functionality.

At the moment, this only provides [repository settings](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#update-a-repository)
but is written with a view to allowing additional configurations, such as branch
protection policies.

This repository is designed to be used once per owner - the simplest way to get
started is to fork this repository into each owner's account. This works for both
users and organisations so can be forked into both.

### Personal Access Token

You will need to provide a [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
in order for this to work. This requires the following permissions:

* Administration: read and write
* Contents: read-only
* Metadata: read-only

This has only been tested using the fine-grained tokens rather than the classic
tokens. However, the `repo` scope should work fine.

### Customisation

The script searches for a `.github-settings.json` file at the root of the default
branch (typically, `main` or `master`). If this file exists then it combines this
with the default [settings.json](./settings.json) file in this repository.

#### Ignoring

Sometimes, you don't want a repository to be managed. In that case, just set your
`.github-settings.json` like this:

```json
{
  "ignore": true
}
```

#### Repo

Anything in the `repo` section is added to the body for
[updating a repository's settings](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#update-a-repository).

#### Branch Protection Settings

Anything in the `branch_protection` section is added to the body for
[updating branch protection](https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection).

##### required_status_checks

The `required_status_checks` are a required field in the API endpoint. This is
problematic for us as this is highly nuanced on a per-repository basis.

The default settings are that the branches must be up to date, but there are
no checks added. If you manually add a check in via the GitHub settings page,
this will be persisted.

If you add any configuration in your `.github-settings.json` file, these will
take priority over the GitHub settings page.

## Contributing

### Open in a container

* [Open in a container](https://code.visualstudio.com/docs/devcontainers/containers)
