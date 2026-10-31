# CruelAddict's Homebrew tap

A Homebrew tap is an additional package catalogue maintained in a GitHub
repository. This one contains package descriptions for my software: where to
download a release, its SHA-256 checksum, and how Homebrew should install it.
Homebrew can add the tap automatically when a package is installed by its full
name.

The application source and release archives stay in their original repository.
This tap tracks stable releases, so installation, upgrades and removal use the
usual Homebrew commands. The update workflow authenticates resh's GitHub build
provenance before publishing each package version.

## resh

The formula is generated from resh's first immutable, attested stable release.
If `Formula/resh.rb` is not present yet, that release is still pending and the
installation command below is not yet available.

```sh
brew install CruelAddict/tap/resh
```

Requires macOS 15+ and [Rex](https://www.superlogical.com/). After installation,
follow `brew info CruelAddict/tap/resh` to connect resh to Rex. Homebrew owns the
installed executable and resources; connecting to Rex is an explicit user step.
`zoxide` and `fd` are optional directory-source tools.

```sh
brew upgrade CruelAddict/tap/resh
```

After upgrading, run `rex config reload` and `resh service restart`. Before
uninstalling, stop resh with `resh service stop` and remove the integration lines
from your Rex configuration, then run `brew uninstall resh`. Personal resh
configuration and history are preserved.

## Maintenance and provenance

`Update resh` runs hourly, or manually from the Actions tab. It accepts immutable
stable releases from [`CruelAddict/resh`](https://github.com/CruelAddict/resh),
downloads the checksum manifest and both macOS archives, and verifies their
GitHub Artifact Attestations before writing `Formula/resh.rb`. Verification pins
the upstream repository, release workflow, tag, source commit and GitHub-hosted
runner. The resulting formula pins each architecture's archive digest.

The workflow only needs its own repository's `GITHUB_TOKEN`; no cross-repository
write token or personal signing key is used. Prereleases and version downgrades
are rejected. Every generated formula update is retained in Git history.

To run the updater locally, install a current GitHub CLI with attestation support
and use Python 3.11+:

```sh
python3 scripts/update-resh.py
```

For direct archive verification and release details, see
[resh's release guide](https://github.com/CruelAddict/resh/blob/main/docs/releases.md).
