## Planet Open STAC Resources

This repo contains the source JSON files for the open [SpatioTemporal Asset Catalog (STAC)](https://stacspec.org) resources deployed to https://www.planet.com/data/stac. This repo is formatted as a 'metadata-only' [self-contained catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-catalogs) with the assets all residing in a Planet Google Cloud Storage bucket. Publishing is done by pushing to an internal Planet git repo, where
the catalog is rewritten to be an 'absolute [published catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#published-catalogs)'. 

The catalog should be considered 'in-progress', as not all items are in their ideal state yet. Contributions as Pull Requests to help improve the STAC metadata are welcome, subject to review by the project maintainers.

### Development

The development environment requires [Docker](https://docs.docker.com/get-docker/) and [Make](https://www.gnu.org/software/make/). The instructions below make use the [`ghcr.io/planetlabs/go-stac` image](https://github.com/planetlabs/go-stac/pkgs/container/go-stac). The CI jobs run the same tasks, so if you cannot run them locally, you can rely on the CI jobs.


After adding new STAC resources to the `stac` directory, add links from the root `stac/catalog.json` (or an existing linked collection or catalog).  Use relative URLs for all link `href` values.

To add or update stats for the `stac/catalog.json`:

    make stats

To format everything in the `stac` directory:

    make format

To validate all of the resources:

    make validate

### Deploying

Deploying changes to https://www.planet.com/data/stac must be done by a Planeteer - if you'd like new changes contributed to be published then just let the maintainers of this repo know.

To update the deployment, set up remotes for the internal and external repositories:

```bash
git remote add origin git@github.com:planetlabs/open-stac.git
git remote add planet ${INTERNAL_REPO_URL}
```

Whenever you want to deploy the latest from the default branch on GitHub:

```bash
git fetch origin
git push planet origin/main:main
```

### License

Planet and any contributors grant you a license to any content (JSON metadata, etc) in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [Apache 2 License](https://opensource.org/license/apache-2-0/), see the [LICENSE-CODE](LICENSE-CODE) file.
